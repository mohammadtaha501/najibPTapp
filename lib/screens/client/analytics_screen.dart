import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ptapp/services/database_service.dart';
import 'package:ptapp/utils/theme.dart';
import 'package:ptapp/widgets/common_widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  final String clientId;
  const AnalyticsScreen({super.key, required this.clientId});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  final _dbService = DatabaseService();
  late Stream<Map<String, dynamic>> _statsStream;

  @override
  void initState() {
    super.initState();
    _statsStream = _dbService.getClientStats(widget.clientId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PROGRESS ANALYTICS')),
      body: StreamBuilder<Map<String, dynamic>>(
        stream: _statsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final stats = snapshot.data ?? {'consistency': 0, 'sessions': 0, 'totalWeight': 0.0};
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SectionHeader(title: 'Overview'),
                _buildStatSummary(stats),
                const SizedBox(height: 24),
                const SectionHeader(title: 'Workout Consistency'),
                _buildConsistencyChart(stats['consistency']),
                const SizedBox(height: 24),
                const SectionHeader(title: 'Strength Progress (Volume)'),
                _buildStrengthChart(stats['trends'] ?? []),
                const SizedBox(height: 24),
                const SectionHeader(title: 'Exercise Performance'),
                _buildExerciseTrends(stats['exerciseTrends'] ?? {}),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildExerciseTrends(Map<dynamic, dynamic> exerciseTrends) {
    if (exerciseTrends.isEmpty) return const CustomCard(child: Center(child: Padding(padding: EdgeInsets.all(20), child: Text('No exercise data recorded.'))));

    return Column(
      children: exerciseTrends.entries.map((entry) {
        final exerciseName = entry.key;
        final logs = entry.value as List<dynamic>;
        
        // Map logs to spots
        final spots = logs.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['weight'] as num).toDouble())).toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: CustomCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exerciseName.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.primaryColor, letterSpacing: 1)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 120,
                  child: LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(
                        bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30, interval: 10)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          color: AppTheme.primaryColor,
                          barWidth: 3,
                          dotData: const FlDotData(show: true),
                          belowBarData: BarAreaData(show: true, color: AppTheme.primaryColor.withOpacity(0.05)),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Last: ${logs.last['weight']}kg', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildConsistencyChart(int consistency) {
    return CustomCard(
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: consistency.toDouble(),
                    color: AppTheme.primaryColor,
                    radius: 30,
                    showTitle: false,
                  ),
                  PieChartSectionData(
                    value: (100 - consistency).toDouble(),
                    color: AppTheme.surfaceColor,
                    radius: 30,
                    showTitle: false,
                  ),
                ],
                centerSpaceRadius: 40,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('$consistency% Consistency', style: const TextStyle(fontWeight: FontWeight.bold)),
          const Text('Based on assigned sessions', style: TextStyle(fontSize: 10, color: AppTheme.mutedTextColor)),
        ],
      ),
    );
  }

  Widget _buildStrengthChart(List<dynamic> trends) {
    if (trends.isEmpty) return const CustomCard(child: Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Not enough data for trends yet.'))));
    
    final spots = trends.map((t) => FlSpot((t['day'] as int).toDouble(), (t['volume'] as double) / 1000)).toList();

    return CustomCard(
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: const FlGridData(show: true),
            titlesData: const FlTitlesData(
              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
              topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: AppTheme.accentColor,
                barWidth: 4,
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: AppTheme.accentColor.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatSummary(Map<String, dynamic> stats) {
    return Row(
      children: [
        Expanded(
          child: CustomCard(
            child: Column(
              children: [
                const Text('Total Lifted', style: TextStyle(fontSize: 12, color: AppTheme.mutedTextColor)),
                Text('${stats['totalWeight'].toStringAsFixed(0)} kg', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: CustomCard(
            child: Column(
              children: [
                const Text('Total Sessions', style: TextStyle(fontSize: 12, color: AppTheme.mutedTextColor)),
                Text('${stats['sessions']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
