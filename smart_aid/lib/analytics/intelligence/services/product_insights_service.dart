import '../models/product_insight.dart';
import '../../models/doctor_dashboard_stats.dart';
import '../../../repositories/medication_repository.dart';
import '../../utils/timeline_calculator.dart';
import '../../models/medication_adherence_stats.dart';
class ProductInsightsService {
  final MedicationRepository medicationRepository;

  ProductInsightsService({
    required this.medicationRepository,
  });

  /// Generates deterministic, emotionally supportive adherence profile.
  Future<PatientAdherenceProfile> generatePatientProfile(String userId) async {
    final medications = await medicationRepository.getAllMedications(userId);
    if (medications.isEmpty) {
      return PatientAdherenceProfile.empty();
    }

    final logs = await medicationRepository.getAllDoseLogs(userId);
    if (logs.isEmpty) {
      return PatientAdherenceProfile(
        consecutivePerfectDays: 0,
        dailyInsight: ProductInsight(
          title: "Let's Get Started",
          message: "You have medications scheduled. Log your first dose to begin your streak!",
          sentiment: InsightSentiment.neutral,
        ),
        todayStats: TimelineCalculator.calculateDailyAdherence(medications, []),
        weeklyTimeline: [],
      );
    }

    // Calculate streak
    int streak = 0;
    DateTime dateWalker = DateTime.now();
    
    while (true) {
      final dateKey = '${dateWalker.year}-${dateWalker.month.toString().padLeft(2, '0')}-${dateWalker.day.toString().padLeft(2, '0')}';
      
      // Filter logs for this day
      final dayLogs = logs.where((l) => l.date == dateKey).toList();
      
      final stats = TimelineCalculator.calculateDailyAdherence(medications, dayLogs);
      
      final isToday = dateKey == TimelineCalculator.todayKey();
      
      if (stats.isPerfect) {
        streak++;
      } else {
        if (!isToday) {
          break; // Streak broken on a past day
        }
      }
      
      dateWalker = dateWalker.subtract(const Duration(days: 1));
      
      // Prevent infinite loop if they have no older logs
      // Check if there are any logs in the entire dataset that are older than dateWalker
      bool hasOlderLogs = false;
      for (var l in logs) {
        // Simple string comparison works for YYYY-MM-DD
        if (l.date.compareTo(dateKey) < 0) {
          hasOlderLogs = true;
          break;
        }
      }
      if (!hasOlderLogs) break;
    }

    // Generate insight message deterministically
    ProductInsight insight;
    if (streak >= 7) {
      insight = ProductInsight(
        title: "Outstanding Consistency",
        message: "You've maintained a perfect medication streak for a full week. Excellent work!",
        sentiment: InsightSentiment.positive,
      );
    } else if (streak >= 3) {
      insight = ProductInsight(
        title: "Great Momentum",
        message: "You're on a $streak-day streak. Keep up the good habit!",
        sentiment: InsightSentiment.positive,
      );
    } else {
      final todayStats = TimelineCalculator.calculateDailyAdherence(
        medications, 
        logs.where((l) => l.date == TimelineCalculator.todayKey()).toList()
      );
      if (todayStats.isPerfect) {
         insight = ProductInsight(
          title: "Good Start",
          message: "You've taken all your medications today.",
          sentiment: InsightSentiment.positive,
        );
      } else if (todayStats.totalTakenDoses > 0) {
        insight = ProductInsight(
          title: "Making Progress",
          message: "You've started logging today. Keep going to hit your daily goal.",
          sentiment: InsightSentiment.neutral,
        );
      } else {
        insight = ProductInsight(
          title: "Stay on Track",
          message: "Consistency is key to managing your health. Try to hit your goals today.",
          sentiment: InsightSentiment.neutral,
        );
      }
    }

    // Retrieve todayStats again for final output
    final finalTodayStats = TimelineCalculator.calculateDailyAdherence(
      medications, 
      logs.where((l) => l.date == TimelineCalculator.todayKey()).toList()
    );

    // Generate 7-day timeline for visualization
    final List<AdherenceTimelinePoint> weeklyTimeline = [];
    DateTime walkTimeline = DateTime.now().subtract(const Duration(days: 6));
    
    for (int i = 0; i < 7; i++) {
      final key = '${walkTimeline.year}-${walkTimeline.month.toString().padLeft(2, '0')}-${walkTimeline.day.toString().padLeft(2, '0')}';
      final dayLogs = logs.where((l) => l.date == key).toList();
      final stats = TimelineCalculator.calculateDailyAdherence(medications, dayLogs);
      
      weeklyTimeline.add(AdherenceTimelinePoint(
        dateKey: key,
        taken: stats.totalTakenDoses,
        expected: stats.totalExpectedDoses,
      ));
      
      walkTimeline = walkTimeline.add(const Duration(days: 1));
    }

    return PatientAdherenceProfile(
      consecutivePerfectDays: streak,
      dailyInsight: insight,
      todayStats: finalTodayStats,
      weeklyTimeline: weeklyTimeline,
    );
  }

  /// Generates a lightweight, privacy-aware snippet for doctors
  ProductInsight generateCohortInsight(DoctorDashboardStats stats) {
    if (stats.optedInCount == 0) {
      return ProductInsight(
        title: "Pending Consent",
        message: "No patients have opted into research sharing yet.",
        sentiment: InsightSentiment.alert,
      );
    }

    return ProductInsight(
      title: "Stable Cohort",
      message: "Research participation is active. Continue requesting consent from new patients.",
      sentiment: InsightSentiment.positive,
    );
  }
}
