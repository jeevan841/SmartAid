import 'package:flutter/material.dart';
import '../models/chart_point.dart';

class WeeklyTrendChart extends StatelessWidget {
  final List<ChartPoint> points;

  const WeeklyTrendChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: points.map((point) {
        return _buildBar(context, point);
      }).toList(),
    );
  }

  Widget _buildBar(BuildContext context, ChartPoint point) {
    const double maxBarHeight = 40.0;
    final double barHeight = point.normalizedValue * maxBarHeight;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 12,
          height: barHeight == 0 ? 4 : barHeight, // Ensure at least a small bump is visible even if 0
          decoration: BoxDecoration(
            color: point.normalizedValue == 1.0 
                ? Colors.green 
                : (point.isHighlight ? Theme.of(context).primaryColor : Colors.grey.shade400),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          point.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: point.isHighlight ? FontWeight.bold : FontWeight.normal,
            color: point.isHighlight ? Colors.black : Colors.grey,
          ),
        ),
      ],
    );
  }
}
