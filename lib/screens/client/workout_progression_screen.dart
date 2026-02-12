
import 'package:flutter/material.dart';
import 'package:ptapp/models/program_model.dart';
import 'package:ptapp/services/database_service.dart';
import 'package:ptapp/utils/theme.dart';
import 'package:ptapp/screens/client/exercise_tracking_screen.dart';

class WorkoutProgressionScreen extends StatefulWidget {
  final Program program;
  const WorkoutProgressionScreen({super.key, required this.program});

  @override
  State<WorkoutProgressionScreen> createState() => _WorkoutProgressionScreenState();
}

class _WorkoutProgressionScreenState extends State<WorkoutProgressionScreen> {
  final _dbService = DatabaseService();
  late Stream<Program?> _programStream;
  late Stream<List<WorkoutDay>> _daysStream;

  @override
  void initState() {
    super.initState();
    _programStream = _dbService.getProgramStream(widget.program.id!);
    _daysStream = _dbService.getProgramDays(widget.program.id!);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Program?>(
      stream: _programStream,
      initialData: widget.program,
      builder: (context, progSnapshot) {
        final currentProg = progSnapshot.data ?? widget.program;
        final bool hasUnreadNotes = currentProg.coachNotes != null && 
            (currentProg.notesReadAt == null || (currentProg.notesUpdatedAt != null && currentProg.notesUpdatedAt!.isAfter(currentProg.notesReadAt!)));

        return Scaffold(
          appBar: AppBar(
            title: Text(currentProg.name.toUpperCase()),
            actions: [
              if (currentProg.coachNotes != null && currentProg.coachNotes!.isNotEmpty)
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.note_alt_outlined),
                      onPressed: () => _showCoachNotesDialog(context, currentProg, _dbService),
                    ),
                    if (hasUnreadNotes)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
          body: StreamBuilder<List<WorkoutDay>>(
            stream: _daysStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final allDays = snapshot.data ?? [];
              
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: currentProg.totalWeeks,
                itemBuilder: (context, weekIdx) {
                  final weekNum = weekIdx + 1;
                  final weekDays = allDays.where((d) => d.week == weekNum).toList();
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('WEEK $weekNum', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.mutedTextColor, letterSpacing: 1.2)),
                      ),
                      ...weekDays.map((day) => _buildDayTile(context, day, currentProg)),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              );
            },
          ),
        );
      }
    );
  }

  void _showCoachNotesDialog(BuildContext context, Program program, DatabaseService dbService) {
    // Mark as read when dialog is opened
    dbService.markProgramNotesAsRead(program.id!);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: Row(
          children: [
            const Icon(Icons.note_alt_outlined, color: AppTheme.primaryColor, size: 24),
            const SizedBox(width: 12),
            const Text('Coach Notes', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Text(
            program.coachNotes ?? '',
            style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.6),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CLOSE', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTile(BuildContext context, WorkoutDay day, Program program) {
    final bool isProgramCompleted = program.status == ProgramStatus.completed;
    final bool isUnlocked = isProgramCompleted || day.week < program.currentWeek || (day.week == program.currentWeek && day.day <= program.currentDay);
    final bool isCurrent = !isProgramCompleted && day.week == program.currentWeek && day.day == program.currentDay;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isCurrent ? AppTheme.primaryColor : Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: isUnlocked ? () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    ExerciseTrackingScreen(program: program, workoutDay: day))) : null,
        leading: Icon(
          isProgramCompleted ? Icons.check_circle : (isUnlocked ? Icons.fitness_center : Icons.lock_outline),
          color: isProgramCompleted ? Colors.green : (isUnlocked ? AppTheme.primaryColor : Colors.white24),
        ),
        title: Text('Day ${day.day}: ${day.muscleGroup}', style: TextStyle(color: isUnlocked ? Colors.white : Colors.white38, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
        trailing: isUnlocked 
          ? (isProgramCompleted
              ? const Icon(Icons.visibility_outlined, color: Colors.white54)
              : (isCurrent 
                  ? const Icon(Icons.play_circle_fill, color: AppTheme.primaryColor) 
                  : const Icon(Icons.check_circle, color: Colors.green)))
          : null,
      ),
    );
  }
}
