import '../models/appointment_model.dart';
import '../repositories/appointment_repository.dart';

class AppointmentService {
  final AppointmentRepository appointmentRepository;

  AppointmentService({required this.appointmentRepository});

  // ---------------------------------------------------------------------------
  // STREAMS (Typed & Safe)
  // ---------------------------------------------------------------------------

  Stream<List<AppointmentModel>> getAppointmentsStream(String userId) {
    return appointmentRepository.getAppointmentsStream(userId);
  }

  // ---------------------------------------------------------------------------
  // OPERATIONS
  // ---------------------------------------------------------------------------

  Future<void> addAppointment({
    required String userId,
    required AppointmentModel appointment,
  }) async {
    await appointmentRepository.addAppointment(userId: userId, appointment: appointment);
  }

  Future<void> updateAppointment({
    required String userId,
    required AppointmentModel appointment,
  }) async {
    await appointmentRepository.updateAppointment(userId: userId, appointment: appointment);
  }

  Future<void> deleteAppointment({
    required String userId,
    required String appointmentId,
  }) async {
    await appointmentRepository.deleteAppointment(userId: userId, appointmentId: appointmentId);
  }
}
