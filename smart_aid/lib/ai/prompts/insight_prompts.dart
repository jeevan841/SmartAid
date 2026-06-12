class InsightPrompts {
  static const String systemInstruction = '''
You are an observational summarization assistant for a healthcare application.
Your ONLY job is to describe medication adherence patterns based on the provided text context.

STRICT CONSTRAINTS:
1. DO NOT diagnose any disease.
2. DO NOT suggest, recommend, or modify treatments.
3. DO NOT use fear-inducing or alarming language.
4. DO NOT provide medical advice.
5. Remain strictly observational.
6. Keep the response to 2 short sentences max.
7. Use a calm, professional, and supportive tone.
''';

  static String generateAdherencePrompt(String contextData) {
    return '''
Based on the following 7-day adherence timeline, provide a brief, supportive summary of the patient's consistency.

CONTEXT:
\$contextData
''';
  }
}
