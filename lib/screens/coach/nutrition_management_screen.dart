import 'package:flutter/material.dart';
import 'package:untitled3/models/nutrition_plan_model.dart';
import 'package:untitled3/services/database_service.dart';
import 'package:untitled3/utils/theme.dart';
import 'package:untitled3/widgets/common_widgets.dart';
import 'package:untitled3/screens/coach/nutrition_editor_screen.dart';
import 'package:intl/intl.dart';

class NutritionManagementScreen extends StatefulWidget {
  final String clientId;
  final String clientName;

  const NutritionManagementScreen({
    super.key,
    required this.clientId,
    required this.clientName,
  });

  @override
  State<NutritionManagementScreen> createState() => _NutritionManagementScreenState();
}

class _NutritionManagementScreenState extends State<NutritionManagementScreen> {
  final _dbService = DatabaseService();
  late Stream<NutritionPlan?> _planStream;

  @override
  void initState() {
    super.initState();
    _planStream = _dbService.getActiveNutritionPlan(widget.clientId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nutrition: ${widget.clientName}'),
      ),
      body: StreamBuilder<NutritionPlan?>(
        stream: _planStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final plan = snapshot.data;
          
          if (plan == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant, size: 80, color: Colors.white.withOpacity(0.05)),
                    const SizedBox(height: 24),
                    const Text(
                      'No nutrition plan created for this client.',
                      style: TextStyle(color: AppTheme.mutedTextColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NutritionEditorScreen(clientId: widget.clientId))),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.black,
                        minimumSize: const Size(200, 50),
                      ),
                      child: const Text('CREATE PLAN', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            plan.goal.label.toUpperCase(),
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                        ),
                        Text(
                          'Active Plan',
                          style: TextStyle(fontSize: 12, color: AppTheme.primaryColor.withOpacity(0.7), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(plan.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      '${plan.sections.length} Guidance Sections',
                      style: const TextStyle(color: AppTheme.mutedTextColor, fontSize: 14),
                    ),
                    const Divider(height: 32, color: Colors.white10),
                    Row(
                      children: [
                        const Icon(Icons.history, size: 14, color: AppTheme.mutedTextColor),
                        const SizedBox(width: 8),
                        Text(
                          'Updated ${DateFormat('MMM dd, yyyy').format(plan.updatedAt)}',
                          style: const TextStyle(fontSize: 12, color: AppTheme.mutedTextColor),
                        ),
                        const Spacer(),
                        if (plan.lastViewedByClient != null) ...[
                          const Icon(Icons.check_circle, size: 14, color: AppTheme.primaryColor),
                          const SizedBox(width: 4),
                          const Text('Viewed', style: TextStyle(fontSize: 12, color: AppTheme.primaryColor)),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NutritionEditorScreen(clientId: widget.clientId, plan: plan))),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.black,
                      ),
                      child: const Text('EDIT PLAN', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
