import '../models/user_model.dart';
import '../repositories/user_repository.dart';

class UserService {
  final UserRepository userRepository;

  UserService({required this.userRepository});

  // ---------------------------------------------------------------------------
  // STREAMS (Typed & Safe)
  // ---------------------------------------------------------------------------

  Stream<UserModel?> getUserStream(String userId) {
    return userRepository.getUserStream(userId);
  }

  // ---------------------------------------------------------------------------
  // OPERATIONS
  // ---------------------------------------------------------------------------

  Future<void> updateConsent({
    required String userId,
    required bool consent,
  }) async {
    await userRepository.updateConsent(userId: userId, consent: consent);
  }

  Future<void> addEmergencyContact({
    required String userId,
    required String contact,
  }) async {
    await userRepository.addEmergencyContact(userId: userId, contact: contact);
  }

  Future<void> removeEmergencyContact({
    required String userId,
    required String contact,
  }) async {
    await userRepository.removeEmergencyContact(userId: userId, contact: contact);
  }
}
