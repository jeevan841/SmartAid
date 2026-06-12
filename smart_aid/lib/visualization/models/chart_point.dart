class ChartPoint {
  final String label;
  final double normalizedValue; // Must be between 0.0 and 1.0
  final bool isHighlight;

  ChartPoint({
    required this.label,
    required this.normalizedValue,
    this.isHighlight = false,
  });
}
