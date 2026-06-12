import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../analytics/models/doctor_dashboard_stats.dart';
import '../analytics/services/research_analytics_service.dart';
import '../analytics/intelligence/services/product_insights_service.dart';
import '../visualization/widgets/cohort_summary_widget.dart';
import '../../ui/loading/shimmer_loading.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  Stream<DoctorDashboardStats>? _statsStream;
  Stream<List<dynamic>>? _patientsStream; // simplified for compiling

  @override
  void initState() {
    super.initState();
    _statsStream = context.read<ResearchAnalyticsService>().getCumulativeStatsStream();
    _patientsStream = context.read<ResearchAnalyticsService>().getConsentingPatientsStream();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Research Overview',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildGroupMetrics(),
            const SizedBox(height: 24),
            const Text(
              'Consenting Patients',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildPatientList(),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupMetrics() {
    if (_statsStream == null) return const SizedBox.shrink();

    return StreamBuilder<DoctorDashboardStats>(
      stream: _statsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SkeletonCard(height: 150);
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: Text('Data temporarily unavailable.', style: TextStyle(color: Colors.grey))),
            ),
          );
        }

        return _buildSummaryCard(snapshot.data!);
      },
    );
  }

  Widget _buildSummaryCard(DoctorDashboardStats stats) {
    final insight = context.read<ProductInsightsService>().generateCohortInsight(stats);

    return CohortSummaryWidget(
      stats: stats,
      insight: insight,
    );
  }

  Widget _buildPatientList() {
    if (_patientsStream == null) return const SizedBox.shrink();

    return StreamBuilder<List<dynamic>>(
      stream: _patientsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 3,
            itemBuilder: (context, index) => const SkeletonCard(height: 70),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: Text('Awaiting patient opt-ins for research data.', style: TextStyle(color: Colors.grey)),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final patient = snapshot.data![index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.person, color: Colors.blue),
                ),
                title: Text(patient.name),
                subtitle: Text(patient.email),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Future: Navigate to patient details
                },
              ),
            );
          },
        );
      },
    );
  }
}
