import 'package:flutter/material.dart';
import 'package:ptapp/models/program_model.dart';
import 'package:ptapp/services/database_service.dart';
import 'package:ptapp/screens/client/workout_view.dart';
import 'package:ptapp/utils/theme.dart';
import 'package:ptapp/widgets/common_widgets.dart';

class ProgramViewScreen extends StatefulWidget {
  final String clientId;
  final Program program;

  const ProgramViewScreen({
    super.key,
    required this.clientId,
    required this.program,
  });

  @override
  State<ProgramViewScreen> createState() => _ProgramViewScreenState();
}

class _ProgramViewScreenState extends State<ProgramViewScreen> {
  final _dbService = DatabaseService();
  late Stream<List<WorkoutDay>> _daysStream;

  @override
  void initState() {
    super.initState();
    _daysStream = _dbService.getProgramDays(widget.program.id!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.program.name.toUpperCase()),
      ),
      body: StreamBuilder<List<WorkoutDay>>(
        stream: _daysStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final allDays = snapshot.data ?? [];
          final days = allDays.where((d) => d.week <= widget.program.totalWeeks).toList();
          if (days.isEmpty) {
            return const Center(child: Text('No workout days added yet.'));
          }

          // Group days by week
          final Map<int, List<WorkoutDay>> weeks = {};
          for (var day in days) {
            weeks.putIfAbsent(day.week, () => []).add(day);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: weeks.length,
            itemBuilder: (context, index) {
              final weekNum = weeks.keys.elementAt(index);
              final weekDays = weeks[weekNum]!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'WEEK $weekNum',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  ...weekDays.map((day) => CustomCard(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkoutView(
                          clientId: widget.clientId,
                          programId: widget.program.id!,
                          workoutDay: day,
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Day ${day.day}: ${day.muscleGroup}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${day.exercises.length} Exercises',
                              style: const TextStyle(fontSize: 12, color: AppTheme.mutedTextColor),
                            ),
                          ],
                        ),
                        const Icon(Icons.play_arrow_rounded, color: AppTheme.primaryColor),
                      ],
                    ),
                  )),
                  const SizedBox(height: 16),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
