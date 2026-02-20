import 'package:flutter/material.dart';
import 'package:ptapp/models/program_model.dart';
import 'package:ptapp/models/log_model.dart';
import 'package:ptapp/utils/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ptapp/screens/client/exercise_detail_logging_screen.dart';
import 'package:ptapp/services/database_service.dart';

class ExerciseTrackingScreen extends StatefulWidget {
  final Program program;
  final WorkoutDay workoutDay;
  const ExerciseTrackingScreen({
    super.key,
    required this.program,
    required this.workoutDay,
  });

  @override
  State<ExerciseTrackingScreen> createState() => _ExerciseTrackingScreenState();
}

class _ExerciseTrackingScreenState extends State<ExerciseTrackingScreen> {
  final Map<String, ExerciseLog> _logs = {};
  bool _isLoading = false;
  late DateTime _sessionStartTime;
  bool _hasAutoPrompted = false;

  @override
  void initState() {
    super.initState();
    _sessionStartTime = DateTime.now();
    _loadExistingLogs();
  }

  void _loadExistingLogs() {
    FirebaseFirestore.instance
        .collection('programs')
        .doc(widget.program.id)
        .collection('days')
        .doc(widget.workoutDay.id)
        .collection('exercise_logs')
        .snapshots()
        .listen((snapshot) {
          if (mounted) {
            setState(() {
              for (var doc in snapshot.docs) {
                _logs[doc.id] = ExerciseLog.fromMap(doc.data());
              }

              // Call outside the setState so we don't interfere with the widget build
            });
            if (ModalRoute.of(context)?.isCurrent == true) {
              _checkAutoPrompt();
            }
          }
        });
  }

  void _checkAutoPrompt() {
    // If the program is completed, or the day is in the past (already completed and moved on)
    final isDayInPast =
        widget.program.currentWeek > widget.workoutDay.week ||
        (widget.program.currentWeek == widget.workoutDay.week &&
            widget.program.currentDay > widget.workoutDay.day);

    if (_hasAutoPrompted ||
        widget.program.status == ProgramStatus.completed ||
        isDayInPast) {
      return;
    }

    final totalExercises = widget.workoutDay.exercises.length;
    if (totalExercises == 0) return;

    int completedCount = 0;
    for (var ex in widget.workoutDay.exercises) {
      final log = _logs[ex.name];
      if (log != null &&
          (log.status == ExerciseStatus.completed ||
              log.status == ExerciseStatus.skipped)) {
        completedCount++;
      }
    }

    if (completedCount == totalExercises) {
      _hasAutoPrompted = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _confirmFinishWorkout();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Day ${widget.workoutDay.day}: ${widget.workoutDay.muscleGroup}',
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...widget.workoutDay.exercises.map((ex) {
                final log = _logs[ex.name];
                return _buildExerciseCard(ex, log);
              }),
              const SizedBox(height: 32),
              // Manual Finish Button (in case they cancelled the auto-prompt)
              // if (widget.program.status != ProgramStatus.completed)
              //   SizedBox(
              //     width: double.infinity,
              //     child: ElevatedButton(
              //       onPressed: _confirmFinishWorkout,
              //       style: ElevatedButton.styleFrom(
              //         backgroundColor: AppTheme.primaryColor,
              //         foregroundColor: Colors.black,
              //         padding: const EdgeInsets.symmetric(vertical: 16),
              //         shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(16),
              //         ),
              //         elevation: 0,
              //       ),
              //       child: const Text(
              //         'FINISH WORKOUT',
              //         style: TextStyle(
              //           fontWeight: FontWeight.bold,
              //           fontSize: 16,
              //           letterSpacing: 0.5,
              //         ),
              //       ),
              //     ),
              //   ),
              const SizedBox(height: 32),
            ],
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  void _confirmFinishWorkout() {
    final notesController = TextEditingController();
    double currentRating = 8.0;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent tap outside
      builder: (context) => PopScope(
        canPop: false, // Prevent back button
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2C), // Dark surface
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.emoji_events,
                              color: Colors.black,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Workout Complete!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Great job today.',
                                  style: TextStyle(
                                    color: AppTheme.mutedTextColor,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Rating Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'SESSION RATING',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: AppTheme.mutedTextColor,
                                  letterSpacing: 1,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRatingColor(
                                    currentRating,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _getRatingColor(
                                      currentRating,
                                    ).withOpacity(0.5),
                                  ),
                                ),
                                child: Text(
                                  '${currentRating.toInt()}/10',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: _getRatingColor(currentRating),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: _getRatingColor(currentRating),
                              inactiveTrackColor: Colors.white10,
                              thumbColor: Colors.white,
                              overlayColor: _getRatingColor(
                                currentRating,
                              ).withOpacity(0.2),
                              trackHeight: 6,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 10,
                              ),
                            ),
                            child: Slider(
                              value: currentRating,
                              min: 1,
                              max: 10,
                              divisions: 9,
                              onChanged: (val) =>
                                  setDialogState(() => currentRating = val),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text(
                                'Light',
                                style: TextStyle(
                                  color: Colors.white24,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                'Moderate',
                                style: TextStyle(
                                  color: Colors.white24,
                                  fontSize: 10,
                                ),
                              ),
                              Text(
                                'Max Effort',
                                style: TextStyle(
                                  color: Colors.white24,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Notes Section
                          const Text(
                            'ADDITIONAL NOTES',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: AppTheme.mutedTextColor,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: notesController,
                            maxLines: 3,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'How did it feel? (Optional)',
                              hintStyle: TextStyle(
                                color: Colors.white.withOpacity(0.3),
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: Colors.black26,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: isSubmitting
                                      ? null
                                      : () => Navigator.pop(
                                          context,
                                        ), // Allows checking logs
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    foregroundColor: AppTheme.mutedTextColor,
                                  ),
                                  child: const Text('Review Logs'),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton(
                                  onPressed: isSubmitting
                                      ? null
                                      : () async {
                                          setDialogState(
                                            () => isSubmitting = true,
                                          );
                                          await _finishWorkout(
                                            notesController.text,
                                            currentRating.toInt(),
                                            fromDialog: true,
                                          );
                                          if (mounted) {
                                            setDialogState(
                                              () => isSubmitting = false,
                                            );
                                          }
                                        },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryColor,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: isSubmitting
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.black,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text(
                                          'SAVE & CLOSE',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Color _getRatingColor(double rating) {
    if (rating <= 4) return Colors.redAccent;
    if (rating <= 7) return Colors.orangeAccent;
    return Colors.greenAccent;
  }

  Future<void> _finishWorkout(
    String notes,
    int rating, {
    bool fromDialog = false,
  }) async {
    // If NOT called from dialog (i.e. manual button), show screen loading.
    // If called from dialog, the dialog handles its own loading state.
    if (!fromDialog) {
      setState(() => _isLoading = true);
    }

    final dbService = DatabaseService();
    // Re-verify program assignment
    if (widget.program.assignedClientId == null) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error: No client assigned to this program.'),
          ),
        );
      }
      return;
    }

    final log = WorkoutLog(
      clientId: widget.program.assignedClientId!,
      programId: widget.program.id!,
      workoutDayId: widget.workoutDay.id ?? widget.workoutDay.muscleGroup,
      date: DateTime.now(),
      exerciseLogs: _logs.values.toList(),
      notes: notes,
      sessionRating: rating,
    );

    try {
      await dbService.logWorkout(log);
      if (mounted) {
        Navigator.pop(context); // Go back to progression screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Workout logged successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        // If from dialog, we just stop the dialog loading (handled by caller's await)
        // If normal screen, we stop screen loading
        if (!fromDialog) {
          setState(() => _isLoading = false);
        }

        // Show error regardless
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error logging workout: $e')));

        // If from dialog, we probably want to Close the dialog if error?
        // Or keep it open to retry? Keep it open is better UX.
        // The dialog's `isSubmitting` will be set to false by the caller.
      }
    }
  }

  Widget _buildExerciseCard(dynamic ex, ExerciseLog? log) {
    final bool isCompleted = log?.status == ExerciseStatus.completed;
    final bool isSkipped = log?.status == ExerciseStatus.skipped;
    final bool isProgramCompleted =
        widget.program.status == ProgramStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (isCompleted || isSkipped)
              ? Colors.green.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: isProgramCompleted
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExerciseDetailLoggingScreen(
                      program: widget.program,
                      workoutDay: widget.workoutDay,
                      exercise: ex,
                      existingLog: log,
                      sessionStartTime: _sessionStartTime,
                    ),
                  ),
                ).then((_) {
                  if (mounted && ModalRoute.of(context)?.isCurrent == true) {
                    _checkAutoPrompt();
                  }
                });
              },
        title: Text(
          ex.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${ex.sets} Sets x ${ex.reps} Reps',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (ex.tempo != null && ex.tempo!.isNotEmpty)
              Text(
                'Tempo: ${ex.tempo}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.mutedTextColor,
                ),
              ),
            if (isProgramCompleted)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 14,
                      color: AppTheme.mutedTextColor.withOpacity(0.6),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'View Only',
                      style: TextStyle(
                        color: AppTheme.mutedTextColor.withOpacity(0.6),
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        trailing: isProgramCompleted
            ? const Icon(Icons.visibility_outlined, color: Colors.white24)
            : (isCompleted
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : (isSkipped
                        ? const Icon(
                            Icons.block,
                            color: Colors.redAccent,
                            size: 20,
                          )
                        : const Icon(
                            Icons.chevron_right,
                            color: Colors.white24,
                          ))),
      ),
    );
  }
}
