import '../../models/medication_adherence_stats.dart';

enum InsightSentiment { positive, neutral, alert }

class ProductInsight {
  final String title;
  final String message;
  final InsightSentiment sentiment;

  ProductInsight({
    required this.title,
    required this.message,
    required this.sentiment,
  });

  factory ProductInsight.empty() => ProductInsight(
        title: "Waiting for Data",
        message: "Start logging your medications to see personalized insights.",
        sentiment: InsightSentiment.neutral,
      );
}

class PatientAdherenceProfile {
  final int consecutivePerfectDays;
  final ProductInsight dailyInsight;
  final MedicationAdherenceStats todayStats;
  final List<AdherenceTimelinePoint> weeklyTimeline;

  PatientAdherenceProfile({
    required this.consecutivePerfectDays,
    required this.dailyInsight,
    required this.todayStats,
    required this.weeklyTimeline,
  });

  factory PatientAdherenceProfile.empty() => PatientAdherenceProfile(
        consecutivePerfectDays: 0,
        dailyInsight: ProductInsight.empty(),
        todayStats: MedicationAdherenceStats.empty(),
        weeklyTimeline: [],
      );
}
