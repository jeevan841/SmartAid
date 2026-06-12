import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_parser.dart';

class DoseLogModel {
  final String id;
  final String medicationId;
  final String medicationName;
  final int count;
  final String date;
  final DateTime? lastTaken;

  DoseLogModel({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.count,
    required this.date,
    this.lastTaken,
  });

  factory DoseLogModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DoseLogModel(
      id: doc.id,
      medicationId: data['medicationId'] as String? ?? '',
      medicationName: data['medicationName'] as String? ?? '',
      count: FirestoreParser.parseInt(data['count'], defaultValue: 0),
      date: data['date'] as String? ?? '',
      lastTaken: FirestoreParser.parseDate(data['lastTaken']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'medicationId': medicationId,
      'medicationName': medicationName,
      'count': count,
      'date': date,
      if (lastTaken != null) 'lastTaken': Timestamp.fromDate(lastTaken!),
    };
  }

  DoseLogModel copyWith({
    String? id,
    String? medicationId,
    String? medicationName,
    int? count,
    String? date,
    DateTime? lastTaken,
  }) {
    return DoseLogModel(
      id: id ?? this.id,
      medicationId: medicationId ?? this.medicationId,
      medicationName: medicationName ?? this.medicationName,
      count: count ?? this.count,
      date: date ?? this.date,
      lastTaken: lastTaken ?? this.lastTaken,
    );
  }
}
