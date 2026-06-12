import '../models/doctor_dashboard_stats.dart';
import '../../repositories/doctor_dashboard_repository.dart';
import '../../models/user_model.dart';

class ResearchAnalyticsService {
  final DoctorDashboardRepository doctorDashboardRepository;

  ResearchAnalyticsService({required this.doctorDashboardRepository});

  /// Returns a safe, privacy-scrubbed stream of cumulative analytics.
  /// Enforces that non-consenting users and other doctors are excluded.
  Stream<DoctorDashboardStats> getCumulativeStatsStream() {
    return doctorDashboardRepository.getConsentingUsersStream().map((users) {
      int optedInCount = 0;

      for (var user in users) {
        // Strict secondary role validation: Only count genuine patients
        if (!user.isDoctor) {
          optedInCount++;
        }
      }

      return DoctorDashboardStats(optedInCount: optedInCount);
    });
  }

  /// Returns a safe, privacy-scrubbed list of consenting patients.
  /// Enforces that non-consenting users and other doctors are excluded.
  Stream<List<UserModel>> getConsentingPatientsStream() {
    return doctorDashboardRepository.getConsentingUsersStream().map((users) {
      final List<UserModel> patients = [];

      for (var user in users) {
        // Strict secondary validation: Ensure non-consenting and doctors never appear
        if (!user.isDoctor && user.shareDataResearch) {
          patients.add(user);
        }
      }

      return patients;
    });
  }
}
