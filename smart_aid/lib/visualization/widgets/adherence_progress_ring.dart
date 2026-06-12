import 'package:flutter/material.dart';
import '../../analytics/models/medication_adherence_stats.dart';

class AdherenceProgressRing extends StatelessWidget {
  final MedicationAdherenceStats stats;
  final double size;

  const AdherenceProgressRing({
    super.key,
    required this.stats,
    this.size = 60.0,
  });

  @override
  Widget build(BuildContext context) {
    if (stats.totalExpectedDoses == 0) {
      return SizedBox(
        width: size,
        height: size,
        child: const Icon(Icons.analytics_outlined, color: Colors.grey, size: 30),
      );
    }

    final double progress = stats.totalTakenDoses / stats.totalExpectedDoses;
    final bool isComplete = stats.isPerfect;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              isComplete ? Colors.green : Theme.of(context).primaryColor,
            ),
          ),
          Center(
            child: Text(
              '${(progress * 100).toInt()}%',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: size * 0.25,
                color: isComplete ? Colors.green : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
