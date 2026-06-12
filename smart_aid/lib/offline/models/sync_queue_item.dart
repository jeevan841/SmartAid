import 'dart:convert';

enum SyncOperationType {
  addMedication,
  addAppointment,
  updateAppointment,
  deleteAppointment,
  saveDoseLog,
}

class SyncQueueItem {
  final String id;
  final SyncOperationType operationType;
  final String userId;
  final Map<String, dynamic> payload;
  final int timestamp; // Epoch ms for ordering

  SyncQueueItem({
    required this.id,
    required this.operationType,
    required this.userId,
    required this.payload,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'operationType': operationType.name,
      'userId': userId,
      'payload': jsonEncode(payload),
      'timestamp': timestamp,
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as String,
      operationType: SyncOperationType.values.byName(map['operationType'] as String),
      userId: map['userId'] as String,
      payload: jsonDecode(map['payload'] as String) as Map<String, dynamic>,
      timestamp: map['timestamp'] as int,
    );
  }
}
