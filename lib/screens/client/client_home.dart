
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled3/providers/auth_provider.dart';
import 'package:untitled3/utils/theme.dart';
import 'package:intl/intl.dart';
import 'package:untitled3/screens/common/nutrition_screen.dart';
import 'package:untitled3/screens/common/chat_screen.dart';
import 'package:untitled3/models/program_model.dart';
import 'package:untitled3/services/database_service.dart';
import 'package:untitled3/screens/client/workout_progression_screen.dart';
import 'package:untitled3/screens/client/assigned_programs_screen.dart';

import '../../models/nutrition_plan_model.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final _dbService = DatabaseService();
  late Stream<List<Program>> _programsStream;
  Stream<List<Program>>? _publicProgramsStream;
  late Stream<int> _unreadCountStream;
  late Stream<NutritionPlan?> _nutritionPlanStream;
  final Map<String, Stream<double>> _progressStreams = {};
  bool _streamsInitialized = false;

  Stream<double> _getProgramProgressStream(String programId) {
    return _progressStreams.putIfAbsent(
      programId,
      () => _dbService.getProgramProgress(programId),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_streamsInitialized) {
      final authProvider = Provider.of<AuthProvider>(context);
      final user = authProvider.userProfile;
      if (user != null) {
        _programsStream = _dbService.getClientPrograms(user.uid);
        _publicProgramsStream = _dbService.getPublicPrograms(user.coachId ?? '');
        _unreadCountStream = _dbService.getUnreadCount(user.coachId ?? '', user.uid);
        _nutritionPlanStream = _dbService.getActiveNutritionPlan(user.uid);
        _streamsInitialized = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userProfile!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('MY TRAINING'),
      ),
      body: StreamBuilder<List<Program>>(
        stream: _programsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final programs = snapshot.data ?? [];
          final activeAndAssigned = programs.where((p) => p.status == ProgramStatus.active || p.status == ProgramStatus.assigned).toList();
          
          Program? activeProgram;
          Program? newlyAssignedProgram;
          int currentWeek = 1;
          
          if (activeAndAssigned.isNotEmpty) {
            // Priority: 1. Active, 2. Assigned
            activeProgram = activeAndAssigned.firstWhere(
              (p) => p.status == ProgramStatus.active, 
              orElse: () => activeAndAssigned.first
            );
            
            // Newly assigned is anything that isn't the current active one
            if (activeProgram.status == ProgramStatus.active) {
              newlyAssignedProgram = activeAndAssigned.where((p) => p.status == ProgramStatus.assigned).firstOrNull;
            }

            if (activeProgram.startDate != null) {
              final daysSinceStart = DateTime.now().difference(activeProgram.startDate!).inDays;
              currentWeek = (daysSinceStart / 7).floor() + 1;
            }
          }

          if (activeAndAssigned.isEmpty) {
            return StreamBuilder<List<Program>>(
              stream: _publicProgramsStream,
              builder: (context, publicSnapshot) {
                final public = publicSnapshot.data ?? [];
                
                // Filter out public programs already claimed (active, assigned, or completed)
                final claimedProgramIds = programs
                    .where((p) => p.parentProgramId != null)
                    .map((p) => p.parentProgramId!)
                    .toSet();
                
                final availablePublic = public.where((p) => !claimedProgramIds.contains(p.id)).toList();
                
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white.withOpacity(0.05)),
                          ),
                          child: Icon(
                            Icons.fitness_center_outlined, 
                            size: 48, 
                            color: Colors.white.withOpacity(0.5)
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Text(
                          'No program started yet', 
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: -0.5)
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'You haven\'t started a training program yet. Message your coach or explore available plans to get started.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTheme.mutedTextColor, height: 1.5),
                        ),
                        const SizedBox(height: 40),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(
                                  currentUserId: user.uid,
                                  otherUserId: user.coachId ?? '',
                                  otherUserName: 'Coach',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.message_outlined, size: 20),
                          label: const Text('MESSAGE COACH'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.black,
                            minimumSize: const Size(double.infinity, 56),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                        ),
                        if (availablePublic.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const AssignedProgramsScreen()));
                            },
                            icon: const Icon(Icons.search, size: 20),
                            label: const Text('EXPLORE PROGRAMS'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 56),
                              side: BorderSide(color: Colors.white.withOpacity(0.1)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTodayHeader(user.name),
                const SizedBox(height: 24),
                // New Program Alert / Banner
                if (newlyAssignedProgram != null) ...[
                  _buildNewProgramBanner(context, newlyAssignedProgram, _dbService),
                  const SizedBox(height: 24),
                ],

                // Chat with Coach Card
                _buildChatCard(context, user),
                const SizedBox(height: 24),

                if (activeProgram != null) ...[
                  _buildActiveWorkoutCard(context, activeProgram, currentWeek, user.uid, _dbService, newlyAssignedProgram),
                  const SizedBox(height: 24),
                ],

                // Nutrition Focus Card
                _buildNutritionFocusCard(context, user.uid, _dbService),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTodayHeader(String name) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Today', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
        const SizedBox(height: 4),
        Text(
          DateFormat('EEEE, MMM d').format(DateTime.now()),
          style: const TextStyle(color: AppTheme.mutedTextColor, fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildActiveWorkoutCard(BuildContext context, Program activeProgram, int currentWeek, String userId, DatabaseService dbService, Program? newlyAssignedProgram) {
    final bool isAssigned = activeProgram.status == ProgramStatus.assigned;
    final bool isCompleted = activeProgram.status == ProgramStatus.completed;
    
    // Calculate simple progress (mocked for now or based on completed days vs total days)
    // In a real app, we'd count documents in 'logs' vs total workout days
    final double progress = 0.65; // Placeholder: 65%

    if (isCompleted) return const SizedBox.shrink();
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor.withOpacity(0.05), AppTheme.surfaceColor],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'CURRENT PROGRAM',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: 1),
                      ),
                    ),
                    Text(
                      'Week ${activeProgram.currentWeek ?? 1}',
                      style: const TextStyle(color: AppTheme.mutedTextColor, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(activeProgram.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white)),
                const SizedBox(height: 8),
                Text(
                  isAssigned ? 'New program assigned by coach' : 'Ready for Day ${activeProgram.currentDay ?? 1}',
                  style: const TextStyle(color: AppTheme.mutedTextColor, fontSize: 14),
                ),
                const SizedBox(height: 24),
                // Progress Bar
                StreamBuilder<double>(
                  stream: _getProgramProgressStream(activeProgram.id!),
                  builder: (context, snapshot) {
                    final double progress = snapshot.data ?? 0.0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Weekly Progress', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
                            Text('${(progress * 100).toInt()}%', style: const TextStyle(color: AppTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progress,
                            backgroundColor: Colors.white.withOpacity(0.05),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    );
                  }
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: ElevatedButton(
              onPressed: () async {
                if (isAssigned) await dbService.startProgram(activeProgram.id!);
                if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => WorkoutProgressionScreen(program: activeProgram)));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                isAssigned ? 'START PROGRAM' : "START TODAY'S WORKOUT", 
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatCard(BuildContext context, dynamic user) {
    return StreamBuilder<int>(
      stream: _unreadCountStream,
      builder: (context, snapshot) {
        final unread = snapshot.data ?? 0;
        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(currentUserId: user.uid, otherUserId: user.coachId ?? '', otherUserName: 'Coach'))),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryColor, size: 32),
                    if (unread > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                          child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Chat with Coach', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text('Have a question about your training?', style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 13)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppTheme.primaryColor),
              ],
            ),
          ),
        );
      }
    );
  }


  Widget _buildNutritionFocusCard(BuildContext context, String userId, DatabaseService dbService) {
    return StreamBuilder<NutritionPlan?>(
      stream: _nutritionPlanStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final plan = snapshot.data!;
        
        // Determine Status logic
        String statusText = 'Ongoing';
        Color statusColor = Colors.green;
        
        if (plan.lastViewedByClient == null) {
          statusText = 'New';
          statusColor = AppTheme.primaryColor;
        } else if (plan.lastViewedByClient!.isBefore(plan.updatedAt)) {
          statusText = 'Updated';
          statusColor = Colors.orange;
        }

        return GestureDetector(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => NutritionScreen(
              clientId: userId, 
              isCoach: false,
            )));
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: statusText != 'Ongoing' ? statusColor.withOpacity(0.5) : Colors.white.withOpacity(0.05),
                width: statusText != 'Ongoing' ? 1.5 : 1,
              ),
              boxShadow: statusText != 'Ongoing' ? [
                BoxShadow(color: statusColor.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))
              ] : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Nutrition Focus', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.mutedTextColor, letterSpacing: 1)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Text(statusText.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(plan.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 8),
                Text(plan.goal.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 20),
                const Row(
                  children: [
                    Text('View', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 16, color: AppTheme.primaryColor),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }




  Widget _buildNewProgramBanner(BuildContext context, Program program, DatabaseService dbService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.primaryColor.withOpacity(0.2), Colors.transparent]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars, color: AppTheme.primaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('NEW PROGRAM READY!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryColor)),
                Text(program.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await dbService.startProgram(program.id!);
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WorkoutProgressionScreen(program: program),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(0, 36),
            ),
            child: const Text('ACTIVATE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
