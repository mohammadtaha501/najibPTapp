
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:ptapp/models/program_model.dart';
import 'package:ptapp/models/log_model.dart';
import 'package:ptapp/services/database_service.dart';
import 'package:ptapp/utils/theme.dart';

class ExerciseDetailLoggingScreen extends StatefulWidget {
  final Program program;
  final WorkoutDay workoutDay;
  final dynamic exercise; // Using dynamic because it's from the WorkoutDay.exercises list
  final ExerciseLog? existingLog;
  final DateTime? sessionStartTime;

  const ExerciseDetailLoggingScreen({
    super.key,
    required this.program,
    required this.workoutDay,
    required this.exercise,
    this.existingLog,
    this.sessionStartTime,
  });

  @override
  State<ExerciseDetailLoggingScreen> createState() => _ExerciseDetailLoggingScreenState();
}

class _ExerciseDetailLoggingScreenState extends State<ExerciseDetailLoggingScreen> {
  late YoutubePlayerController _ytController;
  final DatabaseService _dbService = DatabaseService();
  final List<TextEditingController> _weightControllers = [];
  final List<TextEditingController> _repsControllers = [];
  final TextEditingController _notesController = TextEditingController();
  bool _isLoading = false;
  bool _hasVideo = false;

  @override
  void initState() {
    super.initState();
    _hasVideo = widget.exercise.videoUrl != null && widget.exercise.videoUrl!.isNotEmpty;
    if (_hasVideo) {
      final videoId = YoutubePlayer.convertUrlToId(widget.exercise.videoUrl!) ?? '';
      _ytController = YoutubePlayerController(
        initialVideoId: videoId,
        flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
      );
    }

    final setsCount = int.tryParse(widget.exercise.sets.toString()) ?? 1;
    for (int i = 0; i < setsCount; i++) {
        // Initialize with target data if available or previous logs
        String initialWeight = widget.exercise.targetWeight?.toString() ?? '';
        String initialReps = widget.exercise.reps?.toString() ?? '';
        
        if (widget.existingLog != null && widget.existingLog!.sets.length > i) {
          initialWeight = widget.existingLog!.sets[i].weight.toString();
          initialReps = widget.existingLog!.sets[i].reps.toString();
        }

        _weightControllers.add(TextEditingController(text: initialWeight));
        _repsControllers.add(TextEditingController(text: initialReps));
    }
    _notesController.text = widget.existingLog?.notes ?? '';
  }

  @override
  void dispose() {
    if (_hasVideo) _ytController.dispose();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    for (var c in _weightControllers) {
      c.dispose();
    }
    for (var c in _repsControllers) {
      c.dispose();
    }
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasVideo) {
      return _buildScaffold(context, null);
    }

    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        // Ensure playback state is preserved. If it was paused, keep it paused.
        if (!_ytController.value.isPlaying) {
          _ytController.pause();
        }
      },
      player: YoutubePlayer(
        controller: _ytController,
        showVideoProgressIndicator: true,
        progressIndicatorColor: AppTheme.primaryColor,
        onReady: () {
          _ytController.addListener(() {});
        },
      ),
      builder: (context, player) {
        return _buildScaffold(context, player);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, Widget? player) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.exercise.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_hasVideo && player != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: player,
              ),
              const SizedBox(height: 20),
            ],
            
            Text('Prescription'.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                       _buildMetric('SETS', widget.exercise.sets?.toString() ?? '-'),
                       _buildMetric('REPS', widget.exercise.reps ?? '-'),
                       if (widget.exercise.targetWeight != null && widget.exercise.targetWeight!.isNotEmpty)
                         _buildMetric('WEIGHT', widget.exercise.targetWeight!),
                    ],
                  ),
                  if ((widget.exercise.tempo != null && widget.exercise.tempo!.isNotEmpty) || (widget.exercise.rpe != null && widget.exercise.rpe!.isNotEmpty)) ...[
                    const Divider(color: Colors.white10, height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        if (widget.exercise.tempo != null && widget.exercise.tempo!.isNotEmpty)
                          _buildMetric('TEMPO', widget.exercise.tempo!),
                        if (widget.exercise.rpe != null && widget.exercise.rpe!.isNotEmpty)
                          _buildMetric('RPE', widget.exercise.rpe!),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            if (widget.exercise.description != null && widget.exercise.description!.isNotEmpty) ...[
              const Text('Description', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.mutedTextColor)),
              const SizedBox(height: 4),
              Text(widget.exercise.description!, style: const TextStyle(fontSize: 14, color: Colors.white70)),
              const SizedBox(height: 24),
            ],

            const Divider(color: Colors.white10, height: 40),

            const Text('Log Progress', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            ...List.generate(_weightControllers.length, (index) => _buildSetRow(index)),

            const SizedBox(height: 24),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Exercise Notes',
                hintText: 'e.g. "Felt a bit tight in the hamstrings..."',
              ),
            ),
            
            const SizedBox(height: 40),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _skipExercise,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('SKIP'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : () => _saveProgress(markAsTerminal: false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text('SAVE'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isLoading ? null : () => _saveProgress(markAsTerminal: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                  : const Text(
                'SAVE & COMPLETE',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSetRow(int index) {
    String target = '';
    if (widget.exercise.targetWeight != null && widget.exercise.targetWeight!.isNotEmpty) target += '${widget.exercise.targetWeight}kg ';
    if (widget.exercise.reps != null && widget.exercise.reps!.isNotEmpty) target += 'x ${widget.exercise.reps}';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('SET ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 13)),
              if (target.isNotEmpty)
                Text('Target: $target', style: const TextStyle(color: AppTheme.mutedTextColor, fontSize: 11, fontStyle: FontStyle.italic)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _weightControllers[index],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Weight (kg)', isDense: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _repsControllers[index],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Reps', isDense: true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.mutedTextColor, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }

  Future<void> _saveProgress({required bool markAsTerminal}) async {
    setState(() => _isLoading = true);
    
    final List<SetLog> sets = [];
    for (int i = 0; i < _weightControllers.length; i++) {
        sets.add(SetLog(
          weight: double.tryParse(_weightControllers[i].text) ?? 0,
          reps: int.tryParse(_repsControllers[i].text) ?? 0,
        ));
    }

    final log = ExerciseLog(
      exerciseName: widget.exercise.name,
      sets: sets,
      notes: _notesController.text,
      status: markAsTerminal ? ExerciseStatus.completed : ExerciseStatus.inProgress,
      programVersion: widget.program.version,
      timestamp: DateTime.now(),
      sessionStartTime: widget.sessionStartTime,
    );

    await _dbService.logExerciseProgress(widget.program.id!, widget.workoutDay.id!, log, "");
    
    if (mounted) {
      Navigator.pop(context);
    }
  }

  Future<void> _skipExercise() async {
     setState(() => _isLoading = true);
     await _dbService.skipExercise(widget.program.id!, widget.workoutDay.id!, widget.exercise.name, widget.program.version);
     if (mounted) {
       Navigator.pop(context);
     }
  }
}
