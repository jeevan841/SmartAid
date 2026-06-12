import '../../reports/models/patient_health_report.dart';

class AiInsightRequest {
  final PatientHealthReport report;

  AiInsightRequest({required this.report});

  /// Serializes the typed DTO into a strict text format for the LLM.
  String toPromptContext() {
    final profile = report.adherenceProfile;
    final meds = report.activeMedications;
    
    final buffer = StringBuffer();
    buffer.writeln('Active Medications: ${meds.length}');
    buffer.writeln('Current Streak: ${profile.consecutivePerfectDays} days');
    
    buffer.writeln('7-Day Timeline:');
    for (var point in profile.weeklyTimeline) {
      buffer.writeln('- ${point.dateKey}: Taken ${point.taken}/${point.expected}');
    }
    return buffer.toString();
  }
}
