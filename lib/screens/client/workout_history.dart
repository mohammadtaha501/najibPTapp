import 'package:flutter/material.dart';
import 'package:untitled3/widgets/common_widgets.dart';
import 'package:untitled3/models/log_model.dart';
import 'package:untitled3/services/database_service.dart';
import 'package:untitled3/utils/theme.dart';
import 'package:intl/intl.dart';
import 'package:untitled3/screens/common/workout_detail.dart';

import 'package:untitled3/screens/client/completed_programs_screen.dart';

class WorkoutHistoryScreen extends StatefulWidget {
  final String clientId;
  const WorkoutHistoryScreen({super.key, required this.clientId});

  @override
  State<WorkoutHistoryScreen> createState() => _WorkoutHistoryScreenState();
}

class _WorkoutHistoryScreenState extends State<WorkoutHistoryScreen> {
  final _dbService = DatabaseService();
  late Stream<List<WorkoutLog>> _logsStream;

  @override
  void initState() {
    super.initState();
    _logsStream = _dbService.getClientLogs(widget.clientId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('WORKOUT HISTORY')),
      body: StreamBuilder<List<WorkoutLog>>(
        stream: _logsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final logs = snapshot.data ?? [];
          
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildCompletedProgramsShortcut(context),
              const SizedBox(height: 16),
              if (logs.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Text('No workouts logged yet.', style: TextStyle(color: AppTheme.mutedTextColor)),
                  ),
                )
              else
                ...logs.map((log) => _buildLogCard(context, _dbService, log)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCompletedProgramsShortcut(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: ListTile(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompletedProgramsScreen())),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.emoji_events, color: Colors.black, size: 20),
        ),
        title: const Text('Completed Programs', style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('View your finished training plans', style: TextStyle(fontSize: 12, color: AppTheme.mutedTextColor)),
        trailing: const Icon(Icons.chevron_right, color: AppTheme.primaryColor),
      ),
    );
  }

  Widget _buildLogCard(BuildContext context, DatabaseService dbService, WorkoutLog log) {
    return CustomCard(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => WorkoutDetailScreen(log: log))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('EEEE, MMM d').format(log.date),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                DateFormat('HH:mm').format(log.date),
                style: const TextStyle(color: AppTheme.mutedTextColor, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            log.workoutDayId.toUpperCase(),
            style: const TextStyle(color: AppTheme.primaryColor, letterSpacing: 1.2, fontSize: 12),
          ),
          const Divider(),
          ...log.exerciseLogs.map((ex) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              children: [
                Expanded(child: Text(ex.exerciseName, style: const TextStyle(fontSize: 14))),
                Text(
                  '${ex.sets.length} sets',
                  style: const TextStyle(fontSize: 12, color: AppTheme.mutedTextColor),
                ),
              ],
            ),
          )),
          if (log.notes != null && log.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notes, size: 16, color: AppTheme.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      log.notes!,
                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
