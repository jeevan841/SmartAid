import 'package:flutter/material.dart';
import '../../analytics/models/doctor_dashboard_stats.dart';
import '../../analytics/intelligence/models/product_insight.dart';

class CohortSummaryWidget extends StatelessWidget {
  final DoctorDashboardStats stats;
  final ProductInsight insight;

  const CohortSummaryWidget({
    super.key,
    required this.stats,
    required this.insight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Column(
              children: [
                Icon(
                  Icons.verified_user, 
                  color: insight.sentiment == InsightSentiment.positive ? Colors.green : Colors.blue, 
                  size: 28
                ),
                const SizedBox(height: 4),
                Text(
                  stats.optedInCount.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 6),
                Text(
                  insight.message,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
