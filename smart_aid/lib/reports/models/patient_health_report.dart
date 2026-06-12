import '../../models/medication_model.dart';
import '../../models/appointment_model.dart';
import '../../analytics/intelligence/models/product_insight.dart';

class PatientHealthReport {
  final PatientAdherenceProfile adherenceProfile;
  final List<MedicationModel> activeMedications;
  final List<AppointmentModel> upcomingAppointments;
  final DateTime generatedAt;

  PatientHealthReport({
    required this.adherenceProfile,
    required this.activeMedications,
    required this.upcomingAppointments,
    required this.generatedAt,
  });
}
