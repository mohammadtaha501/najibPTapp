class Exercise {
  static const List<String> muscleGroups = [
    'Quadriceps',
    'Glutes_Hamstrings',
    'Calves',
    'Chest',
    'Back',
    'Shoulders',
    'Triceps',
    'Biceps',
    'Abs',
    'Other',
  ];

  final String? id;
  final String name;
  final String? description;
  final String muscleGroup;
  final int? sets;
  final String? reps;
  final int? restTime;
  final String? videoUrl;
  final String? duration;
  final String? rpe;
  final String? altExercise;
  final String? supersetLabel; // e.g. "A1", "B1", "Superset 1"
  final String? tempo; // e.g. "3-0-1-0"
  final String? targetWeight; // e.g. "80kg" or "Bodyweight"
  final int? totalReps;
  final double? volume;
  final String? note;

  Exercise({
    this.id,
    required this.name,
    this.description,
    required this.muscleGroup,
    this.sets,
    this.reps,
    this.restTime,
    this.videoUrl,
    this.duration,
    this.rpe,
    this.altExercise,
    this.supersetLabel,
    this.tempo,
    this.targetWeight,
    this.totalReps,
    this.volume,
    this.note,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'muscleGroup': muscleGroup,
      'sets': sets,
      'reps': reps,
      'restTime': restTime,
      'videoUrl': videoUrl,
      'duration': duration,
      'rpe': rpe,
      'altExercise': altExercise,
      'supersetLabel': supersetLabel,
      'tempo': tempo,
      'targetWeight': targetWeight,
      'totalReps': totalReps,
      'volume': volume,
      'note': note,
    };
  }

  factory Exercise.fromMap(Map<String, dynamic> map, [String? documentId]) {
    return Exercise(
      id: documentId ?? map['id'],
      name: map['name'] ?? '',
      description: map['description'],
      muscleGroup: map['muscleGroup'] ?? 'Other',
      sets: map['sets'],
      reps: map['reps'],
      restTime: map['restTime'],
      videoUrl: map['videoUrl'],
      duration: map['duration'],
      rpe: map['rpe'],
      altExercise: map['altExercise'],
      supersetLabel: map['supersetLabel'],
      tempo: map['tempo'],
      targetWeight: map['targetWeight'],
      totalReps: map['totalReps'],
      volume: map['volume']?.toDouble(),
      note: map['note'],
    );
  }
}
