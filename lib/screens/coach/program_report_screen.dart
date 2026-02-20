import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ptapp/models/program_model.dart';
import 'package:ptapp/models/user_model.dart';
import 'package:ptapp/models/log_model.dart';
import 'package:ptapp/services/database_service.dart';
import 'package:ptapp/utils/theme.dart';

class ProgramReportScreen extends StatefulWidget {
  final Program program;
  final AppUser client;

  const ProgramReportScreen({
    super.key,
    required this.program,
    required this.client,
  });

  @override
  State<ProgramReportScreen> createState() => _ProgramReportScreenState();
}

class _ProgramReportScreenState extends State<ProgramReportScreen> {
  final _dbService = DatabaseService();
  late Stream<List<WorkoutDay>> _daysStream;
  final Map<String, Stream<List<ExerciseLog>>> _logsStreams = {};
  final Map<String, Stream<WorkoutLog?>> _workoutLogStreams = {};

  @override
  void initState() {
    super.initState();
    _daysStream = _dbService.getProgramDays(widget.program.id!);
  }

  Stream<List<ExerciseLog>> _getLogsStream(String dayId) {
    return _logsStreams.putIfAbsent(
      dayId,
      () => _dbService.getExerciseLogs(widget.program.id!, dayId),
    );
  }

  Stream<WorkoutLog?> _getWorkoutLogStream(String dayId) {
    return _workoutLogStreams.putIfAbsent(
      dayId,
      () => _dbService.getWorkoutLogForDay(widget.program.id!, dayId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.program.name} Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgramSummary(),
            const SizedBox(height: 24),
            Text(
              'Daily Progress'.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<List<WorkoutDay>>(
              stream: _daysStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final allDays = snapshot.data ?? [];
                final days = allDays
                    .where((d) => d.week <= widget.program.totalWeeks)
                    .toList();
                if (days.isEmpty)
                  return const Text(
                    'No workout data found.',
                    style: TextStyle(color: AppTheme.mutedTextColor),
                  );

                return Column(
                  children: days
                      .map((day) => _buildDayReportItem(context, day))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.client.name.toUpperCase(),
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.program.status == ProgramStatus.active
                      ? AppTheme.primaryColor.withOpacity(0.2)
                      : Colors.white10,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.program.status.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: widget.program.status == ProgramStatus.active
                        ? AppTheme.primaryColor
                        : Colors.white60,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.program.name,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.program.totalWeeks} Weeks Duration',
            style: const TextStyle(color: AppTheme.mutedTextColor),
          ),
          if (widget.program.coachNotes != null &&
              widget.program.coachNotes!.isNotEmpty) ...[
            const Divider(color: Colors.white10, height: 32),
            const Text(
              'COACH NOTES',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.mutedTextColor,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.program.coachNotes!,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDayReportItem(BuildContext context, WorkoutDay day) {
    return StreamBuilder<List<ExerciseLog>>(
      stream: _getLogsStream(day.id!),
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];
        final totalEx = day.exercises.length;
        final completedEx = logs
            .where((l) => l.status == ExerciseStatus.completed)
            .length;
        final skippedEx = logs
            .where((l) => l.status == ExerciseStatus.skipped)
            .length;

        final totalVolume = logs.fold(
          0.0,
          (sum, ex) =>
              sum + ex.sets.fold(0.0, (sSum, s) => sSum + (s.weight * s.reps)),
        );
        final DateTime? sessionStart = logs.isNotEmpty
            ? logs.first.sessionStartTime
            : null;

        bool isFuture =
            (day.week > widget.program.currentWeek) ||
            (day.week == widget.program.currentWeek &&
                day.day > widget.program.currentDay);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: _buildStatusIcon(logs, totalEx, isFuture),
              title: Text(
                'W${day.week} D${day.day}: ${day.muscleGroup}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              subtitle: Text(
                sessionStart != null
                    ? 'Completed: ${DateFormat('MMM d').format(sessionStart)} • ${totalVolume.toInt()}kg Volume'
                    : (isFuture ? 'Future Session' : 'Not started yet'),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.mutedTextColor,
                ),
              ),
              children: [
                const Divider(color: Colors.white10, height: 1),
                StreamBuilder<WorkoutLog?>(
                  stream: _getWorkoutLogStream(day.id ?? day.muscleGroup),
                  builder: (context, logSnapshot) {
                    final workoutLog = logSnapshot.data;
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSummaryStat(
                                'COMPLETED',
                                '$completedEx/$totalEx',
                              ),
                              _buildSummaryStat('SKIPPED', '$skippedEx'),
                              _buildSummaryStat(
                                'VOLUME',
                                '${totalVolume.toInt()} kg',
                              ),
                            ],
                          ),
                          if (workoutLog?.sessionRating != null ||
                              (workoutLog?.feedback != null &&
                                  workoutLog!.feedback!.isNotEmpty) ||
                              (workoutLog?.notes != null &&
                                  workoutLog!.notes!.isNotEmpty)) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppTheme.primaryColor.withOpacity(0.2),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.amber,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Client Rating: ${workoutLog?.sessionRating ?? "-"}/10',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (workoutLog?.notes != null &&
                                      workoutLog!.notes!.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      'Client Notes:\n${workoutLog.notes!}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                  if (workoutLog?.feedback != null &&
                                      workoutLog!.feedback!.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Text(
                                      'Your Feedback:\n${workoutLog.feedback!}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          ...day.exercises.map((ex) {
                            final log = logs.firstWhere(
                              (l) => l.exerciseName == ex.name,
                              orElse: () => ExerciseLog(
                                exerciseName: ex.name,
                                sets: [],
                                timestamp: DateTime.now(),
                                status: ExerciseStatus.notStarted,
                              ),
                            );
                            return _buildExerciseLogDetail(ex, log);
                          }).toList(),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon(List<ExerciseLog> logs, int totalEx, bool isFuture) {
    if (logs.isEmpty) {
      return Icon(
        isFuture ? Icons.lock_outline : Icons.radio_button_unchecked,
        color: Colors.white24,
        size: 20,
      );
    }
    final completed = logs
        .where((l) => l.status == ExerciseStatus.completed)
        .length;
    if (completed == totalEx) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 22);
    } else if (completed > 0 ||
        logs.any((l) => l.status == ExerciseStatus.skipped)) {
      return const Icon(
        Icons.pending_actions,
        color: AppTheme.primaryColor,
        size: 22,
      );
    }
    return const Icon(
      Icons.radio_button_unchecked,
      color: Colors.white24,
      size: 20,
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: AppTheme.mutedTextColor,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseLogDetail(dynamic ex, ExerciseLog log) {
    final bool isCompleted = log.status == ExerciseStatus.completed;
    final bool isSkipped = log.status == ExerciseStatus.skipped;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                ex.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              if (isCompleted)
                const Icon(Icons.check, color: Colors.green, size: 14)
              else if (isSkipped)
                const Text(
                  'SKIPPED',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else
                const Text(
                  'NOT DONE',
                  style: TextStyle(color: Colors.white24, fontSize: 10),
                ),
            ],
          ),
          if (isCompleted && log.sets.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: log.sets.asMap().entries.map((entry) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'S${entry.key + 1}: ${entry.value.weight}kg x ${entry.value.reps}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
