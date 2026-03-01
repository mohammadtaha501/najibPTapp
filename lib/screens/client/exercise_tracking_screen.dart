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
    final totalExercises = widget.workoutDay.exercises.length;
    int completedCount = 0;
    for (var ex in widget.workoutDay.exercises) {
      final log = _logs[ex.name];
      if (log != null &&
          (log.status == ExerciseStatus.completed ||
              log.status == ExerciseStatus.skipped)) {
        completedCount++;
      }
    }
    final double progress = totalExercises > 0
        ? completedCount / totalExercises
        : 0;

    return Scaffold(
      backgroundColor: AppTheme.getScaffoldColor(context),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- Immersive Header ---
          SliverAppBar(
            expandedHeight: 220.0,
            pinned: true,
            stretch: true,
            backgroundColor: AppTheme.getScaffoldColor(context),
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor.withOpacity(0.2),
                          AppTheme.getScaffoldColor(context),
                        ],
                      ),
                    ),
                  ),
                  // Progress Content
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DAY ${widget.workoutDay.day}',
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.workoutDay.muscleGroup.toUpperCase(),
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.05),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        AppTheme.primaryColor,
                                      ),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
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
          ),

          // --- Exercise List ---
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final ex = widget.workoutDay.exercises[index];
                final log = _logs[ex.name];
                return _buildExerciseCard(ex, log);
              }, childCount: widget.workoutDay.exercises.length),
            ),
          ),
        ],
      ),
      // --- Floating Finish Button ---
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton:
          (progress >= 1.0 && widget.program.status != ProgramStatus.completed)
          ? Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _confirmFinishWorkout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.black,
                  elevation: 8,
                  shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'FINISH WORKOUT',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  void _confirmFinishWorkout() {
    final notesController = TextEditingController();
    double currentRating = 8.0;
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            final bool isDark = Theme.of(context).brightness == Brightness.dark;
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
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
                        vertical: 32,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(28),
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.emoji_events_rounded,
                              color: Colors.black,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Workout Complete!',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 24,
                              color: Theme.of(context).colorScheme.onSurface,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'UNBELIEVABLE EFFORT TODAY.',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.4),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Rating Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'SESSION INTENSITY',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 11,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.4),
                                  letterSpacing: 1,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getRatingColor(
                                    currentRating,
                                  ).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${currentRating.toInt()}/10',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: _getRatingColor(currentRating),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: _getRatingColor(currentRating),
                              inactiveTrackColor: Theme.of(
                                context,
                              ).dividerColor.withOpacity(0.1),
                              thumbColor: isDark
                                  ? Colors.white
                                  : AppTheme.primaryColor,
                              overlayColor: _getRatingColor(
                                currentRating,
                              ).withOpacity(0.2),
                              trackHeight: 8,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 12,
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

                          const SizedBox(height: 32),

                          // Notes Section
                          Text(
                            'COACH RECAP',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.4),
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: notesController,
                            maxLines: 2,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Any pain or PRs?',
                              hintStyle: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.2),
                                fontSize: 14,
                              ),
                              filled: true,
                              fillColor: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.03),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: TextButton(
                                  onPressed: isSubmitting
                                      ? null
                                      : () => Navigator.pop(context),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 20,
                                    ),
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.4),
                                  ),
                                  child: const Text(
                                    'REVIEW',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
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
                                      vertical: 20,
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
                                          'COMPLETE',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 14,
                                            letterSpacing: 1,
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

    final dbService = DatabaseService();
    // Re-verify program assignment
    if (widget.program.assignedClientId == null) {
      if (mounted) {
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (isCompleted || isSkipped)
              ? (isCompleted ? Colors.greenAccent : Colors.redAccent)
                    .withOpacity(0.2)
              : Theme.of(context).dividerColor.withOpacity(0.05),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Exercise Status Avatar
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.greenAccent.withOpacity(0.12)
                        : isSkipped
                        ? Colors.redAccent.withOpacity(0.12)
                        : AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isCompleted
                          ? Icons.check_rounded
                          : isSkipped
                          ? Icons.close_rounded
                          : Icons.fitness_center_rounded,
                      color: isCompleted
                          ? Colors.greenAccent
                          : isSkipped
                          ? Colors.redAccent
                          : AppTheme.primaryColor,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                // Exercise Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ex.name.toUpperCase(),
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.04),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${ex.sets} SETS × ${ex.reps} REPS',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          if (ex.restTime != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              '${ex.restTime}s REST',
                              style: TextStyle(
                                color: AppTheme.primaryColor.withOpacity(0.6),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // End Action / Lock
                if (isProgramCompleted)
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 18,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.2),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.15),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
