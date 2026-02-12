enum ExerciseStatus { notStarted, inProgress, completed, skipped }

class WorkoutLog {
  final String? id;
  final String clientId;
  final String programId;
  final String workoutDayId;
  final DateTime date;
  final List<ExerciseLog> exerciseLogs;
  final String? notes;
  final String? feedback;

  WorkoutLog({
    this.id,
    required this.clientId,
    required this.programId,
    required this.workoutDayId,
    required this.date,
    required this.exerciseLogs,
    this.notes,
    this.feedback,
  });

  Map<String, dynamic> toMap() {
    return {
      'clientId': clientId,
      'programId': programId,
      'workoutDayId': workoutDayId,
      'date': date.toIso8601String(),
      'exerciseLogs': exerciseLogs.map((e) => e.toMap()).toList(),
      'notes': notes,
      'feedback': feedback,
    };
  }

  factory WorkoutLog.fromMap(Map<String, dynamic> map, String documentId) {
    return WorkoutLog(
      id: documentId,
      clientId: map['clientId'] ?? '',
      programId: map['programId'] ?? '',
      workoutDayId: map['workoutDayId'] ?? '',
      date: DateTime.parse(map['date'] ?? DateTime.now().toIso8601String()),
      exerciseLogs: (map['exerciseLogs'] as List? ?? [])
          .map((e) => ExerciseLog.fromMap(e as Map<String, dynamic>))
          .toList(),
      notes: map['notes'],
      feedback: map['feedback'],
    );
  }
}

class ExerciseLog {
  final String exerciseName;
  final List<SetLog> sets;
  final String? notes;
  final ExerciseStatus status;
  final int programVersion;
  final DateTime timestamp;
  final DateTime? sessionStartTime;

  ExerciseLog({
    required this.exerciseName,
    required this.sets,
    this.notes,
    this.status = ExerciseStatus.notStarted,
    this.programVersion = 1,
    required this.timestamp,
    this.sessionStartTime,
  });

  bool get isTerminal => status == ExerciseStatus.completed || status == ExerciseStatus.skipped;

  Map<String, dynamic> toMap() {
    return {
      'exerciseName': exerciseName,
      'sets': sets.map((s) => s.toMap()).toList(),
      'notes': notes,
      'status': status.index,
      'programVersion': programVersion,
      'timestamp': timestamp.toIso8601String(),
      'sessionStartTime': sessionStartTime?.toIso8601String(),
    };
  }

  factory ExerciseLog.fromMap(Map<String, dynamic> map) {
    return ExerciseLog(
      exerciseName: map['exerciseName'] ?? '',
      sets: (map['sets'] as List? ?? [])
          .map((s) => SetLog.fromMap(s as Map<String, dynamic>))
          .toList(),
      notes: map['notes'],
      status: ExerciseStatus.values[map['status'] ?? 0],
      programVersion: map['programVersion'] ?? 1,
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
      sessionStartTime: map['sessionStartTime'] != null ? DateTime.parse(map['sessionStartTime']) : null,
    );
  }
}

class SetLog {
  double weight;
  int reps;
  int? rpe;

  SetLog({
    required this.weight,
    required this.reps,
    this.rpe,
  });

  Map<String, dynamic> toMap() {
    return {
      'weight': weight,
      'reps': reps,
      'rpe': rpe,
    };
  }

  factory SetLog.fromMap(Map<String, dynamic> map) {
    return SetLog(
      weight: (map['weight'] ?? 0).toDouble(),
      reps: map['reps'] ?? 0,
      rpe: map['rpe'],
    );
  }
}
