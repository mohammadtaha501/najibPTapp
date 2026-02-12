import 'dart:io';
import 'package:ptapp/models/exercise_model.dart';
import 'package:ptapp/services/database_service.dart';

class ExerciseSeeder {
  static Future<void> seedFromExtractedFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      print('File not found: $filePath');
      return;
    }

    final content = await file.readAsString();
    final lines = content.split('\n');
    
    // Find the DATA sheet section
    int dataStartIndex = lines.indexWhere((line) => line.contains('--- Sheet: DATA ---'));
    if (dataStartIndex == -1) {
      print('DATA sheet not found in file');
      return;
    }

    // Header is at dataStartIndex + 1
    // Sets	Reps	Rest_Seconds		Quadriceps	Glutes_Hamstrings	Calves	Chest	Back	Shoulders	Triceps	Biceps	Abs	Other
    final headerLine = lines[dataStartIndex + 1];
    final headers = headerLine.split('\t');
    
    // Muscle groups are from index 4 onwards
    // final muscleGroups = headers.sublist(4).where((h) => h.trim().isNotEmpty).toList();
    final muscleGroupIndices = <String, int>{};
    for (var i = 0; i < headers.length; i++) {
      if (i >= 4 && headers[i].trim().isNotEmpty) {
        muscleGroupIndices[headers[i].trim()] = i;
      }
    }

    final List<Exercise> exercisesToSeed = [];
    final dbService = DatabaseService();

    // Parse exercise rows
    for (int i = dataStartIndex + 2; i < lines.length; i++) {
      final line = lines[i];
      if (line.startsWith('--- Sheet:')) break; // End of DATA sheet
      
      final cells = line.split('\t');
      if (cells.length < 5) continue;

      muscleGroupIndices.forEach((group, index) {
        if (index < cells.length) {
          final exerciseName = cells[index].trim();
          if (exerciseName.isNotEmpty) {
            exercisesToSeed.add(Exercise(
              name: exerciseName,
              muscleGroup: group,
              description: 'Imported from sample plan',
            ));
          }
        }
      });
    }

    print('Found ${exercisesToSeed.length} exercises to seed.');
    if (exercisesToSeed.isNotEmpty) {
      await dbService.seedExercises(exercisesToSeed);
      print('Successfully seeded exercises.');
    }
  }
}
