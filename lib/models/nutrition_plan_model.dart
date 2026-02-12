import 'package:cloud_firestore/cloud_firestore.dart';

enum NutritionGoal {
  fatLoss,
  muscleGain,
  maintenance,
  custom,
}

enum NutritionPlanMode {
  referenceOnly,
  weeklyAdherence,
}

extension NutritionGoalExtension on NutritionGoal {
  String get label {
    switch (this) {
      case NutritionGoal.fatLoss:
        return 'Fat Loss';
      case NutritionGoal.muscleGain:
        return 'Muscle Gain';
      case NutritionGoal.maintenance:
        return 'Maintenance';
      case NutritionGoal.custom:
        return 'Custom';
    }
  }
}

class NutritionSection {
  final String title;
  final String content;

  NutritionSection({
    required this.title,
    required this.content,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
    };
  }

  factory NutritionSection.fromMap(Map<String, dynamic> map) {
    return NutritionSection(
      title: map['title'] ?? '',
      content: map['content'] ?? '',
    );
  }
}

class NutritionPlan {
  final String? id;
  final String clientId;
  final String coachId;
  final String title;
  final NutritionGoal goal;
  final NutritionPlanMode mode;
  final List<NutritionSection> sections;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastViewedByClient;

  NutritionPlan({
    this.id,
    required this.clientId,
    required this.coachId,
    required this.title,
    required this.goal,
    this.mode = NutritionPlanMode.referenceOnly,
    required this.sections,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastViewedByClient,
  })  : this.createdAt = createdAt ?? DateTime.now(),
        this.updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'coachId': coachId,
      'title': title,
      'goal': goal.index,
      'mode': mode.index,
      'sections': sections.map((x) => x.toMap()).toList(),
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
      'lastViewedByClient': lastViewedByClient?.millisecondsSinceEpoch,
    };
  }

  factory NutritionPlan.fromMap(Map<String, dynamic> map, String id) {
    DateTime? _parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is Timestamp) return value.toDate();
      return null;
    }

    return NutritionPlan(
      id: id,
      clientId: map['clientId'] ?? '',
      coachId: map['coachId'] ?? '',
      title: map['title'] ?? '',
      goal: NutritionGoal.values[map['goal'] ?? 0],
      mode: NutritionPlanMode.values[map['mode'] ?? 0],
      sections: List<NutritionSection>.from(
          map['sections']?.map((x) => NutritionSection.fromMap(x)) ?? []),
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(map['updatedAt']) ?? DateTime.now(),
      lastViewedByClient: _parseDateTime(map['lastViewedByClient']),
    );
  }

  NutritionPlan copyWith({
    String? id,
    String? clientId,
    String? coachId,
    String? title,
    NutritionGoal? goal,
    NutritionPlanMode? mode,
    List<NutritionSection>? sections,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastViewedByClient,
  }) {
    return NutritionPlan(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      coachId: coachId ?? this.coachId,
      title: title ?? this.title,
      goal: goal ?? this.goal,
      mode: mode ?? this.mode,
      sections: sections ?? this.sections,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastViewedByClient: lastViewedByClient ?? this.lastViewedByClient,
    );
  }
}
