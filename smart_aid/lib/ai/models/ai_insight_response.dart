class AiInsightResponse {
  final String narrative;
  final bool isFallback;

  AiInsightResponse({
    required this.narrative,
    this.isFallback = false,
  });

  factory AiInsightResponse.fallback(String fallbackMessage) {
    return AiInsightResponse(
      narrative: fallbackMessage,
      isFallback: true,
    );
  }
}
