// lib/services/medication_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/medication_model.dart';
import '../models/dose_log_model.dart';
import '../repositories/medication_repository.dart';
import '../services/local_db_service.dart';

class MedicationService {
  final MedicationRepository medicationRepository;

  MedicationService({required this.medicationRepository});

  // ---------------------------------------------------------------------------
  // STREAMS (Typed & Safe)
  // ---------------------------------------------------------------------------

  Stream<List<MedicationModel>> getMedicationsStream(String userId) {
    return medicationRepository.getMedicationsStream(userId);
  }

  Stream<List<DoseLogModel>> getAllDoseLogsStream(String userId) {
    return medicationRepository.getAllDoseLogsStream(userId);
  }

  Stream<DoseLogModel?> getDoseLogStream(String userId, String medicationId, String dateKey) {
    return medicationRepository.getDoseLogStream(userId, medicationId, dateKey);
  }

  // ---------------------------------------------------------------------------
  // OPERATIONS
  // ---------------------------------------------------------------------------

  // Add a new medication schedule — returns the new Firestore document ID.
  Future<String?> addMedication({
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
    return medicationRepository.addMedication(
      userId: userId,
      name: name,
      composition: composition,
      rationale: rationale,
      dailyDoseLimit: dailyDoseLimit,
      scheduledTimes: scheduledTimes,
      startDate: startDate,
      endDate: endDate,
      gapInDays: gapInDays,
    );
  }

  /// Check whether a medication with this name already exists for the user.
  /// Exposed so AddMedicineScreen can show a duplicate-warning dialog.
  Future<bool> medicationExists({required String userId, required String name}) {
    return medicationRepository.medicationExists(userId: userId, name: name);
  }

  // Log an intake and check for over/underdose.
  // Fix 3A: reads from local SQLite FIRST to avoid a live Firestore round-trip
  // when the device is offline or Firestore is momentarily slow.
  Future<DoseCheckResult> logIntake({
    required String userId,
    required String medicationId,
    required String medicationName,
    required int dailyDoseLimit,
  }) async {
    final today = todayKey();
    final logId = '$medicationId-$today';

    // 1. Read local SQLite rows for this med + today (fast, always available offline)
    int currentCount = 0;
    try {
      final localLogs = await LocalDbService().getLogs(userId);
      final todayLocal = localLogs.where(
        (l) => l['medicationId'] == medicationId && l['dateKey'] == today,
      ).toList();
      currentCount = todayLocal.length; // each row = one intake event
    } catch (e) {
      debugPrint('[MedicationService] local read failed: $e');
    }

    // 2. Only hit Firestore if local count is 0 (first intake of the day or fresh install)
    if (currentCount == 0) {
      try {
        final existingLog = await medicationRepository.getDoseLog(userId, logId);
        currentCount = existingLog?.count ?? 0;
      } on FirebaseException catch (e) {
        // Firestore unavailable — proceed with local count; offline write will sync later
        debugPrint('[MedicationService] getDoseLog Firestore error (${e.code}), using local count=$currentCount');
      }
    }

    // 3. Overdose guard
    if (currentCount >= dailyDoseLimit) {
      return DoseCheckResult.overdose(currentCount, dailyDoseLimit);
    }

    final updatedLog = DoseLogModel(
      id: logId,
      medicationId: medicationId,
      medicationName: medicationName,
      count: currentCount + 1,
      date: today,
    );

    await medicationRepository.saveDoseLog(userId, updatedLog);

    return DoseCheckResult.ok(currentCount + 1, dailyDoseLimit);
  }

  String todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}

class DoseCheckResult {
  final bool isOverdose;
  final int taken;
  final int limit;

  DoseCheckResult._({
    required this.isOverdose,
    required this.taken,
    required this.limit,
  });

  factory DoseCheckResult.ok(int taken, int limit) =>
      DoseCheckResult._(isOverdose: false, taken: taken, limit: limit);

  factory DoseCheckResult.overdose(int taken, int limit) =>
      DoseCheckResult._(isOverdose: true, taken: taken, limit: limit);

  bool get isUnderdose => taken < limit;
}
