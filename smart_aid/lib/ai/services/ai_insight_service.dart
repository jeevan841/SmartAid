import 'package:google_generative_ai/google_generative_ai.dart';
import '../../security/services/secure_logger.dart';
import '../models/ai_insight_request.dart';
import '../models/ai_insight_response.dart';
import '../prompts/insight_prompts.dart';
import '../../reports/models/patient_health_report.dart';

class AiInsightService {
  final String apiKey; // In production, this must be securely fetched or proxied through a backend.

  AiInsightService({required this.apiKey});

  /// Consumes a strictly typed PatientHealthReport to generate an observational narrative.
  /// Falls back deterministically if the dataset is sparse or the API fails.
  Future<AiInsightResponse> generateNarrative(PatientHealthReport report) async {
    // Graceful fallback for sparse datasets or missing API key
    if (apiKey.isEmpty || report.activeMedications.isEmpty || report.adherenceProfile.weeklyTimeline.isEmpty) {
      return AiInsightResponse.fallback(report.adherenceProfile.dailyInsight.message);
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(InsightPrompts.systemInstruction),
      );

      final request = AiInsightRequest(report: report);
      
      // Substitute the variable in the prompt explicitly
      String prompt = InsightPrompts.generateAdherencePrompt(request.toPromptContext());
      // In Dart, if we just used the variable in the string interpolation inside the method, it works natively.
      // Since generateAdherencePrompt takes contextData as a parameter, we are safe.

      final content = [Content.text(prompt)];
      final response = await model.generateContent(content);

      final text = response.text?.trim() ?? '';
      
      if (text.isEmpty) {
        return AiInsightResponse.fallback(report.adherenceProfile.dailyInsight.message);
      }

      return AiInsightResponse(narrative: text);
    } catch (e, stack) {
      SecureLogger.logError('AI Generation Failed', e, stackTrace: stack);
      // Deterministic fallback path guaranteed
      return AiInsightResponse.fallback(report.adherenceProfile.dailyInsight.message);
    }
  }
}
