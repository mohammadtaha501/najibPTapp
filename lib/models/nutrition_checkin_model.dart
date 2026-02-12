import 'package:cloud_firestore/cloud_firestore.dart';

enum AdherenceStatus {
  followedWell,
  partiallyFollowed,
  didNotFollow,
}

extension AdherenceStatusExtension on AdherenceStatus {
  String get label {
    switch (this) {
      case AdherenceStatus.followedWell:
        return 'Followed well';
      case AdherenceStatus.partiallyFollowed:
        return 'Partially followed';
      case AdherenceStatus.didNotFollow:
        return 'Did not follow';
    }
  }

  String get emoji {
    switch (this) {
      case AdherenceStatus.followedWell:
        return '✅';
      case AdherenceStatus.partiallyFollowed:
        return '⚠️';
      case AdherenceStatus.didNotFollow:
        return '❌';
    }
  }
}

class WeeklyNutritionCheckIn {
  final String? id;
  final String clientId;
  final String nutritionPlanId;
  final DateTime weekStartDate; // Standardized to Monday 00:00
  final AdherenceStatus status;
  final String notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  WeeklyNutritionCheckIn({
    this.id,
    required this.clientId,
    required this.nutritionPlanId,
    required this.weekStartDate,
    required this.status,
    this.notes = '',
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'nutritionPlanId': nutritionPlanId,
      'weekStartDate': weekStartDate.millisecondsSinceEpoch,
      'status': status.index,
      'notes': notes,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory WeeklyNutritionCheckIn.fromMap(Map<String, dynamic> map, String id) {
    DateTime? _parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return WeeklyNutritionCheckIn(
      id: id,
      clientId: map['clientId'] ?? '',
      nutritionPlanId: map['nutritionPlanId'] ?? '',
      weekStartDate: _parseDateTime(map['weekStartDate']) ?? DateTime.now(),
      status: AdherenceStatus.values[map['status'] ?? 0],
      notes: map['notes'] ?? '',
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
    );
  }

  WeeklyNutritionCheckIn copyWith({
    String? id,
    String? clientId,
    String? nutritionPlanId,
    DateTime? weekStartDate,
    AdherenceStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WeeklyNutritionCheckIn(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      nutritionPlanId: nutritionPlanId ?? this.nutritionPlanId,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
