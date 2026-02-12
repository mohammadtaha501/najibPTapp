import 'package:flutter/material.dart';
import 'package:ptapp/models/log_model.dart';
import 'package:ptapp/utils/theme.dart';
import 'package:ptapp/widgets/common_widgets.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final WorkoutLog log;

  const WorkoutDetailScreen({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WORKOUT DETAILS'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            ...log.exerciseLogs.map((e) => _buildExerciseExpansion(e)),
            if (log.notes != null && log.notes!.isNotEmpty) ...[
              const SectionHeader(title: 'Session Notes'),
              CustomCard(
                child: Text(log.notes!, style: const TextStyle(fontStyle: FontStyle.italic)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return CustomCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(log.workoutDayId.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              Text(log.date.toString().split(' ')[0], style: const TextStyle(color: AppTheme.mutedTextColor)),
            ],
          ),
          const Icon(Icons.calendar_today, color: AppTheme.primaryColor),
        ],
      ),
    );
  }

  Widget _buildExerciseExpansion(ExerciseLog exLog) {
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(exLog.exerciseName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor)),
          const SizedBox(height: 8),
          const Row(
            children: [
              SizedBox(width: 40, child: Text('SET', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold))),
              Expanded(child: Center(child: Text('WEIGHT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
              Expanded(child: Center(child: Text('REPS', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
              Expanded(child: Center(child: Text('RPE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)))),
            ],
          ),
          const Divider(height: 16),
          ...exLog.sets.asMap().entries.map((entry) {
            final idx = entry.key;
            final s = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  SizedBox(width: 40, child: Text('${idx + 1}', style: const TextStyle(color: AppTheme.mutedTextColor))),
                  Expanded(child: Center(child: Text('${s.weight} kg'))),
                  Expanded(child: Center(child: Text('${s.reps}'))),
                  Expanded(child: Center(child: Text('${s.rpe ?? '-'}'))),
                ],
              ),
            );
          }),
          if (exLog.notes != null && exLog.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text('Note: ${exLog.notes}', style: const TextStyle(fontSize: 12, color: AppTheme.mutedTextColor)),
            ),
        ],
      ),
    );
  }
}
