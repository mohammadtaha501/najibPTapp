import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled3/models/exercise_model.dart';

enum ProgramStatus { assigned, active, replaced, completed }

class Program {
  final String? id;
  final String name;
  final String coachId;
  final bool isTemplate;
  final String? createdForClientId;
  final bool isPublic;
  final int totalWeeks;
  final String? assignedClientId;
  final DateTime? startDate;
  final ProgramStatus status;
  final int version;
  final int currentWeek;
  final int currentDay;
  final String? coachNotes;
  final DateTime? notesUpdatedAt;
  final DateTime? notesReadAt;
  final String? parentProgramId; // Link to the original public program if this is a copy

  Program({
    this.id,
    required this.name,
    required this.coachId,
    this.isPublic = false,
    this.isTemplate = false,
    required this.totalWeeks,
    this.assignedClientId,
    this.startDate,
    this.createdForClientId,
    this.status = ProgramStatus.assigned,
    this.version = 1,
    this.currentWeek = 1,
    this.currentDay = 1,
    this.coachNotes,
    this.notesUpdatedAt,
    this.notesReadAt,
    this.parentProgramId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'coachId': coachId,
      'isPublic': isPublic,
      'isTemplate': isTemplate,
      'totalWeeks': totalWeeks,
      'assignedClientId': assignedClientId,
      'startDate': startDate != null ? Timestamp.fromDate(startDate!) : null,
      'createdForClientId': createdForClientId,
      'status': status.index,
      'version': version,
      'currentWeek': currentWeek,
      'currentDay': currentDay,
      'coachNotes': coachNotes,
      'notesUpdatedAt': notesUpdatedAt != null ? Timestamp.fromDate(notesUpdatedAt!) : null,
      'notesReadAt': notesReadAt != null ? Timestamp.fromDate(notesReadAt!) : null,
      'parentProgramId': parentProgramId,
    };
  }

  factory Program.fromMap(Map<String, dynamic> map, String documentId) {
    return Program(
      id: documentId,
      name: map['name'] ?? '',
      coachId: map['coachId'] ?? '',
      isPublic: map['isPublic'] ?? false,
      isTemplate: map['isTemplate'] ?? false,
      totalWeeks: map['totalWeeks'] ?? 1,
      assignedClientId: map['assignedClientId'],
      startDate: (map['startDate'] as Timestamp?)?.toDate(),
      createdForClientId: map['createdForClientId'],
      status: ProgramStatus.values[map['status'] ?? 0],
      version: map['version'] ?? 1,
      currentWeek: map['currentWeek'] ?? 1,
      currentDay: map['currentDay'] ?? 1,
      coachNotes: map['coachNotes'],
      notesUpdatedAt: (map['notesUpdatedAt'] as Timestamp?)?.toDate(),
      notesReadAt: (map['notesReadAt'] as Timestamp?)?.toDate(),
      parentProgramId: map['parentProgramId'],
    );
  }
}

class WorkoutDay {
  final String? id;
  final int week;
  final int day;
  final String muscleGroup;
  final List<Exercise> exercises;

  WorkoutDay({
    this.id,
    required this.week,
    required this.day,
    required this.muscleGroup,
    required this.exercises,
  });

  Map<String, dynamic> toMap() {
    return {
      'week': week,
      'day': day,
      'muscleGroup': muscleGroup,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }

  factory WorkoutDay.fromMap(Map<String, dynamic> map, String documentId) {
    return WorkoutDay(
      id: documentId,
      week: map['week'] ?? 1,
      day: map['day'] ?? 1,
      muscleGroup: map['muscleGroup'] ?? '',
      exercises: (map['exercises'] as List? ?? [])
          .map((e) => Exercise.fromMap(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
