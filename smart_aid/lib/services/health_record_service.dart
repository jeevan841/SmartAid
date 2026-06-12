import '../models/health_record_model.dart';
import '../repositories/health_record_repository.dart';

class HealthRecordService {
  final HealthRecordRepository healthRecordRepository;

  HealthRecordService({required this.healthRecordRepository});

  // ---------------------------------------------------------------------------
  // FIRESTORE METADATA OPERATIONS
  // ---------------------------------------------------------------------------

  Stream<List<HealthRecordModel>> getHealthRecordsStream(String userId) {
    return healthRecordRepository.getHealthRecordsStream(userId);
  }

  Future<void> saveRecordMetadata({
    required String userId,
    required String fileName,
    required String localPath,
  }) async {
    await healthRecordRepository.saveRecordMetadata(userId: userId, fileName: fileName, localPath: localPath);
  }

  Future<void> deleteRecordMetadata({
    required String userId,
    required String recordId,
  }) async {
    await healthRecordRepository.deleteRecordMetadata(userId: userId, recordId: recordId);
  }

  // ---------------------------------------------------------------------------
  // LOCAL FILESYSTEM OPERATIONS
  // ---------------------------------------------------------------------------

  /// Attempts to open a local file.
  /// Returns false if the file is missing or invalid, ensuring the UI can notify the user gracefully.
  Future<bool> openLocalFile(String localPath) async {
    return await healthRecordRepository.openLocalFile(localPath);
  }

  /// Attempts to delete a local file.
  /// Does not throw exceptions if the file is missing or locked.
  Future<void> deleteLocalFile(String localPath) async {
    await healthRecordRepository.deleteLocalFile(localPath);
  }

  /// Combines Firestore deletion and Local file deletion safely.
  Future<void> deleteRecord({
    required String userId,
    required HealthRecordModel record,
  }) async {
    // We intentionally separate these try-catch blocks.
    // If local deletion fails, we still want to remove the metadata if possible, or vice versa depending on rules.
    // By doing metadata first, we ensure it's removed from UI.
    await deleteRecordMetadata(userId: userId, recordId: record.id);
    await deleteLocalFile(record.localPath);
  }
}
