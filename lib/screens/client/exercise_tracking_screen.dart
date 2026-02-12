import 'package:flutter/material.dart';
import 'package:untitled3/models/program_model.dart';
import 'package:untitled3/models/log_model.dart';
import 'package:untitled3/utils/theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled3/screens/client/exercise_detail_logging_screen.dart';

import '../../services/database_service.dart';

class ExerciseTrackingScreen extends StatefulWidget {
  final Program program;
  final WorkoutDay workoutDay;
  const ExerciseTrackingScreen({super.key, required this.program, required this.workoutDay});

  @override
  State<ExerciseTrackingScreen> createState() => _ExerciseTrackingScreenState();
}

class _ExerciseTrackingScreenState extends State<ExerciseTrackingScreen> {
  final Map<String, ExerciseLog> _logs = {};
  bool _isLoading = false;
  late DateTime _sessionStartTime;

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
           });
        }
      });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Day ${widget.workoutDay.day}: ${widget.workoutDay.muscleGroup}'),
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
            ],
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  void _confirmFinishWorkout() {
    final notesController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Finish Workout?', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Great job! Add any notes for your coach:', style: TextStyle(color: AppTheme.mutedTextColor)),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. Squats felt heavy today...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                filled: true,
                fillColor: Colors.black12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.mutedTextColor)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _finishWorkout(notesController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.black,
            ),
            child: const Text('FINISH', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _finishWorkout(String notes) async {
    setState(() => _isLoading = true);
    
    final dbService = DatabaseService(); 
    final log = WorkoutLog(
      clientId: widget.program.assignedClientId!,
      programId: widget.program.id!,
      workoutDayId: widget.workoutDay.id ?? widget.workoutDay.muscleGroup,
      date: DateTime.now(),
      exerciseLogs: _logs.values.toList(),
      notes: notes,
    );

    try {
      await dbService.logWorkout(log);
      if (mounted) {
        Navigator.pop(context); // Go back to progression screen
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Workout logged successfully!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error logging workout: $e')));
      }
    }
  }

  Widget _buildExerciseCard(dynamic ex, ExerciseLog? log) {
    final bool isCompleted = log?.status == ExerciseStatus.completed;
    final bool isSkipped = log?.status == ExerciseStatus.skipped;
    final bool isProgramCompleted = widget.program.status == ProgramStatus.completed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isCompleted || isSkipped) ? Colors.green.withOpacity(0.3) : Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        onTap: isProgramCompleted ? null : () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => ExerciseDetailLoggingScreen(
            program: widget.program,
            workoutDay: widget.workoutDay,
            exercise: ex,
            existingLog: log,
            sessionStartTime: _sessionStartTime,
          )));
        },
        title: Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('${ex.sets} Sets x ${ex.reps} Reps', style: const TextStyle(color: AppTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.w600)),
            if (ex.tempo != null && ex.tempo!.isNotEmpty)
              Text('Tempo: ${ex.tempo}', style: const TextStyle(fontSize: 12, color: AppTheme.mutedTextColor)),
            if (isProgramCompleted)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, size: 14, color: AppTheme.mutedTextColor.withOpacity(0.6)),
                    const SizedBox(width: 6),
                    Text(
                      'View Only',
                      style: TextStyle(color: AppTheme.mutedTextColor.withOpacity(0.6), fontSize: 11, fontStyle: FontStyle.italic),
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
              : (isSkipped ? const Icon(Icons.block, color: Colors.redAccent, size: 20) : const Icon(Icons.chevron_right, color: Colors.white24))),
      ),
    );
  }
}
