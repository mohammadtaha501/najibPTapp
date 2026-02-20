import 'package:flutter/material.dart';
import 'package:ptapp/models/program_model.dart';
import 'package:ptapp/services/database_service.dart';
import 'package:ptapp/utils/theme.dart';
import 'package:ptapp/screens/client/exercise_tracking_screen.dart';

class WorkoutProgressionScreen extends StatefulWidget {
  final Program program;
  const WorkoutProgressionScreen({super.key, required this.program});

  @override
  State<WorkoutProgressionScreen> createState() =>
      _WorkoutProgressionScreenState();
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
        final bool hasUnreadNotes =
            currentProg.coachNotes != null &&
            (currentProg.notesReadAt == null ||
                (currentProg.notesUpdatedAt != null &&
                    currentProg.notesUpdatedAt!.isAfter(
                      currentProg.notesReadAt!,
                    )));

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: StreamBuilder<List<WorkoutDay>>(
            stream: _daysStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final allDays = snapshot.data ?? [];

              return CustomScrollView(
                slivers: [
                  // Premium Sliver App Bar
                  SliverAppBar(
                    expandedHeight: 180.0,
                    pinned: true,
                    backgroundColor: AppTheme.surfaceColor,
                    elevation: 0,
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
                      title: Text(
                        currentProg.name.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                          letterSpacing: 1,
                        ),
                      ),
                      background: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppTheme.primaryColor.withOpacity(0.2),
                              AppTheme.surfaceColor,
                            ],
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 32, top: 40),
                            child: Icon(
                              Icons.fitness_center,
                              size: 100,
                              color: Colors.white.withOpacity(0.05),
                            ),
                          ),
                        ),
                      ),
                    ),
                    actions: [
                      if (currentProg.coachNotes != null &&
                          currentProg.coachNotes!.isNotEmpty)
                        Stack(
                          clipBehavior: Clip.none,
                          alignment: Alignment.center,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.note_alt_outlined,
                                  color: AppTheme.primaryColor,
                                ),
                                onPressed: () => _showCoachNotesDialog(
                                  context,
                                  currentProg,
                                  _dbService,
                                ),
                              ),
                            ),
                            if (hasUnreadNotes)
                              Positioned(
                                right: 16,
                                top: 12,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.surfaceColor,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),

                  // Weeks and Days List
                  SliverPadding(
                    padding: const EdgeInsets.all(20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, weekIdx) {
                        final weekNum = weekIdx + 1;
                        final weekDays = allDays
                            .where((d) => d.week == weekNum)
                            .toList();

                        if (weekDays.isEmpty) return const SizedBox.shrink();

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildWeekHeader(weekNum),
                            const SizedBox(height: 16),
                            ...weekDays.map(
                              (day) => _buildDayCard(context, day, currentProg),
                            ),
                            const SizedBox(height: 32),
                          ],
                        );
                      }, childCount: currentProg.totalWeeks),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildWeekHeader(int weekNum) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
          ),
          child: Text(
            'WEEK $weekNum',
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w900,
              fontSize: 14,
              letterSpacing: 1.5,
            ),
          ),
        ),
        const Expanded(
          child: Divider(color: Colors.white10, indent: 16, thickness: 1),
        ),
      ],
    );
  }

  void _showCoachNotesDialog(
    BuildContext context,
    Program program,
    DatabaseService dbService,
  ) {
    // Mark as read when dialog is opened
    dbService.markProgramNotesAsRead(program.id!);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.note_alt_rounded,
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    'Coach Notes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    program.coachNotes ?? '',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'CLOSE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard(BuildContext context, WorkoutDay day, Program program) {
    final bool isProgramCompleted = program.status == ProgramStatus.completed;
    final bool isUnlocked =
        isProgramCompleted ||
        day.week < program.currentWeek ||
        (day.week == program.currentWeek && day.day <= program.currentDay);
    final bool isCurrent =
        !isProgramCompleted &&
        day.week == program.currentWeek &&
        day.day == program.currentDay;

    return GestureDetector(
      onTap: isUnlocked
          ? () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ExerciseTrackingScreen(program: program, workoutDay: day),
              ),
            )
          : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isCurrent
              ? AppTheme.primaryColor.withOpacity(0.05)
              : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCurrent
                ? AppTheme.primaryColor.withOpacity(0.5)
                : Colors.white.withOpacity(0.05),
            width: isCurrent ? 1.5 : 1,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Status Icon Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isProgramCompleted
                    ? Colors.green.withOpacity(0.1)
                    : isUnlocked
                    ? AppTheme.primaryColor.withOpacity(0.1)
                    : Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isProgramCompleted
                    ? Icons.check_circle_rounded
                    : isCurrent
                    ? Icons.play_arrow_rounded
                    : isUnlocked
                    ? Icons.check_rounded
                    : Icons.lock_rounded,
                color: isProgramCompleted
                    ? Colors.green
                    : isUnlocked
                    ? AppTheme.primaryColor
                    : Colors.white38,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            // Title & Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Day ${day.day}',
                    style: TextStyle(
                      color: isUnlocked
                          ? AppTheme.mutedTextColor
                          : Colors.white24,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    day.muscleGroup,
                    style: TextStyle(
                      color: isUnlocked ? Colors.white : Colors.white38,
                      fontSize: 18,
                      fontWeight: isCurrent ? FontWeight.w900 : FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // Action Icon
            if (isUnlocked)
              Icon(
                isProgramCompleted
                    ? Icons.visibility_outlined
                    : isCurrent
                    ? Icons.arrow_forward_ios_rounded
                    : Icons.check_circle_rounded,
                color: isProgramCompleted
                    ? Colors.white54
                    : isCurrent
                    ? AppTheme.primaryColor
                    : Colors.green,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}
