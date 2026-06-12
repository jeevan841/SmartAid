// lib/services/medication_service.dart

import '../models/medication_model.dart';
import '../models/dose_log_model.dart';
import '../repositories/medication_repository.dart';

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

  // Add a new medication schedule
  Future<void> addMedication({
    required String userId,
    required String name,
    required String composition,
    required String rationale, // "Prescribed to control blood pressure"
    required int dailyDoseLimit,
    required List<String> scheduledTimes, // ["08:00", "20:00"]
    DateTime? startDate,
    DateTime? endDate,
    int? gapInDays,
  }) async {
    await medicationRepository.addMedication(
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

  // Log an intake and check for over/underdose
  Future<DoseCheckResult> logIntake({
    required String userId,
    required String medicationId,
    required String medicationName,
    required int dailyDoseLimit,
  }) async {
    final today = todayKey();
    final logId = '$medicationId-$today';

    final existingLog = await medicationRepository.getDoseLog(userId, logId);
    int currentCount = existingLog?.count ?? 0;

    // Check overdose rule
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
