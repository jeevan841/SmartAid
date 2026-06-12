import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_parser.dart';

class HealthRecordModel {
  final String id;
  final String fileName;
  final String localPath;
  final DateTime? createdAt;

  HealthRecordModel({
    required this.id,
    required this.fileName,
    required this.localPath,
    this.createdAt,
  });

  factory HealthRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    final fileName = FirestoreParser.parseString(data['fileName']) ?? '';
    final localPath = FirestoreParser.parseString(data['localPath']) ?? '';

    // Constraint: Health record streams should skip malformed metadata documents safely.
    if (fileName.isEmpty || localPath.isEmpty) {
      throw const FormatException("Missing or invalid 'fileName' or 'localPath'.");
    }

    return HealthRecordModel(
      id: doc.id,
      fileName: fileName,
      localPath: localPath,
      createdAt: FirestoreParser.parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fileName': fileName,
      'localPath': localPath,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  HealthRecordModel copyWith({
    String? id,
    String? fileName,
    String? localPath,
    DateTime? createdAt,
  }) {
    return HealthRecordModel(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      localPath: localPath ?? this.localPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
