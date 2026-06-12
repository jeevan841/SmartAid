
import '../../services/medication_service.dart';
import '../../services/appointment_service.dart';
import '../../analytics/intelligence/services/product_insights_service.dart';
import '../models/patient_health_report.dart';

class ReportGenerationService {
  final MedicationService medicationService;
  final AppointmentService appointmentService;
  final ProductInsightsService insightsService;

  ReportGenerationService({
    required this.medicationService,
    required this.appointmentService,
    required this.insightsService,
  });

  /// Orchestrates fetching all data to build a comprehensive, typed Patient Health Report.
  /// Designed to be completely presentation-agnostic and export-ready.
  Future<PatientHealthReport> generatePatientReport(String userId) async {
    // 1. Fetch Adherence Intelligence Profile (which handles streaks & calculations)
    final profile = await insightsService.generatePatientProfile(userId);

    // 2. Fetch Active Medications (could potentially differ from raw logs)
    final medicationsStream = medicationService.getMedicationsStream(userId);
    final medications = await medicationsStream.first;

    // 3. Fetch Upcoming Appointments
    final appointmentsStream = appointmentService.getAppointmentsStream(userId);
    final allAppointments = await appointmentsStream.first;
    
    // Filter to upcoming only
    final now = DateTime.now();
    final upcomingAppointments = allAppointments.where((a) {
      if (a.dateTime == null) return false;
      return a.dateTime!.isAfter(now);
    }).toList();

    return PatientHealthReport(
      adherenceProfile: profile,
      activeMedications: medications,
      upcomingAppointments: upcomingAppointments,
      generatedAt: DateTime.now(),
    );
  }
}
