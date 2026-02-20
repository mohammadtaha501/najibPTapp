import 'package:flutter/material.dart';
import 'package:ptapp/models/exercise_model.dart';
import 'package:ptapp/models/log_model.dart';
import 'package:ptapp/models/program_model.dart';
import 'package:ptapp/services/database_service.dart';
import 'package:ptapp/utils/theme.dart';

import '../../widgets/youtube_dialog.dart';

class WorkoutView extends StatefulWidget {
  final String clientId;
  final String programId;
  final WorkoutDay workoutDay;

  const WorkoutView({
    super.key,
    required this.clientId,
    required this.programId,
    required this.workoutDay,
  });

  @override
  State<WorkoutView> createState() => _WorkoutViewState();
}

class _WorkoutViewState extends State<WorkoutView> {
  final _dbService = DatabaseService();
  final Map<int, List<SetLog>> _logs = {};
  final Map<int, String> _exerciseNotes = {};
  final _sessionNotesController = TextEditingController();
  int _restRemaining = 0;
  bool _isTimerActive = false;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.workoutDay.exercises.length; i++) {
      final ex = widget.workoutDay.exercises[i];
      _logs[i] = List.generate(
        ex.sets ?? 3,
        (index) => SetLog(weight: 0, reps: 0),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.workoutDay.muscleGroup.toUpperCase()} WORKOUT'),
        actions: [
          _buildVolumeBadge(),
          IconButton(icon: const Icon(Icons.check), onPressed: _saveLog),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.symmetric(vertical: 16),
            children: _buildExerciseList(context),
          ),
          if (_isTimerActive) _buildTimerOverlay(),
        ],
      ),
    );
  }

  Widget _buildExerciseMedia(Exercise ex) {
    return GestureDetector(
      onTap: ex.videoUrl != null
          ? () => showExerciseGuidance(context, ex.name, ex.videoUrl!)
          : null,
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.black,
          image: ex.videoUrl != null
              ? null
              : const DecorationImage(
                  image: NetworkImage(
                    'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?q=80&w=1000',
                  ), // Placeholder for missing media
                  fit: BoxFit.cover,
                  opacity: 0.6,
                ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (ex.videoUrl != null)
              const Icon(Icons.play_circle_fill, size: 64, color: Colors.white),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildExerciseList(BuildContext context) {
    List<Widget> list = [];
    String? currentSuperset;

    for (int i = 0; i < widget.workoutDay.exercises.length; i++) {
      final exercise = widget.workoutDay.exercises[i];

      // Add Superset Header if applicable
      if (exercise.supersetLabel != null &&
          exercise.supersetLabel!.isNotEmpty &&
          exercise.supersetLabel != currentSuperset) {
        currentSuperset = exercise.supersetLabel;
        list.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.link, size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  currentSuperset!.toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (exercise.supersetLabel == null ||
          exercise.supersetLabel!.isEmpty) {
        currentSuperset = null;
      }

      list.add(
        Container(
          margin: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExerciseMedia(exercise),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${exercise.sets} sets • ${exercise.reps} Reps ${exercise.tempo != null && exercise.tempo!.isNotEmpty ? "• Tempo: ${exercise.tempo}" : ""} ${exercise.rpe != null && exercise.rpe!.isNotEmpty ? "• RPE ${exercise.rpe}" : ""} ${exercise.restTime != null ? "• ${exercise.restTime}s Rest" : ""}',
                      style: const TextStyle(
                        color: AppTheme.mutedTextColor,
                        fontSize: 13,
                      ),
                    ),
                    if (exercise.targetWeight != null &&
                        exercise.targetWeight!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          'TARGET: ${exercise.targetWeight}',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    ...List.generate(
                      exercise.sets ?? 3,
                      (setIndex) => _buildSetInputRow(i, setIndex),
                    ),
                    if (exercise.description != null &&
                        exercise.description!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Cues: ${exercise.description}',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    if (exercise.altExercise != null &&
                        exercise.altExercise!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _buildAlternativeRow('Alt: ${exercise.altExercise}'),
                    ],
                  ],
                ),
              ),
              const Divider(color: Colors.white10, thickness: 8),
            ],
          ),
        ),
      );
    }
    return list;
  }

  Widget _buildSetInputRow(int exIndex, int setIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
            child: Text(
              '${setIndex + 1}',
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          _buildSetField('0', 'kg', (v) {
            _logs[exIndex]![setIndex].weight = double.tryParse(v) ?? 0;
          }),
          Container(width: 1, height: 20, color: Colors.white10),
          _buildSetField('0', 'Reps', (v) {
            _logs[exIndex]![setIndex].reps = int.tryParse(v) ?? 0;
          }),
          TextButton(
            onPressed: () => _logSet(exIndex, setIndex),
            child: const Text(
              'LOG',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _logSet(int exIndex, int setIndex) {
    final rest = widget.workoutDay.exercises[exIndex].restTime ?? 60;
    _startRestTimer(rest);
    setState(() {}); // Update volume badge if needed
  }

  void _startRestTimer(int seconds) {
    setState(() {
      _restRemaining = seconds;
      _isTimerActive = true;
    });
    _runTimer();
  }

  void _runTimer() async {
    while (_restRemaining > 0 && _isTimerActive) {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      setState(() {
        _restRemaining--;
        if (_restRemaining <= 0) _isTimerActive = false;
      });
    }
  }

  Widget _buildTimerOverlay() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.timer, color: Colors.white),
            const SizedBox(width: 16),
            Text(
              'REST: $_restRemaining s',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() => _isTimerActive = false),
              child: const Text('SKIP', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVolumeBadge() {
    double total = 0;
    _logs.forEach((key, list) {
      for (var s in list) {
        total += s.weight * s.reps;
      }
    });
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '${total.toInt()} kg',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSetField(String hint, String label, Function(String) onChanged) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            child: TextField(
              textAlign: TextAlign.center,
              onChanged: onChanged,
              keyboardType: TextInputType.number,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                fillColor: Colors.transparent,
              ),
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.mutedTextColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativeRow(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.white.withOpacity(0.3),
            size: 20,
          ),
        ],
      ),
    );
  }

  Future<void> _saveLog() async {
    // Show session rating bottom sheet first
    final int? rating = await _showRatingSheet();
    if (!mounted) return;

    final List<ExerciseLog> exerciseLogs = [];
    for (int i = 0; i < widget.workoutDay.exercises.length; i++) {
      exerciseLogs.add(
        ExerciseLog(
          exerciseName: widget.workoutDay.exercises[i].name,
          sets: _logs[i]!,
          notes: _exerciseNotes[i],
          timestamp: DateTime.now(),
        ),
      );
    }

    final log = WorkoutLog(
      clientId: widget.clientId,
      programId: widget.programId,
      workoutDayId: widget.workoutDay.id ?? widget.workoutDay.muscleGroup,
      date: DateTime.now(),
      exerciseLogs: exerciseLogs,
      notes: _sessionNotesController.text,
      sessionRating: rating,
    );

    try {
      await _dbService.logWorkout(log);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout logged successfully!')),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error logging workout: $e')));
    }
  }

  Future<int?> _showRatingSheet() async {
    int? selected;
    return showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
              decoration: BoxDecoration(
                color: const Color(0xFF16213E),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border(
                  top: BorderSide(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                  ),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Icon(
                    Icons.emoji_events_rounded,
                    color: AppTheme.primaryColor,
                    size: 36,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'How was this session?',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rate out of 10 to track your performance trends',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(10, (i) {
                      final n = i + 1;
                      final isSelected = selected == n;
                      final Color chipColor = n <= 4
                          ? Colors.redAccent
                          : n <= 7
                          ? Colors.orangeAccent
                          : Colors.greenAccent;
                      return GestureDetector(
                        onTap: () => setModalState(() => selected = n),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isSelected ? 34 : 28,
                          height: isSelected ? 34 : 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? chipColor
                                : Colors.white.withOpacity(0.08),
                            border: Border.all(
                              color: isSelected ? chipColor : Colors.white12,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$n',
                              style: TextStyle(
                                fontSize: isSelected ? 13 : 11,
                                fontWeight: FontWeight.bold,
                                color: isSelected
                                    ? Colors.black
                                    : Colors.white60,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white54,
                            side: const BorderSide(color: Colors.white12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            minimumSize: const Size(0, 48),
                          ),
                          child: const Text('SKIP'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: selected != null
                              ? () => Navigator.pop(ctx, selected)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            disabledBackgroundColor: AppTheme.primaryColor
                                .withOpacity(0.3),
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            selected != null
                                ? 'SUBMIT $selected/10'
                                : 'SELECT RATING',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
