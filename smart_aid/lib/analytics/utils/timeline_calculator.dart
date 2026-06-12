import '../models/medication_adherence_stats.dart';
import '../../models/medication_model.dart';
import '../../models/dose_log_model.dart';

class TimelineCalculator {
  /// Pure Dart function: calculates adherence stats given a list of medications and today's logs.
  /// Does not touch Firestore or execute any side effects.
  static MedicationAdherenceStats calculateDailyAdherence(
      List<MedicationModel> medications, List<DoseLogModel> todayLogs) {
    int totalExpected = 0;
    int totalTaken = 0;
    List<String> missed = [];

    for (var med in medications) {
      int limit = med.dailyDoseLimit;
      totalExpected += limit;

      // Find if we have logs for this med today
      final logIdSuffix = todayKey(); // Since logId format is medicationId-todayKey
      var log = todayLogs.where((l) => l.medicationId == med.id && l.date == logIdSuffix).firstOrNull;
      
      int taken = log?.count ?? 0;
      
      // Cap the taken at expected so over-taking doesn't artificially inflate adherence percentage
      totalTaken += (taken > limit ? limit : taken);

      if (taken < limit) {
        missed.add('${med.name} (took $taken of $limit doses)');
      }
    }

    double percentage = totalExpected == 0 ? 100.0 : (totalTaken / totalExpected) * 100.0;

    return MedicationAdherenceStats(
      totalExpectedDoses: totalExpected,
      totalTakenDoses: totalTaken,
      adherencePercentage: percentage,
      missedMedications: missed,
    );
  }

  static String todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
