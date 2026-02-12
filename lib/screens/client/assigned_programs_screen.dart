import 'package:flutter/material.dart';
import 'package:untitled3/models/program_model.dart';
import 'package:untitled3/services/database_service.dart';
import 'package:untitled3/utils/theme.dart';
import 'package:untitled3/screens/client/workout_progression_screen.dart';
import 'package:provider/provider.dart';
import 'package:untitled3/providers/auth_provider.dart';
import 'package:intl/intl.dart';

class AssignedProgramsScreen extends StatefulWidget {
  const AssignedProgramsScreen({super.key});

  @override
  State<AssignedProgramsScreen> createState() => _AssignedProgramsScreenState();
}

class _AssignedProgramsScreenState extends State<AssignedProgramsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Stream<List<Program>> _clientProgramsStream;
  late Stream<List<Program>> _publicProgramsStream;
  final _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final user = Provider.of<AuthProvider>(context, listen: false).userProfile!;
    _clientProgramsStream = _dbService.getClientPrograms(user.uid);
    // Handle case where coachId might be null or empty string, though typically it should depend on business logic
    _publicProgramsStream = _dbService.getPublicPrograms(user.coachId ?? '');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).userProfile!;
    final dbService = _dbService;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Programs'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              height: 44,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  return Row(
                    children: [
                      _buildToggleButton(0, 'IN PROGRESS'),
                      _buildToggleButton(1, 'NEW PLANS'),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. IN PROGRESS TAB
          _buildProgramList(
            dbService, 
            user, 
            stream: _clientProgramsStream,
            filter: (p) => p.status == ProgramStatus.active,
            emptyMessage: 'No programs currently in progress.',
            buttonLabel: "START TODAY'S WORKOUT",
          ),

          // 2. NEW PLANS TAB
          StreamBuilder<List<Program>>(
            stream: _clientProgramsStream,
            builder: (context, personalSnapshot) {
              return StreamBuilder<List<Program>>(
                stream: _publicProgramsStream,
                builder: (context, publicSnapshot) {
                  final personal = personalSnapshot.data ?? [];
                  final public = publicSnapshot.data ?? [];
                  
                  final unstartedPersonal = personal.where((p) => p.status == ProgramStatus.assigned).toList();
                  
                  // Filter public programs: 
                  // Don't show if user has an ACTIVE or ASSIGNED (unstarted) copy of it.
                  // IF they have a COMPLETED copy, they CAN see it again to restart.
                  final claimingActiveOrAssignedIds = personal
                      .where((p) => p.parentProgramId != null && (p.status == ProgramStatus.active || p.status == ProgramStatus.assigned))
                      .map((p) => p.parentProgramId!)
                      .toSet();

                  final availablePublic = public.where((p) => !claimingActiveOrAssignedIds.contains(p.id)).toList();
                  final allNewPlans = [...unstartedPersonal, ...availablePublic];

                  if (allNewPlans.isEmpty) {
                    return const _EmptyPlaceholder(message: 'No new plans available.');
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: allNewPlans.length,
                    itemBuilder: (context, index) {
                      final program = allNewPlans[index];
                      // If it's in the 'public' list, it's a general program.
                      // If it's in the 'unstartedPersonal' list, it's a customized plan (or a re-assigned one).
                      final bool isGeneral = program.isPublic || (program.parentProgramId != null && program.isPublic == false); 
                      // Actually, if it's from availablePublic, it isGeneral = true.
                      // If it's from unstartedPersonal, it's customized (or specifically assigned).
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
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(int index, String label) {
    final isSelected = _tabController.index == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabController.animateTo(index)),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : AppTheme.mutedTextColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgramList(
    DatabaseService dbService, 
    dynamic user, 
    {required Stream<List<Program>> stream, 
    required bool Function(Program) filter, 
    required String emptyMessage,
    required String buttonLabel}
  ) {
    return StreamBuilder<List<Program>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final filtered = (snapshot.data ?? []).where(filter).toList();

        if (filtered.isEmpty) {
          return _EmptyPlaceholder(message: emptyMessage);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            return _buildProgramCard(context, filtered[index], dbService, isPublic: false, buttonLabel: buttonLabel);
          },
        );
      },
    );
  }

  Widget _buildProgramCard(BuildContext context, Program program, DatabaseService dbService, {required bool isPublic, required String buttonLabel, bool isGeneralLabel = false}) {
    final user = Provider.of<AuthProvider>(context, listen: false).userProfile!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.fitness_center, color: AppTheme.primaryColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              program.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isGeneralLabel ? Colors.blueAccent.withOpacity(0.1) : AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isGeneralLabel ? Colors.blueAccent.withOpacity(0.3) : AppTheme.primaryColor.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              isGeneralLabel ? 'GENERAL' : 'CUSTOMIZED',
                              style: TextStyle(
                                fontSize: 9, 
                                fontWeight: FontWeight.bold, 
                                color: isGeneralLabel ? Colors.blueAccent : AppTheme.primaryColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${program.totalWeeks} weeks',
                        style: const TextStyle(color: AppTheme.mutedTextColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (program.startDate != null && !isPublic) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined, size: 14, color: AppTheme.mutedTextColor),
                  const SizedBox(width: 8),
                  Text(
                    'Assigned ${DateFormat('MMM d, yyyy').format(program.startDate!)}',
                    style: const TextStyle(color: AppTheme.mutedTextColor, fontSize: 12),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                if (isPublic) {
                  final newProgramId = await dbService.claimPublicProgram(program.id!, user.uid);
                  if (context.mounted) {
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
                      MaterialPageRoute(builder: (_) => WorkoutProgressionScreen(program: newProgram)),
                    );
                  }
                } else {
                  if (program.status == ProgramStatus.assigned) {
                    await dbService.startProgram(program.id!);
                  }
                  if (context.mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => WorkoutProgressionScreen(program: program)),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black),
              ),
            ),
          ],
        ),
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.fitness_center_outlined, size: 80, color: AppTheme.mutedTextColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: AppTheme.mutedTextColor, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
