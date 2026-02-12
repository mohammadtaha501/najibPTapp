import 'package:flutter/material.dart';
import 'package:ptapp/models/exercise_model.dart';
import 'package:ptapp/services/database_service.dart';
import 'package:ptapp/utils/theme.dart';
import 'package:ptapp/widgets/youtube_dialog.dart';
import 'package:ptapp/screens/coach/exercise_editor_screen.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final DatabaseService _dbService = DatabaseService();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  late Stream<List<Exercise>> _exercisesStream;

  @override
  void initState() {
    super.initState();
    _exercisesStream = _dbService.getExercises();
  }

  final Map<String, List<String>> _categoryMap = {
    'Upper Body': ['Chest', 'Back', 'Shoulders', 'Triceps', 'Biceps'],
    'Lower Body': ['Quadriceps', 'Glutes_Hamstrings', 'Calves'],
    'Core': ['Abs'],
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Exercise Library'),
        actions: [

        ],
      ),
      body: Column(
        children: [
          _buildCategoryTabs(),
          _buildSearchOverlay(),
          Expanded(
            child: StreamBuilder<List<Exercise>>(
              stream: _exercisesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final exercises = (snapshot.data ?? []).where((e) {
                  // Search across name, muscle group, and description/equipment
                  final query = _searchQuery.toLowerCase();
                  final matchesSearch = e.name.toLowerCase().contains(query) || 
                                      e.muscleGroup.toLowerCase().contains(query) || 
                                      (e.description?.toLowerCase().contains(query) ?? false);
                  
                  // Category filtering
                  bool matchesCategory = true;
                  if (_selectedCategory != 'All') {
                    final targetMuscles = _categoryMap[_selectedCategory] ?? [];
                    matchesCategory = targetMuscles.contains(e.muscleGroup);
                  }

                  return matchesSearch && matchesCategory;
                }).toList();

                if (exercises.isEmpty) {
                  return const Center(child: Text('No exercises found.', style: TextStyle(color: AppTheme.mutedTextColor)));
                }

                return ListView.builder(
                  itemCount: exercises.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return _buildExerciseCard(context, exercise);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = ['All', 'Upper Body', 'Lower Body', 'Core'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: categories.map((cat) {
            final isSelected = _selectedCategory == cat;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.05),
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(color: AppTheme.primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
                    ] : [],
                  ),
                  child: Text(
                    cat,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchOverlay() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _showAddExerciseDialog(context),
            child: Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.add_box_outlined,
                color:Colors.black,
              ),
            ),
          ),
          SizedBox(width: 8,),
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search by name of exercise',
                prefixIcon: const Icon(Icons.search, size: 20, color: AppTheme.mutedTextColor),
                filled: true,
                fillColor: AppTheme.surfaceColor,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Exercise exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Exercise?'),
        content: const Text(
          'If you delete this exercise then the users having this exercise in their program will not be able to access this exercise',
          style: TextStyle(color: Colors.redAccent),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _dbService.deleteExercise(exercise.id!);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, Exercise exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: const DecorationImage(
          image: NetworkImage('https://images.unsplash.com/photo-1517836357463-d25dfeac3438?q=80&w=1000'), 
          fit: BoxFit.cover,
        ),
      ),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ExerciseEditorScreen(exerciseToEdit: exercise, isReadOnly: true),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
            ),
            Positioned(
              left: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    exercise.name.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16, letterSpacing: 1),
                  ),
                  Text(
                    'Tap to view details',
                    style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10),
                  ),
                ],
              ),
            ),
            if (exercise.videoUrl != null)
              Positioned(
                right: 16,
                top: 16,
                child: GestureDetector(
                  onTap: () => showExerciseGuidance(context, exercise.name, exercise.videoUrl!),
                  child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 40),
                ),
              ),
            Positioned(
              right: exercise.videoUrl != null ? 64 : 16,
              top: 16,
              child: GestureDetector(
                onTap: () => _showDeleteDialog(exercise),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.black45, borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExerciseDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExerciseEditorScreen(
          onExerciseCreated: (exercise) {
            // The library screen listens to the stream, so it will update automatically.
          },
        ),
      ),
    );
  }
}
