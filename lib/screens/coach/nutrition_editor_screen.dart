import 'package:flutter/material.dart';
import 'package:ptapp/models/nutrition_plan_model.dart';
import 'package:ptapp/services/database_service.dart';
import 'package:ptapp/utils/theme.dart';
import 'package:ptapp/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class NutritionEditorScreen extends StatefulWidget {
  final String clientId;
  final NutritionPlan? plan;

  const NutritionEditorScreen({super.key, required this.clientId, this.plan});

  @override
  State<NutritionEditorScreen> createState() => _NutritionEditorScreenState();
}

class _NutritionEditorScreenState extends State<NutritionEditorScreen> {
  final _dbService = DatabaseService();
  final _titleController = TextEditingController();
  NutritionGoal _goal = NutritionGoal.maintenance;
  NutritionPlanMode _mode = NutritionPlanMode.referenceOnly;
  List<NutritionSection> _sections = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.plan != null) {
      _titleController.text = widget.plan!.title;
      _goal = widget.plan!.goal;
      _mode = widget.plan!.mode;
      _sections = List.from(widget.plan!.sections);
    } else {
      _titleController.text = 'Nutrition Plan';
      // Add a couple of default sections to help the coach start
      _sections = [
        NutritionSection(title: 'Daily Calories', content: ''),
        NutritionSection(title: 'Protein Guidelines', content: ''),
      ];
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a plan title')));
      return;
    }

    if (_sections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one guideline section')));
      return;
    }

    // Check if every section has content
    for (final section in _sections) {
      if (section.content.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please add a description for "${section.title}"')));
        return;
      }
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final newPlan = NutritionPlan(
      id: widget.plan?.id,
      clientId: widget.clientId,
      coachId: authProvider.userProfile!.uid,
      title: _titleController.text.trim(),
      goal: _goal,
      mode: _mode,
      sections: _sections,
      createdAt: widget.plan?.createdAt,
      lastViewedByClient: widget.plan?.lastViewedByClient,
    );

    try {
      await _dbService.saveNutritionPlan(newPlan);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving plan: $e')));
      }
    }
  }

  void _addSection() {
    setState(() {
      _sections.add(NutritionSection(title: 'New Section', content: ''));
    });
  }

  void _removeSection(int index) {
    setState(() {
      _sections.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.plan == null ? 'CREATE NUTRITION' : 'EDIT NUTRITION'),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _isLoading ? null : _save),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionLabel('PLAN INFO'),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Plan Title',
                    hintText: 'e.g. Fat Loss Phase 1',
                    filled: true,
                    fillColor: AppTheme.surfaceColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSectionLabel('PRIMARY GOAL'),
                _buildGoalSelector(),
                const SizedBox(height: 32),
                _buildSectionLabel('NUTRITION MODE'),
                _buildModeSelector(),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildSectionLabel('GUIDELINE SECTIONS'),
                    TextButton.icon(
                      onPressed: _addSection,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('ADD SECTION'),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.primaryColor),
                    ),
                  ],
                ),
                if (_sections.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('No sections added. Tap "ADD SECTION" to begin.', 
                        style: TextStyle(color: AppTheme.mutedTextColor.withOpacity(0.5))),
                    ),
                  )
                else
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _sections.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = _sections.removeAt(oldIndex);
                        _sections.insert(newIndex, item);
                      });
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        key: ValueKey('section_$index'),
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildSectionEditor(index, _sections[index]),
                      );
                    },
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading ? null : _save,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.save),
        label: const Text('SAVE PLAN', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          _buildModeOption(
            'REFERENCE ONLY', 
            NutritionPlanMode.referenceOnly, 
            Icons.menu_book,
            'Clients just read the plan'
          ),
          _buildModeOption(
            'WEEKLY ADHERENCE', 
            NutritionPlanMode.weeklyAdherence, 
            Icons.fact_check,
            'Clients check-in weekly'
          ),
        ],
      ),
    );
  }

  Widget _buildModeOption(String label, NutritionPlanMode mode, IconData icon, String subtitle) {
    final bool isSelected = _mode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_mode == mode) return;
          setState(() {
            _mode = mode;
            // Auto-populate 7 days if switching to Weekly Adherence and current sections are empty or default placeholders
            if (_mode == NutritionPlanMode.weeklyAdherence) {
              bool isDefaultOrEmpty = _sections.isEmpty || 
                (_sections.length == 2 && 
                 _sections[0].title == 'Daily Calories' && 
                 _sections[0].content.isEmpty &&
                 _sections[1].title == 'Protein Guidelines' &&
                 _sections[1].content.isEmpty);

              if (isDefaultOrEmpty) {
                _sections = List.generate(7, (i) => NutritionSection(title: 'Day ${i + 1}', content: ''));
              }
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Icon(
                icon, 
                size: 20, 
                color: isSelected ? Colors.black : AppTheme.mutedTextColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.black : AppTheme.mutedTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isSelected ? Colors.black54 : AppTheme.mutedTextColor.withOpacity(0.5),
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor, letterSpacing: 1.2)),
    );
  }

  Widget _buildGoalSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: NutritionGoal.values.map((g) {
        final isSelected = _goal == g;
        return GestureDetector(
          onTap: () => setState(() => _goal = g),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.white10),
            ),
            child: Text(
              g.label.toUpperCase(),
              style: TextStyle(
                color: isSelected ? Colors.black : Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionEditor(int index, NutritionSection section) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_indicator, color: Colors.white24, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  onChanged: (v) {
                    _sections[index] = NutritionSection(title: v, content: section.content);
                  },
                  controller: TextEditingController(text: section.title)..selection = TextSelection.fromPosition(TextPosition(offset: section.title.length)),
                  decoration: const InputDecoration(
                    hintText: 'Section Title (e.g. Protein)',
                    hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: () => _removeSection(index),
              ),
            ],
          ),
          const Divider(color: Colors.white10),
          TextField(
            onChanged: (v) {
              _sections[index] = NutritionSection(title: _sections[index].title, content: v);
            },
            controller: TextEditingController(text: section.content)..selection = TextSelection.fromPosition(TextPosition(offset: section.content.length)),
            maxLines: null,
            decoration: const InputDecoration(
              hintText: 'Enter guidance notes here...',
              hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
              border: InputBorder.none,
            ),
            style: const TextStyle(fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}
