import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/ai_insight_service.dart';
import '../models/ai_insight_response.dart';
import '../../reports/services/report_generation_service.dart';
import '../../ui/loading/shimmer_loading.dart';

class AiNarrativeWidget extends StatefulWidget {
  final String userId;
  const AiNarrativeWidget({super.key, required this.userId});

  @override
  State<AiNarrativeWidget> createState() => _AiNarrativeWidgetState();
}

class _AiNarrativeWidgetState extends State<AiNarrativeWidget> {
  late Future<AiInsightResponse> _narrativeFuture;

  @override
  void initState() {
    super.initState();
    _loadNarrative();
  }

  void _loadNarrative() {
    final reportService = context.read<ReportGenerationService>();
    final aiService = context.read<AiInsightService>();
    _narrativeFuture = reportService.generatePatientReport(widget.userId)
        .then((report) => aiService.generateNarrative(report));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AiInsightResponse>(
      future: _narrativeFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Subtle shimmer that reserves layout space
          return _buildContainer(
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                 SkeletonCard(height: 20, width: 150, margin: EdgeInsets.only(bottom: 8)),
                 SkeletonCard(height: 14, width: double.infinity, margin: EdgeInsets.only(bottom: 4)),
                 SkeletonCard(height: 14, width: 200, margin: EdgeInsets.zero),
              ],
            )
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          // Silent fallback on complete failure
          return const SizedBox.shrink();
        }

        final response = snapshot.data!;
        
        return _buildContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    response.isFallback ? Icons.insights : Icons.auto_awesome, 
                    color: Colors.blue.shade800, 
                    size: 18
                  ),
                  const SizedBox(width: 8),
                  Text(
                    response.isFallback ? 'Adherence Insight' : 'AI Adherence Summary',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                response.narrative,
                style: const TextStyle(fontSize: 14, color: Colors.black87),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        child: child,
      ),
    );
  }
}
