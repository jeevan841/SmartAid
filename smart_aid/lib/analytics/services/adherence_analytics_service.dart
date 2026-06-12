import '../models/medication_adherence_stats.dart';
import '../utils/timeline_calculator.dart';
import '../../repositories/medication_repository.dart';
import '../../models/dose_log_model.dart';

class AdherenceAnalyticsService {
  final MedicationRepository medicationRepository;

  AdherenceAnalyticsService({required this.medicationRepository});

  /// Calculates today's adherence stats by aggregating medication limits and dose logs.
  Future<MedicationAdherenceStats> getDailyAdherence(String userId) async {
    final medications = await medicationRepository.getAllMedications(userId);
    final today = TimelineCalculator.todayKey();
    
    List<DoseLogModel> todayLogs = [];
    
    for (var med in medications) {
      final logId = '${med.id}-$today';
      final log = await medicationRepository.getDoseLog(userId, logId);
      if (log != null) {
        todayLogs.add(log);
      }
    }

    // Delegate pure mathematical calculation to the utility
    return TimelineCalculator.calculateDailyAdherence(medications, todayLogs);
  }
}
