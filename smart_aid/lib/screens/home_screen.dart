import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_aid/screens/add_medicine_screen.dart';
import 'package:smart_aid/screens/add_appointment_screen.dart';
import 'package:smart_aid/screens/emergency_screen.dart';
import 'package:smart_aid/services/medication_service.dart';
import 'package:smart_aid/services/appointment_service.dart';
import '../models/medication_model.dart';
import '../models/dose_log_model.dart';
import '../models/appointment_model.dart';
import '../analytics/intelligence/services/product_insights_service.dart';
import '../analytics/intelligence/models/product_insight.dart';
import '../visualization/widgets/adherence_progress_ring.dart';
import '../visualization/widgets/weekly_trend_chart.dart';
import '../visualization/utils/chart_data_mapper.dart';
import '../reports/services/report_generation_service.dart';
import '../services/pdf_export_service.dart';
import '../ai/widgets/ai_narrative_widget.dart';
import '../offline/services/offline_sync_service.dart';
import '../ui/loading/shimmer_loading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _userId;
  Stream<List<MedicationModel>>? _medicationsStream;
  Stream<List<AppointmentModel>>? _appointmentsStream;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser?.uid;
    if (_userId != null) {
      _medicationsStream = context.read<MedicationService>().getMedicationsStream(_userId!);
      _appointmentsStream = context.read<AppointmentService>().getAppointmentsStream(_userId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(body: Center(child: Text("Not logged in.")));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Daily Medications'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Builder(
            builder: (context) {
              final offlineSyncService = context.watch<OfflineSyncService>();
              final pendingCount = offlineSyncService.pendingCount;
              final isSyncing = offlineSyncService.isSyncing;
              
              if (pendingCount > 0 || isSyncing) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(
                      children: [
                        if (isSyncing)
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        else
                          const Icon(Icons.cloud_off, size: 20, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          isSyncing ? 'Syncing...' : 'Pending ($pendingCount)',
                          style: TextStyle(color: isSyncing ? Colors.blue : Colors.orange, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            }
          ),
          IconButton(
            icon: const Icon(Icons.download, color: Colors.blue, size: 28),
            tooltip: 'Export Weekly Report',
            onPressed: () async {
              if (_userId == null) return;
              try {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating report...')));
                final report = await context.read<ReportGenerationService>().generatePatientReport(_userId!);
                await PdfExportService().generateAndSharePdf(report);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to export: $e')));
                }
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.emergency, color: Colors.red, size: 32),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const EmergencyScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(context, "Upcoming Appointments"),
            SizedBox(
              height: 140,
              child: StreamBuilder<List<AppointmentModel>>(
                stream: _appointmentsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: 2,
                      itemBuilder: (context, index) => Container(
                        margin: EdgeInsets.only(left: index == 0 ? 20 : 10, right: 10),
                        child: const SkeletonCard(height: 140, width: 250, margin: EdgeInsets.zero),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32.0),
                        child: Text(
                          'Your schedule is clear. Tap + to add an appointment when needed.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey, fontSize: 14),
                        ),
                      ),
                    );
                  }

                  final appointments = snapshot.data!;

                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: appointments.length,
                    itemBuilder: (context, index) {
                      final appt = appointments[index];
                      final dateTime = appt.dateTime;
                      
                      String timeStr = dateTime != null 
                          ? '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}'
                          : 'No Time';
                      String dateStr = dateTime != null
                          ? '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}'
                          : 'No Date';

                      final isDark = Theme.of(context).brightness == Brightness.dark;
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddAppointmentScreen(
                                appointment: appt,
                              ),
                              fullscreenDialog: true,
                            ),
                          );
                        },
                        child: Container(
                          width: 250,
                          margin: EdgeInsets.only(
                            left: index == 0 ? 20 : 10,
                            right: index == appointments.length - 1 ? 20 : 0,
                            bottom: 10,
                          ),
                          padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isDark ? null : [
                            BoxShadow(
                              color: Colors.grey.withValues(alpha: 0.2),
                              spreadRadius: 1,
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    appt.doctorName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(appt.reason, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.black87)),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(dateStr, style: const TextStyle(fontWeight: FontWeight.w600)),
                                Text(timeStr, style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ));
                    },
                  );
                },
              ),
            ),

            _buildSectionHeader(context, "Today's Insights"),
            FutureBuilder<PatientAdherenceProfile>(
              future: _userId != null 
                  ? context.read<ProductInsightsService>().generatePatientProfile(_userId!) 
                  : Future.value(PatientAdherenceProfile.empty()),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final profile = snapshot.data!;
                  final stats = profile.todayStats;
                  final insight = profile.dailyInsight;
                  
                  // Hide entirely if no medications expected and no generic message
                  if (stats.totalExpectedDoses == 0 && insight.sentiment == InsightSentiment.neutral) {
                     return const SizedBox.shrink();
                  }

                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: insight.sentiment == InsightSentiment.positive 
                          ? (isDark ? Colors.green.withValues(alpha: 0.1) : Colors.green.shade50) 
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: insight.sentiment == InsightSentiment.positive 
                            ? (isDark ? Colors.green.withValues(alpha: 0.3) : Colors.green.shade200) 
                            : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                profile.consecutivePerfectDays > 0 ? Icons.local_fire_department : Icons.insights, 
                                color: profile.consecutivePerfectDays > 0 ? (isDark ? Colors.orangeAccent : Colors.orange) : Theme.of(context).colorScheme.primary, 
                                size: 28
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(insight.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                              if (profile.consecutivePerfectDays > 0)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.orange.withValues(alpha: 0.2) : Colors.orange.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text('${profile.consecutivePerfectDays} Day Streak!', style: TextStyle(color: isDark ? Colors.orange.shade200 : Colors.orange.shade900, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(insight.message, style: TextStyle(color: isDark ? Colors.grey.shade300 : Colors.grey.shade800)),

                          if (stats.totalExpectedDoses > 0) ...[
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                AdherenceProgressRing(stats: stats, size: 70),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: WeeklyTrendChart(
                                    points: ChartDataMapper.mapTimelineToWeeklyTrend(profile.weeklyTimeline),
                                  ),
                                ),
                              ],
                            ),
                            AiNarrativeWidget(userId: _userId!),
                          ]
                        ],
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            _buildSectionHeader(context, "Medications"),
            StreamBuilder<List<MedicationModel>>(
              stream: _medicationsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        SkeletonCard(height: 100),
                        SkeletonCard(height: 100),
                      ],
                    ),
                  );
                }

                if (snapshot.hasError) {
                  if (snapshot.error is FirebaseException && (snapshot.error as FirebaseException).code == 'permission-denied') {
                    return const Center(child: Text('Data temporarily unavailable.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)));
                  }
                  return const Center(child: Text('Unable to load at this time.', style: TextStyle(color: Colors.grey)));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.spa, size: 60, color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade100),
                          const SizedBox(height: 16),
                          Text(
                            'Your routine is clear.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'When you\'re ready, tap the + button below to set up your daily schedule.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 15, color: isDark ? Colors.grey.shade400 : Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final medications = snapshot.data!;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: medications.length,
                  itemBuilder: (context, index) {
                    final med = medications[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MedicineCardWidget(
                        userId: _userId!,
                        medication: med,
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 60), // padding for the FAB
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Options'),
        onPressed: () {
          showModalBottomSheet(
            context: context,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) {
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.medication, size: 30, color: Colors.blue),
                        title: const Text('Add New Medicine', style: TextStyle(fontSize: 18)),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AddMedicineScreen(),
                              fullscreenDialog: true,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      ListTile(
                        leading: const Icon(Icons.calendar_today, size: 30, color: Colors.green),
                        title: const Text('Book Appointment', style: TextStyle(fontSize: 18)),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const AddAppointmentScreen(),
                              fullscreenDialog: true,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _MedicineCardWidget extends StatefulWidget {
  final String userId;
  final MedicationModel medication;

  const _MedicineCardWidget({
    required this.userId,
    required this.medication,
  });

  @override
  State<_MedicineCardWidget> createState() => _MedicineCardWidgetState();
}

class _MedicineCardWidgetState extends State<_MedicineCardWidget> {
  Stream<DoseLogModel?>? _doseLogStream;

  bool _isDisappearing = false;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    final medService = context.read<MedicationService>();
    _doseLogStream = medService.getDoseLogStream(
      widget.userId,
      widget.medication.id,
      medService.todayKey(),
    );
  }

  Future<void> _handleTap(bool isTaken) async {
    if (isTaken) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Already logged today')),
        );
      }
      return;
    }
    try {
      await context.read<MedicationService>().logIntake(
        userId: widget.userId,
        medicationId: widget.medication.id,
        medicationName: widget.medication.name,
        dailyDoseLimit: widget.medication.dailyDoseLimit,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              Text('${widget.medication.name} logged!'),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      // Hold the strikethrough visible, then collapse
      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      setState(() => _isDisappearing = true);
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) setState(() => _isVisible = false);
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.code == 'permission-denied'
                ? 'Permission denied to log dose.'
                : 'Error: ${e.message ?? ''}'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final String time = widget.medication.scheduledTimes.isNotEmpty
        ? widget.medication.scheduledTimes.first
        : '00:00';

    return StreamBuilder<DoseLogModel?>(
      stream: _doseLogStream,
      builder: (context, logSnapshot) {
        if (logSnapshot.hasError) {
          return const Center(child: Text('Permission error', style: TextStyle(color: Colors.red, fontSize: 12)));
        }

        int taken = 0;
        if (logSnapshot.hasData && logSnapshot.data != null) {
          taken = logSnapshot.data!.count;
        }

        final bool isTaken =
            taken >= widget.medication.dailyDoseLimit || _isDisappearing;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AnimatedOpacity(
          opacity: _isDisappearing ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 350),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOut,
            height: _isDisappearing ? 0.0 : null,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(),
            child: GestureDetector(
              onTap: () => _handleTap(isTaken),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isTaken
                      ? (isDark
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.green.shade50)
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isDark
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.grey.withValues(alpha: 0.2),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                  border: Border.all(
                    color: isTaken
                        ? (isDark
                            ? Colors.green.withValues(alpha: 0.3)
                            : Colors.green.shade200)
                        : (isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.medication,
                      color: isTaken
                          ? Colors.green
                          : Theme.of(context).colorScheme.primary,
                      size: 40,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.medication.name,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              decoration: isTaken
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationThickness: 2.5,
                              color: isTaken
                                  ? (isDark
                                      ? Colors.grey.shade600
                                      : Colors.grey)
                                  : (isDark ? Colors.white : Colors.black87),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.medication.dailyDoseLimit} Pill(s) Daily — Taken $taken',
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                              decoration: isTaken
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isTaken
                                ? Colors.grey
                                : Theme.of(context).colorScheme.primary,
                            decoration:
                                isTaken ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            isTaken
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            key: ValueKey(isTaken),
                            color: isTaken
                                ? (isDark ? Colors.greenAccent : Colors.green)
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
