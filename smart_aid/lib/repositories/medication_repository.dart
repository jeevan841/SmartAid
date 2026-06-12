// ignore_for_file: use_null_aware_elements
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_aid/services/local_db_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../offline/models/sync_queue_item.dart';
import '../security/validators/input_validators.dart';
import '../models/medication_model.dart';
import '../models/dose_log_model.dart';

class MedicationRepository {
  final _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // STREAMS (Typed & Safe)
  // ---------------------------------------------------------------------------

  Stream<List<MedicationModel>> getMedicationsStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('medications')
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return MedicationModel.fromFirestore(doc);
        } catch (e) {
          debugPrint('Error parsing MedicationModel for doc ${doc.id}: $e');
          return null;
        }
      }).where((model) => model != null).cast<MedicationModel>().toList();
    });
  }

  Stream<List<DoseLogModel>> getAllDoseLogsStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('dose_logs')
        .orderBy('lastTaken', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return DoseLogModel.fromFirestore(doc);
        } catch (e) {
          debugPrint('Error parsing DoseLogModel for doc ${doc.id}: $e');
          return null;
        }
      }).where((model) => model != null).cast<DoseLogModel>().toList();
    });
  }

  Stream<DoseLogModel?> getDoseLogStream(String userId, String medicationId, String dateKey) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('dose_logs')
        .doc('$medicationId-$dateKey')
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      try {
        return DoseLogModel.fromFirestore(doc);
      } catch (e) {
        debugPrint('Error parsing DoseLogModel for doc ${doc.id}: $e');
        return null;
      }
    });
  }

  // ---------------------------------------------------------------------------
  // OPERATIONS
  // ---------------------------------------------------------------------------

  Future<String> addMedication({
    required String userId,
    required String name,
    required String composition,
    required String rationale,
    required int dailyDoseLimit,
    required List<String> scheduledTimes,
    DateTime? startDate,
    DateTime? endDate,
    int? gapInDays,
  }) async {
    final sanitizedName = InputValidators.sanitizeText(name, maxLength: 50);
    final sanitizedComp = InputValidators.sanitizeText(composition, maxLength: 100);
    final sanitizedRationale = InputValidators.sanitizeText(rationale, maxLength: 150);

    final docRef = await _db.collection('users').doc(userId).collection('medications').add({
      'name': sanitizedName,
      'composition': sanitizedComp,
      'rationale': sanitizedRationale,
      'dailyDoseLimit': dailyDoseLimit,
      'scheduledTimes': scheduledTimes,
      if (startDate != null) 'startDate': Timestamp.fromDate(startDate),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate),
      if (gapInDays != null) 'gapInDays': gapInDays,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  Future<DoseLogModel?> getDoseLog(String userId, String logId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('dose_logs')
        .doc(logId)
        .get();

    if (snapshot.exists) {
      try {
        return DoseLogModel.fromFirestore(snapshot);
      } catch (e) {
        debugPrint('Error parsing DoseLogModel during getDoseLog for doc ${snapshot.id}: $e');
        // Fallback gracefully
        return DoseLogModel(
          id: snapshot.id,
          medicationId: snapshot.data()?['medicationId'] as String? ?? '',
          medicationName: snapshot.data()?['medicationName'] as String? ?? '',
          count: (snapshot.data()?['count'] ?? 0) as int,
          date: snapshot.data()?['date'] as String? ?? '',
        );
      }
    }
    return null;
  }

  Future<void> saveDoseLog(String userId, DoseLogModel log) async {
    // 1. Save to internal database (sqflite) first (always, for fast local reads and resilience)
    await LocalDbService().insertLog(userId: userId, log: log);

    // 2. Save to Firestore (Check connectivity)
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
       final item = SyncQueueItem(
         id: 'dose_${DateTime.now().millisecondsSinceEpoch}',
         operationType: SyncOperationType.saveDoseLog,
         userId: userId,
         payload: {
           'id': log.id,
           'medicationId': log.medicationId,
           'medicationName': log.medicationName,
           'count': log.count,
           'date': log.date,
         },
         timestamp: DateTime.now().millisecondsSinceEpoch,
       );
       await LocalDbService().enqueueSyncItem(item);
       return;
    }

    await _withFirestoreRetry(() => _db
        .collection('users')
        .doc(userId)
        .collection('dose_logs')
        .doc(log.id)
        .set({
      'medicationId': log.medicationId,
      'medicationName': log.medicationName,
      'count': log.count,
      'date': log.date,
      'lastTaken': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true)));
  }

  /// Wraps a Firestore call with exponential back-off retry for transient
  /// gRPC errors ('unavailable', 'deadline-exceeded').
  /// Retries up to 3 times with delays of 1 s, 2 s, 4 s.
  Future<T> _withFirestoreRetry<T>(Future<T> Function() fn) async {
    const transientCodes = {'unavailable', 'deadline-exceeded'};
    int attempt = 0;
    while (true) {
      try {
        return await fn();
      } on FirebaseException catch (e) {
        attempt++;
        if (!transientCodes.contains(e.code) || attempt >= 3) rethrow;
        final delay = Duration(seconds: 1 << (attempt - 1)); // 1s, 2s, 4s
        debugPrint('[Firestore] transient error "${e.code}", retrying in ${delay.inSeconds}s (attempt $attempt/3)');
        await Future.delayed(delay);
      }
    }
  }

  Future<void> syncDoseLog(String userId, Map<String, dynamic> payload) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('dose_logs')
        .doc(payload['id'])
        .set({
      'medicationId': payload['medicationId'],
      'medicationName': payload['medicationName'],
      'count': payload['count'],
      'date': payload['date'],
      'lastTaken': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<List<MedicationModel>> getAllMedications(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('medications')
        .get();

    final List<MedicationModel> list = [];
    for (final doc in snapshot.docs) {
      try {
        list.add(MedicationModel.fromFirestore(doc));
      } catch (e) {
        debugPrint('Error parsing MedicationModel in getAllMedications: $e');
      }
    }
    return list;
  }

  Future<List<DoseLogModel>> getAllDoseLogs(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('dose_logs')
        .orderBy('lastTaken', descending: true)
        .get();

    final List<DoseLogModel> list = [];
    for (final doc in snapshot.docs) {
      try {
        list.add(DoseLogModel.fromFirestore(doc));
      } catch (e) {
        debugPrint('Error parsing DoseLogModel in getAllDoseLogs: $e');
      }
    }
    return list;
  }
}
