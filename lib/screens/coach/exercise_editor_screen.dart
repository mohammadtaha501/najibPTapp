import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled3/models/exercise_model.dart';
import 'package:untitled3/services/database_service.dart';
import 'package:untitled3/utils/theme.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class ExerciseEditorScreen extends StatefulWidget {
  final Function(Exercise)? onExerciseCreated;
  final Exercise? exerciseToEdit;
  final bool isReadOnly;

  const ExerciseEditorScreen({
    super.key,
    this.onExerciseCreated,
    this.exerciseToEdit,
    this.isReadOnly = false,
  });

  @override
  State<ExerciseEditorScreen> createState() => _ExerciseEditorScreenState();
}

class _ExerciseEditorScreenState extends State<ExerciseEditorScreen> {
  final _dbService = DatabaseService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _videoController = TextEditingController();
  final _setsController = TextEditingController();
  final _repsController = TextEditingController();
  final _restController = TextEditingController();
  final _weightController = TextEditingController();
  final _totalRepsController = TextEditingController();
  final _volumeController = TextEditingController();
  final _noteController = TextEditingController();
  final _tempoController = TextEditingController();
  final _rpeController = TextEditingController();

  String? _selectedMuscleGroup;
  final List<String> _muscleGroups = [
    'Quadriceps', 'Glutes_Hamstrings', 'Calves', 'Chest', 'Back', 'Shoulders', 'Triceps', 'Biceps', 'Abs', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.exerciseToEdit != null) {
      final ex = widget.exerciseToEdit!;
      _nameController.text = ex.name;
      _descController.text = ex.description ?? '';
      _videoController.text = ex.videoUrl ?? '';
      _setsController.text = ex.sets?.toString() ?? '';
      _repsController.text = ex.reps ?? '';
      _restController.text = ex.restTime?.toString() ?? '';
      _weightController.text = ex.targetWeight ?? '';
      _totalRepsController.text = ex.totalReps?.toString() ?? '';
      _volumeController.text = ex.volume?.toString() ?? '';
      _noteController.text = ex.note ?? '';
      _tempoController.text = ex.tempo ?? '';
      _rpeController.text = ex.rpe ?? '';
      _selectedMuscleGroup = ex.muscleGroup;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _videoController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _restController.dispose();
    _weightController.dispose();
    _totalRepsController.dispose();
    _volumeController.dispose();
    _noteController.dispose();
    _tempoController.dispose();
    _rpeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedMuscleGroup == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a muscle group.')),
      );
      return;
    }

    String? videoUrl = _videoController.text.trim();
    if (videoUrl.isNotEmpty) {
      final videoId = YoutubePlayer.convertUrlToId(videoUrl);
      if (videoId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid YouTube link.')),
        );
        return;
      }
    } else {
      videoUrl = null;
    }

    final exercise = Exercise(
      id: widget.exerciseToEdit?.id,
      name: _nameController.text.trim(),
      muscleGroup: _selectedMuscleGroup!,
      description: _descController.text.trim(),
      videoUrl: videoUrl,
      sets: int.tryParse(_setsController.text),
      reps: _repsController.text.trim(),
      restTime: int.tryParse(_restController.text),
      targetWeight: _weightController.text.trim(),
      totalReps: int.tryParse(_totalRepsController.text),
      volume: double.tryParse(_volumeController.text),
      note: _noteController.text.trim(),
      tempo: _tempoController.text.trim(),
      rpe: _rpeController.text.trim(),
    );

    setState(() => _isLoading = true);
    try {
      final String id = await _dbService.addExercise(exercise);
      final completeExercise = Exercise(
        id: id,
        name: exercise.name,
        muscleGroup: exercise.muscleGroup,
        description: exercise.description,
        videoUrl: exercise.videoUrl,
        sets: exercise.sets,
        reps: exercise.reps,
        restTime: exercise.restTime,
        targetWeight: exercise.targetWeight,
        totalReps: exercise.totalReps,
        volume: exercise.volume,
        note: exercise.note,
        tempo: exercise.tempo,
        rpe: exercise.rpe,
      );

      if (widget.onExerciseCreated != null) {
        widget.onExerciseCreated!(completeExercise);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Exercise saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving exercise: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isReadOnly 
          ? 'Exercise Details' 
          : (widget.exerciseToEdit == null ? 'Create Exercise' : 'Edit Exercise')),
        actions: [
          if (!widget.isReadOnly)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _save,
            ),
        ],
      ),
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Basic Information'),
                  _buildTextField(_nameController, 'Exercise Name *', icon: Icons.fitness_center, validator: (v) => v!.isEmpty ? 'Name is required' : null),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _selectedMuscleGroup,
                    hint: const Text('Select Muscle Group Focus *'),
                    items: _muscleGroups.map((g) => DropdownMenuItem(value: g, child: Text(g.replaceAll('_', ' ')))).toList(),
                    onChanged: (widget.isReadOnly || _isLoading) ? null : (v) => setState(() => _selectedMuscleGroup = v!),
                    validator: (v) => v == null ? 'Muscle group is required' : null,
                    decoration: InputDecoration(
                      labelText: 'Muscle Group Focus *',
                      prefixIcon: const Icon(Icons.accessibility_new, size: 20, color: AppTheme.primaryColor),
                      filled: true,
                      fillColor: AppTheme.surfaceColor,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(_descController, 'Description *', icon: Icons.description, maxLines: 3, validator: (v) => v!.isEmpty ? 'Description is required' : null),
                  const SizedBox(height: 16),
                  _buildTextField(_videoController, 'YouTube Video Link', icon: Icons.video_library, hint: 'https://youtube.com/...'),
                  
                  const SizedBox(height: 32),
                  _buildSectionTitle('Default Settings (Optional)'),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_setsController, 'Sets *', icon: Icons.repeat, keyboardType: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(_repsController, 'Reps *', icon: Icons.format_list_numbered, hint: 'e.g. 8-12', validator: (v) => v!.isEmpty ? 'Required' : null)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_restController, 'Rest (Seconds)', icon: Icons.timer, keyboardType: TextInputType.number)),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          _weightController, 
                          'Weight (kg)', 
                          icon: Icons.monitor_weight,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(3),
                          ],
                          validator: (v) {
                            if (v != null && v.isNotEmpty) {
                              if (int.tryParse(v) == null) return 'Numbers only';
                              if (v.length > 3) return 'Max 3 digits';
                            }
                            return null;
                          },
                        )
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_totalRepsController, 'Total Reps', icon: Icons.summarize, keyboardType: TextInputType.number)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(_volumeController, 'Volume', icon: Icons.analytics, keyboardType: TextInputType.number)),
                    ],
                  ),
                   const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_tempoController, 'Tempo', icon: Icons.speed)),
                      const SizedBox(width: 16),
                      Expanded(child: _buildTextField(_rpeController, 'Target RPE', icon: Icons.bolt)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(_noteController, 'Coaching Note', icon: Icons.sticky_note_2, maxLines: 2),
                  
                  if (!widget.isReadOnly) ...[
                    const SizedBox(height: 40),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _save,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(_isLoading ? 'Saving...' : 'Save Exercise', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryColor),
                    SizedBox(height: 16),
                    Text('Uploading to Firebase...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller, 
    String label, 
    {IconData? icon, String? hint, int maxLines = 1, TextInputType keyboardType = TextInputType.text, String? Function(String?)? validator, List<TextInputFormatter>? inputFormatters}
  ) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      readOnly: widget.isReadOnly,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon, size: 20, color: AppTheme.primaryColor) : null,
        filled: true,
        fillColor: AppTheme.surfaceColor,
        alignLabelWithHint: maxLines > 1,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }
}
