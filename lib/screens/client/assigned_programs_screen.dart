import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ptapp/models/program_model.dart';
import 'package:ptapp/services/database_service.dart';
import 'package:ptapp/utils/theme.dart';
import 'package:ptapp/screens/client/workout_progression_screen.dart';
import 'package:provider/provider.dart';
import 'package:ptapp/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class AssignedProgramsScreen extends StatefulWidget {
  const AssignedProgramsScreen({super.key});

  @override
  State<AssignedProgramsScreen> createState() => _AssignedProgramsScreenState();
}

class _AssignedProgramsScreenState extends State<AssignedProgramsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Stream<List<Program>> _inProgressStream;
  late Stream<List<Program>> _newPlansUnfilteredStream;
  late Stream<List<Program>> _publicProgramsStream;
  final _dbService = DatabaseService();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  String? _lastUserId;
  String? _lastCoachId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<AuthProvider>(context).userProfile;

    if (user == null) {
      if (_lastUserId != null) {
        _inProgressStream = Stream.value([]);
        _newPlansUnfilteredStream = Stream.value([]);
        _publicProgramsStream = Stream.value([]);
        _lastUserId = null;
        _lastCoachId = null;
      }
      return;
    }

    final currentCoachId = user.coachId ?? '';

    if (user.uid != _lastUserId || currentCoachId != _lastCoachId) {
      _inProgressStream = _dbService.getClientPrograms(user.uid);
      _newPlansUnfilteredStream = _dbService.getClientPrograms(user.uid);

      _publicProgramsStream = _dbService
          .getPublicPrograms(currentCoachId)
          .handleError((error) {
            debugPrint('[AssignedPrograms] getPublicPrograms error: $error');
          })
          .timeout(
            const Duration(seconds: 15),
            onTimeout: (sink) => sink.add([]),
          );

      _lastUserId = user.uid;
      _lastCoachId = currentCoachId;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).userProfile;
    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final dbService = _dbService;

    return Scaffold(
      backgroundColor: AppTheme.getScaffoldColor(context),
      body: SafeArea(
        child: Column(
          children: [
            // --- Premium Header ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MY TRAINING',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Programs',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Theme.of(context).dividerColor.withOpacity(0.05),
                      ),
                    ),
                    child: Icon(
                      Icons.fitness_center_rounded,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ),

            // --- Modern Tab Toggle ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                height: 52,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.05),
                  ),
                ),
                child: AnimatedBuilder(
                  animation: _tabController,
                  builder: (context, _) => Row(
                    children: [
                      _buildToggleButton(0, 'ACTIVE'),
                      _buildToggleButton(1, 'NEW PLANS'),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // --- Content ---
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildProgramList(
                    dbService,
                    user,
                    stream: _inProgressStream,
                    filter: (p) => p.status == ProgramStatus.active,
                    emptyMessage: 'No active programs yet.',
                    buttonLabel: "CONTINUE WORKOUT",
                  ),
                  _buildNewPlansTab(dbService, user),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewPlansTab(DatabaseService dbService, dynamic user) {
    return StreamBuilder<List<Program>>(
      stream: _newPlansUnfilteredStream,
      builder: (context, personalSnapshot) {
        return StreamBuilder<List<Program>>(
          stream: _publicProgramsStream,
          builder: (context, publicSnapshot) {
            if ((personalSnapshot.connectionState == ConnectionState.waiting &&
                    !personalSnapshot.hasData) ||
                (publicSnapshot.connectionState == ConnectionState.waiting &&
                    !publicSnapshot.hasData)) {
              return const Center(child: CircularProgressIndicator());
            }

            final personal = personalSnapshot.data ?? [];
            final public = publicSnapshot.data ?? [];
            final unstartedPersonal = personal
                .where((p) => p.status == ProgramStatus.assigned)
                .toList();

            final claimingActiveOrAssignedIds = personal
                .where(
                  (p) =>
                      p.parentProgramId != null &&
                      (p.status == ProgramStatus.active ||
                          p.status == ProgramStatus.assigned),
                )
                .map((p) => p.parentProgramId!)
                .toSet();

            final availablePublic = public
                .where((p) => !claimingActiveOrAssignedIds.contains(p.id))
                .toList();
            final allNewPlans = [...unstartedPersonal, ...availablePublic];

            if (allNewPlans.isEmpty) {
              return const _EmptyPlaceholder(
                message: 'Ready for a new routine? Check back later.',
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              itemCount: allNewPlans.length,
              itemBuilder: (context, index) {
                final program = allNewPlans[index];
                final bool fromPublicList = availablePublic.contains(program);
                return _buildProgramCard(
                  context,
                  program,
                  dbService,
                  isPublic: fromPublicList,
                  buttonLabel: "START PROGRAM",
                  isGeneralLabel: fromPublicList,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildToggleButton(int index, String label) {
    final isSelected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabController.animateTo(index)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.black
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              fontWeight: FontWeight.w900,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgramList(
    DatabaseService dbService,
    dynamic user, {
    required Stream<List<Program>> stream,
    required bool Function(Program) filter,
    required String emptyMessage,
    required String buttonLabel,
  }) {
    return StreamBuilder<List<Program>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _EmptyPlaceholder(message: emptyMessage);
        }

        final filtered = (snapshot.data ?? []).where(filter).toList();

        if (filtered.isEmpty) {
          return _EmptyPlaceholder(message: emptyMessage);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return _buildProgramCard(
              context,
              filtered[index],
              dbService,
              isPublic: false,
              buttonLabel: buttonLabel,
            );
          },
        );
      },
    );
  }

  Widget _buildProgramCard(
    BuildContext context,
    Program program,
    DatabaseService dbService, {
    required bool isPublic,
    required String buttonLabel,
    bool isGeneralLabel = false,
  }) {
    final user = Provider.of<AuthProvider>(context, listen: false).userProfile!;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.05),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutProgressionScreen(program: program),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                (isGeneralLabel
                                        ? Colors.blueAccent
                                        : AppTheme.primaryColor)
                                    .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isPublic
                                ? Icons.explore_rounded
                                : Icons.bolt_rounded,
                            color: isGeneralLabel
                                ? Colors.blueAccent
                                : AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          (isGeneralLabel
                                                  ? Colors.blueAccent
                                                  : AppTheme.primaryColor)
                                              .withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isGeneralLabel
                                          ? 'LIBRARY'
                                          : 'PERSONALIZED',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: isGeneralLabel
                                            ? Colors.blueAccent
                                            : AppTheme.primaryColor,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${program.totalWeeks} WEEKS',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.3),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                program.name,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (program.startDate != null && !isPublic) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.4),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Started ${DateFormat('MMM d').format(program.startDate!)}',
                              style: TextStyle(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.4),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: ElevatedButton(
              onPressed: _isProcessing
                  ? null
                  : () async {
                      setState(() => _isProcessing = true);
                      bool dialogShown = false;
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      );
                      dialogShown = true;

                      try {
                        if (isPublic) {
                          final newProgramId = await dbService
                              .claimPublicProgram(program.id!, user.uid)
                              .timeout(const Duration(seconds: 30));

                          await Future.delayed(
                            const Duration(milliseconds: 500),
                          );

                          if (context.mounted) {
                            if (dialogShown) {
                              Navigator.pop(context);
                              dialogShown = false;
                            }

                            final newProgram = Program(
                              id: newProgramId,
                              name: program.name,
                              coachId: program.coachId,
                              assignedClientId: user.uid,
                              totalWeeks: program.totalWeeks,
                              status: ProgramStatus.active,
                              currentWeek: 1,
                              currentDay: 1,
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => WorkoutProgressionScreen(
                                  program: newProgram,
                                ),
                              ),
                            );
                          }
                        } else {
                          if (program.status == ProgramStatus.assigned) {
                            await dbService
                                .startProgram(program.id!)
                                .timeout(const Duration(seconds: 30));
                          }

                          await Future.delayed(
                            const Duration(milliseconds: 500),
                          );

                          if (context.mounted) {
                            if (dialogShown) {
                              Navigator.pop(context);
                              dialogShown = false;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    WorkoutProgressionScreen(program: program),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        debugPrint(
                          '[AssignedPrograms] Error starting program: $e',
                        );
                        String errorMessage = e.toString();
                        if (e is TimeoutException) {
                          errorMessage = 'Request timed out. Please try again.';
                        }

                        if (context.mounted) {
                          if (dialogShown) {
                            Navigator.pop(context);
                            dialogShown = false;
                          }
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(errorMessage)));
                        }
                      } finally {
                        if (mounted) {
                          setState(() => _isProcessing = false);
                          if (dialogShown) {
                            Navigator.pop(context);
                            dialogShown = false;
                          }
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  final String message;
  const _EmptyPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center_rounded,
                size: 64,
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.05),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
