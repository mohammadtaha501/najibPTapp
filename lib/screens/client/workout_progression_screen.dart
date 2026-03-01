import 'dart:ui';
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
  int? _selectedWeek;

  @override
  void initState() {
    super.initState();
    _selectedWeek = widget.program.currentWeek;
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
          backgroundColor: AppTheme.getScaffoldColor(context),
          body: StreamBuilder<List<WorkoutDay>>(
            stream: _daysStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading program: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              final allDays = snapshot.data ?? [];
              if (allDays.isEmpty &&
                  snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final effectiveSelectedWeek =
                  _selectedWeek ?? currentProg.currentWeek;

              final currentDayObj = allDays.firstWhere(
                (d) =>
                    d.week == currentProg.currentWeek &&
                    d.day == currentProg.currentDay,
                orElse: () => allDays.isEmpty
                    ? WorkoutDay(
                        id: '',
                        week: 1,
                        day: 1,
                        muscleGroup: 'Rest Day',
                        exercises: [],
                      )
                    : allDays.first,
              );

              // Filter days for the selected week
              final weekDays =
                  allDays.where((d) => d.week == effectiveSelectedWeek).toList()
                    ..sort((a, b) => a.day.compareTo(b.day));

              final isViewingCurrentWeek =
                  effectiveSelectedWeek == currentProg.currentWeek;
              final isViewingPastWeek =
                  effectiveSelectedWeek < currentProg.currentWeek;
              final isViewingFutureWeek =
                  effectiveSelectedWeek > currentProg.currentWeek;

              // Calculate overall completed days for stats (independent of selected week)
              final completedDaysCount = allDays.where((d) {
                if (currentProg.status == ProgramStatus.completed) return true;
                return d.week < currentProg.currentWeek ||
                    (d.week == currentProg.currentWeek &&
                        d.day < currentProg.currentDay);
              }).length;

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // --- Immersive Sliver App Bar ---
                  SliverAppBar(
                    expandedHeight: 280.0,
                    pinned: true,
                    stretch: true,
                    backgroundColor: AppTheme.getScaffoldColor(context),
                    elevation: 0,
                    leading: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surface.withOpacity(0.4),
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
                        StretchMode.fadeTitle,
                      ],
                      centerTitle: false,
                      titlePadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      title: Text(
                        currentProg.name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                          fontSize: 22,
                          letterSpacing: -0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.35),
                              offset: const Offset(0, 2),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      background: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Background Image Overlay
                          Image.asset(
                            'assets/images/fitness_program_background.png',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppTheme.primaryColor.withOpacity(0.4),
                                        Theme.of(
                                          context,
                                        ).scaffoldBackgroundColor,
                                      ],
                                    ),
                                  ),
                                ),
                          ),
                          // Premium Gradient Overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                stops: const [0.0, 0.4, 0.7, 1.0],
                                colors: [
                                  Colors.black.withOpacity(0.4),
                                  Colors.transparent,
                                  Theme.of(
                                    context,
                                  ).scaffoldBackgroundColor.withOpacity(0.8),
                                  Theme.of(context).scaffoldBackgroundColor,
                                ],
                              ),
                            ),
                          ),
                          // Progress Indicators in Header
                          Positioned(
                            bottom: 80,
                            left: 20,
                            right: 20,
                            child: Row(
                              children: [
                                _buildHeaderStat(
                                  context,
                                  'WEEK',
                                  '${currentProg.currentWeek}/${currentProg.totalWeeks}',
                                  Icons.calendar_today_rounded,
                                ),
                                const SizedBox(width: 24),
                                _buildHeaderStat(
                                  context,
                                  'COMPLETED',
                                  '$completedDaysCount/${allDays.length}',
                                  Icons.check_circle_outline_rounded,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      if (currentProg.coachNotes != null &&
                          currentProg.coachNotes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: IconButton(
                            icon: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface.withOpacity(0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.chat_bubble_outline_rounded,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    size: 20,
                                  ),
                                ),
                                if (hasUnreadNotes)
                                  Positioned(
                                    right: 2,
                                    top: 2,
                                    child: Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: Colors.redAccent,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Theme.of(
                                            context,
                                          ).scaffoldBackgroundColor,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            onPressed: () => _showCoachNotesDialog(
                              context,
                              currentProg,
                              _dbService,
                            ),
                          ),
                        ),
                    ],
                  ),

                  // --- Week Selector ---
                  SliverToBoxAdapter(
                    child: _buildWeekSelector(
                      context,
                      currentProg.totalWeeks,
                      effectiveSelectedWeek,
                      currentProg.currentWeek,
                    ),
                  ),

                  // --- Content Sections ---
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isViewingCurrentWeek &&
                              currentProg.status !=
                                  ProgramStatus.completed) ...[
                            _buildSectionTitle(
                              context,
                              'MAIN FOCUS',
                              Icons.bolt_rounded,
                              AppTheme.primaryColor,
                            ),
                            const SizedBox(height: 16),
                            _buildCurrentDayHero(
                              context,
                              currentDayObj,
                              currentProg,
                            ),
                            const SizedBox(height: 32),
                          ],

                          // Week Days List
                          _buildSectionTitle(
                            context,
                            'WEEK $effectiveSelectedWeek SCHEDULE',
                            Icons.calendar_view_day_rounded,
                            isViewingPastWeek
                                ? Colors.greenAccent
                                : isViewingCurrentWeek
                                ? AppTheme.primaryColor
                                : Colors.blueAccent,
                          ),
                          const SizedBox(height: 16),
                          if (weekDays.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Text(
                                  'No workouts planned for this week.',
                                  style: TextStyle(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.3),
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: weekDays.length,
                              itemBuilder: (context, index) {
                                final day = weekDays[index];
                                final isDayCompleted =
                                    isViewingPastWeek ||
                                    (isViewingCurrentWeek &&
                                        day.day < currentProg.currentDay) ||
                                    (currentProg.status ==
                                        ProgramStatus.completed);

                                return _buildDayCard(
                                  context,
                                  day,
                                  currentProg,
                                  isCompleted: isDayCompleted,
                                  isUpcoming:
                                      !isDayCompleted &&
                                      (isViewingFutureWeek ||
                                          (isViewingCurrentWeek &&
                                              day.day >
                                                  currentProg.currentDay)),
                                );
                              },
                            ),
                          const SizedBox(height: 40),
                        ],
                      ),
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

  Widget _buildWeekSelector(
    BuildContext context,
    int totalWeeks,
    int selectedWeek,
    int currentWeek,
  ) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: totalWeeks,
        itemBuilder: (context, index) {
          final weekNum = index + 1;
          final isSelected = weekNum == selectedWeek;
          final isCurrent = weekNum == currentWeek;
          final isPast = weekNum < currentWeek;

          return GestureDetector(
            onTap: () => setState(() => _selectedWeek = weekNum),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : isCurrent
                      ? AppTheme.primaryColor.withOpacity(0.3)
                      : Theme.of(context).dividerColor.withOpacity(0.05),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'WEEK',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.black
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    weekNum.toString(),
                    style: TextStyle(
                      color: isSelected
                          ? Colors.black
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  if (isCurrent && !isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderStat(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color.withOpacity(0.8)),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Divider(
            color: Theme.of(context).dividerColor.withOpacity(0.05),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentDayHero(
    BuildContext context,
    WorkoutDay day,
    Program program,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ExerciseTrackingScreen(program: program, workoutDay: day),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'ACTIVE NOW',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    Text(
                      'Day ${day.day}',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.4),
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  day.muscleGroup,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.fitness_center_rounded,
                      size: 16,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.4),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${day.exercises.length} EXERCISES PLANNED',
                      style: TextStyle(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.4),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Text(
                      'START WORKOUT',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
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
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(28),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: AppTheme.primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Coach Notes',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  child: Text(
                    program.coachNotes ?? '',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
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
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'GOT IT',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
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

  Widget _buildDayCard(
    BuildContext context,
    WorkoutDay day,
    Program program, {
    bool isCompleted = false,
    bool isUpcoming = false,
  }) {
    final bool isProgramCompleted = program.status == ProgramStatus.completed;
    final bool isUnlocked =
        isProgramCompleted ||
        isCompleted ||
        (day.week <= program.currentWeek && day.day <= program.currentDay);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).cardTheme.color!.withOpacity(isUnlocked ? 1.0 : 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isUnlocked
              ? Theme.of(context).dividerColor.withOpacity(0.05)
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isUnlocked
              ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExerciseTrackingScreen(
                      program: program,
                      workoutDay: day,
                    ),
                  ),
                )
              : null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.greenAccent.withOpacity(0.1)
                        : isUnlocked
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      isCompleted
                          ? Icons.check_rounded
                          : isUnlocked
                          ? Icons.play_arrow_rounded
                          : Icons.lock_rounded,
                      color: isCompleted
                          ? Colors.greenAccent
                          : isUnlocked
                          ? AppTheme.primaryColor
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.2),
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Day ${day.day}',
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        day.muscleGroup,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface
                              .withOpacity(isUnlocked ? 1.0 : 0.3),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isCompleted)
                  Text(
                    'DONE',
                    style: TextStyle(
                      color: Colors.greenAccent.withOpacity(0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  )
                else if (isUnlocked)
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.1),
                    size: 14,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
