import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_parser.dart';

class AppointmentModel {
  final String id;
  final String doctorName;
  final String reason;
  final DateTime? dateTime;
  final DateTime? createdAt;

  AppointmentModel({
    required this.id,
    required this.doctorName,
    required this.reason,
    this.dateTime,
    this.createdAt,
  });

  factory AppointmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Constraint: Invalid or missing appointment dates should cause the document 
    // to be skipped. We enforce this by throwing an exception if date is null.
    final parsedDate = FirestoreParser.parseDate(data['dateTime']);
    if (parsedDate == null) {
      throw const FormatException("Missing or invalid 'dateTime' field.");
    }

    return AppointmentModel(
      id: doc.id,
      doctorName: data['doctorName'] as String? ?? 'Unknown Doctor',
      reason: data['reason'] as String? ?? 'No reason provided',
      dateTime: parsedDate,
      createdAt: FirestoreParser.parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'doctorName': doctorName,
      'reason': reason,
      if (dateTime != null) 'dateTime': Timestamp.fromDate(dateTime!),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  AppointmentModel copyWith({
    String? id,
    String? doctorName,
    String? reason,
    DateTime? dateTime,
    DateTime? createdAt,
  }) {
    return AppointmentModel(
      id: id ?? this.id,
      doctorName: doctorName ?? this.doctorName,
      reason: reason ?? this.reason,
      dateTime: dateTime ?? this.dateTime,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
