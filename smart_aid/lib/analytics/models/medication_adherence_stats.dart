class MedicationAdherenceStats {
  final int totalExpectedDoses;
  final int totalTakenDoses;
  final double adherencePercentage;
  final List<String> missedMedications;

  MedicationAdherenceStats({
    required this.totalExpectedDoses,
    required this.totalTakenDoses,
    required this.adherencePercentage,
    required this.missedMedications,
  });

  factory MedicationAdherenceStats.empty() => MedicationAdherenceStats(
        totalExpectedDoses: 0,
        totalTakenDoses: 0,
        adherencePercentage: 100.0,
        missedMedications: [],
      );

  bool get isPerfect => adherencePercentage >= 100.0;
}

class AdherenceTimelinePoint {
  final String dateKey; // Format: YYYY-MM-DD
  final int taken;
  final int expected;

  AdherenceTimelinePoint({
    required this.dateKey,
    required this.taken,
    required this.expected,
  });

  double get percentage => expected == 0 ? 100.0 : (taken / expected) * 100.0;
}
