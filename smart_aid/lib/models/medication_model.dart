import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/firestore_parser.dart';

class MedicationModel {
  final String id;
  final String name;
  final String composition;
  final String rationale;
  final int dailyDoseLimit;
  final List<String> scheduledTimes;
  final DateTime? startDate;
  final DateTime? endDate;
  final int? gapInDays;
  final DateTime? createdAt;

  MedicationModel({
    required this.id,
    required this.name,
    required this.composition,
    required this.rationale,
    required this.dailyDoseLimit,
    required this.scheduledTimes,
    this.startDate,
    this.endDate,
    this.gapInDays,
    this.createdAt,
  });

  factory MedicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MedicationModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      composition: data['composition'] as String? ?? '',
      rationale: data['rationale'] as String? ?? '',
      dailyDoseLimit: FirestoreParser.parseInt(data['dailyDoseLimit'], defaultValue: 1),
      scheduledTimes: FirestoreParser.parseStringList(data['scheduledTimes']),
      startDate: FirestoreParser.parseDate(data['startDate']),
      endDate: FirestoreParser.parseDate(data['endDate']),
      gapInDays: data['gapInDays'] == null ? null : FirestoreParser.parseInt(data['gapInDays']),
      createdAt: FirestoreParser.parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'composition': composition,
      'rationale': rationale,
      'dailyDoseLimit': dailyDoseLimit,
      'scheduledTimes': scheduledTimes,
      if (startDate != null) 'startDate': Timestamp.fromDate(startDate!),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      if (gapInDays != null) 'gapInDays': gapInDays,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }

  MedicationModel copyWith({
    String? id,
    String? name,
    String? composition,
    String? rationale,
    int? dailyDoseLimit,
    List<String>? scheduledTimes,
    DateTime? startDate,
    DateTime? endDate,
    int? gapInDays,
    DateTime? createdAt,
  }) {
    return MedicationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      composition: composition ?? this.composition,
      rationale: rationale ?? this.rationale,
      dailyDoseLimit: dailyDoseLimit ?? this.dailyDoseLimit,
      scheduledTimes: scheduledTimes ?? this.scheduledTimes,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      gapInDays: gapInDays ?? this.gapInDays,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
