import 'package:flutter/material.dart';
import 'package:untitled3/models/program_model.dart';
import 'package:untitled3/services/database_service.dart';
import 'package:untitled3/utils/theme.dart';
import 'package:untitled3/screens/client/workout_progression_screen.dart';
import 'package:provider/provider.dart';
import 'package:untitled3/providers/auth_provider.dart';

class CompletedProgramsScreen extends StatefulWidget {
  const CompletedProgramsScreen({super.key});

  @override
  State<CompletedProgramsScreen> createState() => _CompletedProgramsScreenState();
}

class _CompletedProgramsScreenState extends State<CompletedProgramsScreen> {
  final _dbService = DatabaseService();
  late Stream<List<Program>> _programsStream;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      final user = Provider.of<AuthProvider>(context).userProfile!;
      _programsStream = _dbService.getClientPrograms(user.uid);
      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Completed Programs'),
      ),
      body: StreamBuilder<List<Program>>(
        stream: _programsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final programs = snapshot.data ?? [];
          final completedPrograms = programs.where((p) => p.status == ProgramStatus.completed).toList();

          if (completedPrograms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_outlined, size: 80, color: AppTheme.mutedTextColor.withOpacity(0.5)),
                  const SizedBox(height: 24),
                  const Text(
                    'No completed programs yet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Keep training to build your history!',
                    style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: completedPrograms.length,
            itemBuilder: (context, index) {
              final program = completedPrograms[index];
              return _buildCompletedProgramCard(context, program);
            },
          );
        },
      ),
    );
  }

  Widget _buildCompletedProgramCard(BuildContext context, Program program) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
        ),
        title: Text(
          program.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${program.totalWeeks} weeks',
              style: const TextStyle(color: AppTheme.mutedTextColor, fontSize: 13),
            ),
            if (program.startDate != null)
              Text(
                'Completed',
                style: TextStyle(color: Colors.green.shade300, fontSize: 12, fontWeight: FontWeight.bold),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => WorkoutProgressionScreen(program: program)),
          );
        },
      ),
    );
  }
}
