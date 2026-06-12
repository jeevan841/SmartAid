import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/appointment_model.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../offline/models/sync_queue_item.dart';
import '../services/local_db_service.dart';
import '../security/validators/input_validators.dart';

class AppointmentRepository {
  final _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // STREAMS (Typed & Safe)
  // ---------------------------------------------------------------------------

  Stream<List<AppointmentModel>> getAppointmentsStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('appointments')
        .orderBy('dateTime') // Constraint: sorted chronologically
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return AppointmentModel.fromFirestore(doc);
        } catch (e) {
          // Constraint: Invalid or missing appointment dates cause skipping
          // Constraint: Log malformed documents and parsing reasons
          debugPrint('Error parsing AppointmentModel for doc ${doc.id}: $e');
          return null;
        }
      }).where((model) => model != null).cast<AppointmentModel>().toList();
    });
  }

  // ---------------------------------------------------------------------------
  // OPERATIONS
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _safePayload(AppointmentModel appointment) {
    return {
      'id': appointment.id,
      'doctorName': appointment.doctorName,
      'reason': appointment.reason,
      if (appointment.dateTime != null) 'dateTime': appointment.dateTime!.toIso8601String(),
    };
  }

  Future<void> addAppointment({
    required String userId,
    required AppointmentModel appointment,
  }) async {
    final sanitizedAppointment = appointment.copyWith(
      doctorName: InputValidators.sanitizeText(appointment.doctorName, maxLength: 50),
      reason: InputValidators.sanitizeText(appointment.reason, maxLength: 150),
    );

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
       final item = SyncQueueItem(
         id: 'appt_${DateTime.now().millisecondsSinceEpoch}',
         operationType: SyncOperationType.addAppointment,
         userId: userId,
         payload: _safePayload(sanitizedAppointment),
         timestamp: DateTime.now().millisecondsSinceEpoch,
       );
       await LocalDbService().enqueueSyncItem(item);
       return;
    }

    final data = sanitizedAppointment.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _db.collection('users').doc(userId).collection('appointments').add(data);
  }

  Future<void> syncAddAppointment(String userId, Map<String, dynamic> payload) async {
    final data = <String, dynamic>{
       'doctorName': payload['doctorName'],
       'reason': payload['reason'],
       'createdAt': FieldValue.serverTimestamp(),
    };
    if (payload['dateTime'] != null) {
       data['dateTime'] = Timestamp.fromDate(DateTime.parse(payload['dateTime']));
    }
    await _db.collection('users').doc(userId).collection('appointments').add(data);
  }

  Future<void> updateAppointment({
    required String userId,
    required AppointmentModel appointment,
  }) async {
    final sanitizedAppointment = appointment.copyWith(
      doctorName: InputValidators.sanitizeText(appointment.doctorName, maxLength: 50),
      reason: InputValidators.sanitizeText(appointment.reason, maxLength: 150),
    );

    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
       final item = SyncQueueItem(
         id: 'appt_upd_${DateTime.now().millisecondsSinceEpoch}',
         operationType: SyncOperationType.updateAppointment,
         userId: userId,
         payload: _safePayload(sanitizedAppointment),
         timestamp: DateTime.now().millisecondsSinceEpoch,
       );
       await LocalDbService().enqueueSyncItem(item);
       return;
    }

    final data = sanitizedAppointment.toMap();
    data.remove('createdAt'); 
    await _db
        .collection('users')
        .doc(userId)
        .collection('appointments')
        .doc(appointment.id)
        .update(data);
  }

  Future<void> syncUpdateAppointment(String userId, Map<String, dynamic> payload) async {
    final data = <String, dynamic>{
       'doctorName': payload['doctorName'],
       'reason': payload['reason'],
    };
    if (payload['dateTime'] != null) {
       data['dateTime'] = Timestamp.fromDate(DateTime.parse(payload['dateTime']));
    }
    await _db.collection('users').doc(userId).collection('appointments').doc(payload['id']).update(data);
  }

  Future<void> deleteAppointment({
    required String userId,
    required String appointmentId,
  }) async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
       final item = SyncQueueItem(
         id: 'appt_del_${DateTime.now().millisecondsSinceEpoch}',
         operationType: SyncOperationType.deleteAppointment,
         userId: userId,
         payload: {'appointmentId': appointmentId},
         timestamp: DateTime.now().millisecondsSinceEpoch,
       );
       await LocalDbService().enqueueSyncItem(item);
       return;
    }

    await _db
        .collection('users')
        .doc(userId)
        .collection('appointments')
        .doc(appointmentId)
        .delete();
  }

  Future<void> syncDeleteAppointment(String userId, String appointmentId) async {
    await _db.collection('users').doc(userId).collection('appointments').doc(appointmentId).delete();
  }
}
