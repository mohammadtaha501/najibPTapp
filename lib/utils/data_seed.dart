import 'package:untitled3/models/exercise_model.dart';

class DataSeed {
  static List<Exercise> getInitialExercises() {
    return [
      // Quadriceps
      Exercise(name: 'Barbell Box Squat', muscleGroup: 'Quadriceps'),
      Exercise(name: 'Hack Squat', muscleGroup: 'Quadriceps'),
      Exercise(name: 'Leg Press', muscleGroup: 'Quadriceps'),
      Exercise(name: 'Leg Extension', muscleGroup: 'Quadriceps'),
      Exercise(name: 'Front Squat', muscleGroup: 'Quadriceps'),
      // Glutes & Hamstrings
      Exercise(name: 'Barbell Deadlift', muscleGroup: 'Glutes_Hamstrings'),
      Exercise(name: 'Romanian Deadlift', muscleGroup: 'Glutes_Hamstrings'),
      Exercise(name: 'Lying Leg Curl', muscleGroup: 'Glutes_Hamstrings'),
      Exercise(name: 'Hip Thrust', muscleGroup: 'Glutes_Hamstrings'),
      Exercise(name: 'Seated Leg Curl', muscleGroup: 'Glutes_Hamstrings'),
      // Calves
      Exercise(name: 'Barbell Calf Raise', muscleGroup: 'Calves'),
      Exercise(name: 'Seated Calf Raise', muscleGroup: 'Calves'),
      // Chest
      Exercise(name: 'Barbell Bench Press', muscleGroup: 'Chest'),
      Exercise(name: 'Incline Dumbbell Press', muscleGroup: 'Chest'),
      Exercise(name: 'Chest Fly', muscleGroup: 'Chest'),
      Exercise(name: 'Push Ups', muscleGroup: 'Chest'),
      // Back
      Exercise(name: 'Lat Pulldown', muscleGroup: 'Back'),
      Exercise(name: 'Barbell Row', muscleGroup: 'Back'),
      Exercise(name: 'Seated Cable Row', muscleGroup: 'Back'),
      Exercise(name: 'Pull Ups', muscleGroup: 'Back'),
      Exercise(name: 'T-Bar Row', muscleGroup: 'Back'),
      // Shoulders
      Exercise(name: 'Overhead Press', muscleGroup: 'Shoulders'),
      Exercise(name: 'Lateral Raise', muscleGroup: 'Shoulders'),
      Exercise(name: 'Front Raise', muscleGroup: 'Shoulders'),
      Exercise(name: 'Face Pulls', muscleGroup: 'Shoulders'),
      // Triceps
      Exercise(name: 'Tricep Pushdown', muscleGroup: 'Triceps'),
      Exercise(name: 'Skull Crushers', muscleGroup: 'Triceps'),
      Exercise(name: 'Overhead Tricep Extension', muscleGroup: 'Triceps'),
      // Biceps
      Exercise(name: 'Barbell Curl', muscleGroup: 'Biceps'),
      Exercise(name: 'Hammer Curl', muscleGroup: 'Biceps'),
      Exercise(name: 'Preacher Curl', muscleGroup: 'Biceps'),
      // Abs
      Exercise(name: 'Crunches', muscleGroup: 'Abs'),
      Exercise(name: 'Plank', muscleGroup: 'Abs'),
      Exercise(name: 'Hanging Leg Raise', muscleGroup: 'Abs'),
    ];
  }
}
