import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import '../models/health_record_model.dart';

class HealthRecordRepository {
  final _db = FirebaseFirestore.instance;

  // ---------------------------------------------------------------------------
  // FIRESTORE METADATA OPERATIONS
  // ---------------------------------------------------------------------------

  Stream<List<HealthRecordModel>> getHealthRecordsStream(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('health_records')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          return HealthRecordModel.fromFirestore(doc);
        } catch (e) {
          // Constraint: Health record streams should skip malformed metadata documents safely.
          // Constraint: Log malformed health record IDs using debugPrint.
          debugPrint('Error parsing HealthRecordModel for doc ${doc.id}: $e');
          return null;
        }
      }).where((model) => model != null).cast<HealthRecordModel>().toList();
    });
  }

  Future<void> saveRecordMetadata({
    required String userId,
    required String fileName,
    required String localPath,
  }) async {
    await _db.collection('users').doc(userId).collection('health_records').add({
      'fileName': fileName,
      'localPath': localPath,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteRecordMetadata({
    required String userId,
    required String recordId,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('health_records')
        .doc(recordId)
        .delete();
  }

  // ---------------------------------------------------------------------------
  // LOCAL FILESYSTEM OPERATIONS
  // ---------------------------------------------------------------------------

  /// Attempts to open a local file.
  /// Returns false if the file is missing or invalid, ensuring the UI can notify the user gracefully.
  Future<bool> openLocalFile(String localPath) async {
    // Constraint: File existence validation must occur before every file open attempt.
    final file = File(localPath);
    if (!await file.exists()) {
      // Constraint: Log invalid file paths using debugPrint.
      debugPrint('Validation failed: File not found at $localPath');
      return false;
    }

    try {
      final result = await OpenFilex.open(localPath);
      if (result.type != ResultType.done) {
        debugPrint('OpenFilex failed: ${result.message}');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('Exception while opening file at $localPath: $e');
      return false;
    }
  }

  /// Attempts to delete a local file.
  /// Does not throw exceptions if the file is missing or locked.
  Future<void> deleteLocalFile(String localPath) async {
    try {
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('Successfully deleted local file: $localPath');
      } else {
        debugPrint('File deletion skipped: File not found at $localPath');
      }
    } catch (e) {
      // Constraint: File deletion failures must fail gracefully without crashing the UI.
      debugPrint('Graceful failure: Could not delete local file at $localPath: $e');
    }
  }
}
