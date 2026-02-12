import 'package:cloud_firestore/cloud_firestore.dart';

enum NutritionStatus { met, missed }

class NutritionLog {
  final String? id;
  final String clientId;
  final DateTime date; // Standardized to midnight
  final NutritionStatus status;
  final String notes;
  final DateTime timestamp;

  NutritionLog({
    this.id,
    required this.clientId,
    required this.date,
    required this.status,
    required this.notes,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'date': Timestamp.fromDate(date),
      'status': status.index,
      'notes': notes,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory NutritionLog.fromMap(Map<String, dynamic> map, String id) {
    return NutritionLog(
      id: id,
      clientId: map['clientId'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      status: NutritionStatus.values[map['status'] ?? 0],
      notes: map['notes'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
    );
  }
}
