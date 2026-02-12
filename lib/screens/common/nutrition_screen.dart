import 'package:flutter/material.dart';
import 'package:ptapp/models/nutrition_plan_model.dart';
import 'package:ptapp/models/nutrition_checkin_model.dart';
import 'package:ptapp/services/database_service.dart';
import 'package:ptapp/utils/theme.dart';
import 'package:intl/intl.dart';

class NutritionScreen extends StatefulWidget {
  final String clientId;
  final bool isCoach;

  const NutritionScreen({
    super.key,
    required this.clientId,
    required this.isCoach,
  });

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final _dbService = DatabaseService();
  final _checkinController = TextEditingController();
  AdherenceStatus? _selectedStatus;
  bool _isSavingCheckin = false;
  bool _isEditing = false;
  bool _isAddingNew = false;
  String? _editingCheckinId;
  DateTime? _editingCreatedAt;
  late Stream<NutritionPlan?> _planStream;
  late Stream<List<WeeklyNutritionCheckIn>> _weeklyCheckinsStream;
  late Stream<List<WeeklyNutritionCheckIn>> _historyStream;

  @override
  void initState() {
    super.initState();
    _planStream = _dbService.getActiveNutritionPlan(widget.clientId);
    _weeklyCheckinsStream = _dbService.getWeeklyCheckinsForWeek(widget.clientId, _currentWeekStart);
    _historyStream = _dbService.getWeeklyCheckInHistory(widget.clientId);
  }

  DateTime get _currentWeekStart {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  @override
  void dispose() {
    _checkinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NUTRITION GUIDANCE'),
      ),
      body: StreamBuilder<NutritionPlan?>(
        stream: _planStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final plan = snapshot.data;

          if (plan == null) {
            return _buildEmptyState();
          }

          // Mark as read if client is viewing
          if (!widget.isCoach) {
            _dbService.markNutritionPlanAsViewed(widget.clientId, plan.id!);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(plan),
                const SizedBox(height: 32),
                _buildSectionLabel('YOUR GUIDELINES'),
                ...plan.sections.map((section) => _buildExpandableSection(section)),
                if (plan.mode == NutritionPlanMode.weeklyAdherence) ...[
                  const SizedBox(height: 32),
                  _buildWeeklyAdherenceSection(plan),
                ],
                const SizedBox(height: 48),
                Center(
                  child: Text(
                    'Last updated: ${DateFormat('MMM dd, yyyy').format(plan.updatedAt)}',
                    style: const TextStyle(color: AppTheme.mutedTextColor, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 80, color: Colors.white.withOpacity(0.05)),
            const SizedBox(height: 24),
            Text(
              widget.isCoach ? 'No nutrition plan created for this client.' : 'Your coach hasn\'t shared your nutrition plan yet.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.mutedTextColor, fontSize: 16),
            ),
          if (widget.isCoach) ...[
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // This would navigate to editor, but usually context manages this
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
                minimumSize: const Size(200, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('CREATE PLAN', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      )
     ),
    );
  }

  Widget _buildWeeklyAdherenceSection(NutritionPlan plan) {
    if (widget.isCoach) {
      return _buildCoachAdherenceSummary();
    }

    return StreamBuilder<List<WeeklyNutritionCheckIn>>(
      stream: _weeklyCheckinsStream,
      builder: (context, snapshot) {
        final history = snapshot.data ?? [];
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isEditing || _isAddingNew || history.isEmpty)
              _buildWeeklyAdherenceCard(
                plan, 
                _isEditing ? history.firstWhere((c) => c.id == _editingCheckinId) : null, 
                isFormMode: true
              )
            else
              ElevatedButton.icon(
                onPressed: () => setState(() => _isAddingNew = true),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('LOG PROGRESS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  foregroundColor: AppTheme.primaryColor,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: AppTheme.primaryColor, width: 1),
                  ),
                ),
              ),
            if (history.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildSectionLabel('THIS WEEK\'S LOGS'),
              ...history.map((checkin) => _buildHistoryItem(checkin)),
            ],
          ],
        );
      },
    );
  }

  Widget _buildCoachAdherenceSummary() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionLabel('CLIENT ADHERENCE HISTORY'),
        StreamBuilder<List<WeeklyNutritionCheckIn>>(
          stream: _historyStream,
          builder: (context, snapshot) {
            final history = snapshot.data ?? [];
            if (history.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: const Text(
                  'No adherence check-ins submitted yet.',
                  style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 13),
                ),
              );
            }

            return Column(
              children: history.map((c) => _buildHistoryItem(c)).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHistoryItem(WeeklyNutritionCheckIn checkin) {
    final dateStr = DateFormat('MMM dd').format(checkin.weekStartDate);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Week of $dateStr', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(
                '${checkin.status.emoji} ${checkin.status.label.toUpperCase()}',
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
              ),
            ],
          ),
          if (checkin.notes.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              checkin.notes,
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12, height: 1.4),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            'Logged on ${DateFormat('MMM dd, yyyy').format(checkin.createdAt)}',
            style: TextStyle(color: AppTheme.mutedTextColor.withOpacity(0.5), fontSize: 10, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyAdherenceCard(NutritionPlan plan, WeeklyNutritionCheckIn? checkin, {required bool isFormMode}) {
    final bool isSubmitted = checkin != null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (isSubmitted && !isFormMode) ? AppTheme.primaryColor.withOpacity(0.2) : Colors.white10,
          width: (isSubmitted && !isFormMode) ? 1.5 : 1,
        ),
        boxShadow: (isSubmitted && !isFormMode) ? [
          BoxShadow(color: AppTheme.primaryColor.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))
        ] : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.fact_check, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 12),
              const Text(
                'THIS WEEK\'S CHECK-IN',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.1),
              ),
              const Spacer(),
              if (isSubmitted && !isFormMode)
                const Icon(Icons.check_circle, color: AppTheme.primaryColor, size: 16),
            ],
          ),
          const SizedBox(height: 16),
          if (isFormMode)
            _buildNotSubmittedState(plan)
          else
            _buildSubmittedState(checkin!),
        ],
      ),
    );
  }

  Widget _buildSubmittedState(WeeklyNutritionCheckIn checkin) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(checkin.status.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  checkin.status.label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Submitted on ${DateFormat('MMM dd').format(checkin.createdAt)}',
                  style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        if (checkin.notes.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              checkin.notes,
              style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.white70),
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() {
            _isEditing = true;
            _editingCheckinId = checkin.id;
            _editingCreatedAt = checkin.createdAt;
            _selectedStatus = checkin.status;
            _checkinController.text = checkin.notes;
          }),
          style: TextButton.styleFrom(
            padding: EdgeInsets.all(12),
            backgroundColor: AppTheme.primaryColor.withOpacity(0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit, size: 14, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('EDIT CHECK-IN', style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotSubmittedState(NutritionPlan plan) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How closely did you follow your nutrition plan this week?',
          style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 13),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: AdherenceStatus.values.map((s) => _buildStatusOption(s)).toList(),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _checkinController,
          maxLines: 2,
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Any challenges or notes? (optional)',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 13),
            filled: true,
            fillColor: Colors.white.withOpacity(0.03),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            if (_isEditing) ...[
              Expanded(
                child: TextButton(
                  onPressed: () => setState(() {
                    _isEditing = false;
                    _isAddingNew = false;
                    _editingCheckinId = null;
                    _editingCreatedAt = null;
                    _selectedStatus = null;
                    _checkinController.clear();
                  }),
                  child: const Text('CANCEL', style: TextStyle(color: AppTheme.mutedTextColor)),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: (_selectedStatus == null || _isSavingCheckin) ? null : () => _submitCheckin(plan),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: Colors.white10,
                ),
                child: _isSavingCheckin 
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54))
                  : Text(_isEditing ? 'UPDATE CHECK-IN' : 'SUBMIT WEEKLY CHECK-IN', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusOption(AdherenceStatus status) {
    final bool isSelected = _selectedStatus == status;
    return GestureDetector(
      onTap: () => setState(() => _selectedStatus = status),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.transparent),
            ),
            child: Text(status.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(height: 8),
          Text(
            status.label.split(' ')[0], // Short label
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppTheme.primaryColor : AppTheme.mutedTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitCheckin(NutritionPlan plan) async {
    setState(() => _isSavingCheckin = true);
    
    final checkin = WeeklyNutritionCheckIn(
      id: _editingCheckinId,
      clientId: widget.clientId,
      nutritionPlanId: plan.id!,
      weekStartDate: _currentWeekStart,
      status: _selectedStatus!,
      notes: _checkinController.text.trim(),
      createdAt: _editingCreatedAt,
    );

    try {
      await _dbService.saveWeeklyCheckIn(checkin);
      if (mounted) {
        setState(() {
          _isSavingCheckin = false;
          _isEditing = false;
          _isAddingNew = false;
          _editingCheckinId = null;
          _editingCreatedAt = null;
          _selectedStatus = null;
          _checkinController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_editingCheckinId != null ? 'Weekly check-in updated!' : 'Weekly check-in submitted!')));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSavingCheckin = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error submitting check-in: $e')));
      }
    }
  }

  Widget _buildHeader(NutritionPlan plan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.15), AppTheme.surfaceColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              plan.goal.label.toUpperCase(),
              style: const TextStyle(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            plan.title,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Personalized Guidance',
            style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildExpandableSection(NutritionSection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            section.title,
            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16),
          ),
          iconColor: AppTheme.primaryColor,
          collapsedIconColor: Colors.white38,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          children: [
            Container(
              alignment: Alignment.topLeft,
              child: Text(
                section.content.isEmpty ? 'No specific notes for this section.' : section.content,
                style: const TextStyle(color: Colors.white70, height: 1.6, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
