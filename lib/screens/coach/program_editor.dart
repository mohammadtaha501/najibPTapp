import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ptapp/models/exercise_model.dart';
import 'package:ptapp/models/program_model.dart';
import 'package:ptapp/models/user_model.dart';
import 'package:ptapp/services/database_service.dart';
import 'package:ptapp/utils/theme.dart';
import 'package:ptapp/screens/coach/exercise_editor_screen.dart';
import 'dart:async';

enum ProgramType { personal, allUsers, template }

class ProgramEditor extends StatefulWidget {
  final String coachId;
  final String? preSelectedClientId;
  final Program? programToEdit;
  const ProgramEditor({
    super.key,
    required this.coachId,
    this.preSelectedClientId,
    this.programToEdit,
  });

  @override
  State<ProgramEditor> createState() => _ProgramEditorState();
}

class _ProgramEditorState extends State<ProgramEditor> {
  final _dbService = DatabaseService();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController(text: '1');
  int _weeks = 1;
  int _selectedWeek = 1;
  ProgramType? _selectedType;
  String? _assignedClientId;
  List<AppUser> _clients = [];
  List<WorkoutDay> _days = [];
  final List<String> _deletedDayIds = [];
  StreamSubscription? _clientsSubscription;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadClients();
    if (widget.programToEdit != null) {
      final p = widget.programToEdit!;
      _nameController.text = p.name;
      _weeks = p.totalWeeks;
      _durationController.text = p.totalWeeks.toString();
      _assignedClientId = p.assignedClientId;
      if (p.isTemplate) {
        _selectedType = ProgramType.template;
      } else if (p.isPublic) {
        _selectedType = ProgramType.allUsers;
      } else {
        _selectedType = ProgramType.personal;
      }
      _loadProgramDays(p.id!);
    } else if (widget.preSelectedClientId != null) {
      _assignedClientId = widget.preSelectedClientId;
      _selectedType = ProgramType.personal;
    }
  }

  void _loadProgramDays(String programId) {
    _dbService.getProgramDays(programId).first.then((days) {
      if (mounted) {
        setState(() => _days = days);
      }
    });
  }

  void _loadClients() {
    _clientsSubscription = _dbService.getClients(widget.coachId).listen((
      clients,
    ) {
      if (mounted) {
        setState(() {
          _clients = clients;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _clientsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          widget.programToEdit == null ? 'Program Builder' : 'Edit Program',
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildProgramHeader(),
                    const SizedBox(height: 16),
                    _buildWeekPickerHeader(),
                    _buildWeekPicker(),
                    const SizedBox(height: 24),
                    _buildDaysList(),
                    const SizedBox(height: 16),
                    _buildSecondaryButton(
                      'Add Workout Day to Week $_selectedWeek',
                      _addNewDay,
                      icon: Icons.add,
                      color: Colors.cyanAccent,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryColor),
                    SizedBox(height: 16),
                    Text(
                      'Saving Program...',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          border: Border.all(color: Colors.white.withOpacity(0.05)),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _saveProgram,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            _isLoading
                ? 'SAVING...'
                : (widget.programToEdit == null
                      ? 'CREATE PROGRAM'
                      : 'SAVE CHANGES'),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildWeekPickerHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 32, 4, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PHASE PROGRESSION',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.mutedTextColor,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Select Training Week',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          InkWell(
            onTap: _duplicateCurrentWeek,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.copy_all_rounded,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'DUPLICATE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _duplicateCurrentWeek() {
    if (_selectedWeek >= _weeks) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot duplicate to next week (limit reached).'),
        ),
      );
      return;
    }
    final nextWeek = _selectedWeek + 1;
    final currentWeekDays = _days
        .where((d) => d.week == _selectedWeek)
        .toList();

    setState(() {
      for (var day in currentWeekDays) {
        _days.add(
          WorkoutDay(
            week: nextWeek,
            day: day.day,
            muscleGroup: day.muscleGroup,
            exercises: day.exercises
                .map(
                  (e) => Exercise(
                    name: e.name,
                    description: e.description,
                    muscleGroup: e.muscleGroup,
                    sets: e.sets,
                    reps: e.reps,
                    restTime: e.restTime,
                    videoUrl: e.videoUrl,
                    duration: e.duration,
                    rpe: e.rpe,
                    altExercise: e.altExercise,
                    supersetLabel: e.supersetLabel,
                    tempo: e.tempo,
                    targetWeight: e.targetWeight,
                    totalReps: e.totalReps,
                    volume: e.volume,
                    note: e.note,
                  ),
                )
                .toList(),
          ),
        );
      }
      _selectedWeek = nextWeek;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Week $_selectedWeek duplicated to Week $nextWeek'),
      ),
    );
  }

  Widget _buildWeekPicker() {
    return SizedBox(
      height: 54,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        itemCount: _weeks,
        itemBuilder: (context, index) {
          final week = index + 1;
          final isSelected = _selectedWeek == week;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: InkWell(
              onTap: () => setState(() => _selectedWeek = week),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 24),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.white.withOpacity(0.05),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [],
                ),
                child: Text(
                  'Week $week',
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white60,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgramHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'PROGRAM IDENTITY',
                      style: TextStyle(
                        color: AppTheme.mutedTextColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      decoration: InputDecoration(
                        hintText: 'e.g., Full Body Strength',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.2),
                          fontSize: 18,
                        ),
                        filled: true,
                        fillColor: Colors.black.withOpacity(0.3),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInputBox(
            label: 'PLAN DURATION',
            icon: Icons.calendar_today_rounded,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(2),
                    ],
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 12,
                      ),
                    ),
                    onChanged: (val) {
                      final n = int.tryParse(val);
                      if (n != null) {
                        if (n > 20) {
                          setState(() {
                            _weeks = 20;
                            _durationController.text = '20';
                            _durationController.selection =
                                TextSelection.fromPosition(
                                  TextPosition(
                                    offset: _durationController.text.length,
                                  ),
                                );
                            if (_selectedWeek > 20) _selectedWeek = 20;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Plan duration cannot be more than 20 weeks',
                              ),
                              backgroundColor: AppTheme.errorColor,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else if (n > 0) {
                          setState(() {
                            _weeks = n;
                            if (_selectedWeek > _weeks) _selectedWeek = _weeks;
                          });
                        }
                      }
                    },
                  ),
                ),
                const Text(
                  'Weeks',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedTextColor,
                  ),
                ),
              ],
            ),
          ),
          if (_selectedType == ProgramType.personal) ...[
            const SizedBox(height: 12),
            _buildInputBox(
              label: 'CLIENT ASSIGNMENT',
              icon: Icons.person_add_alt_1_rounded,
              child: widget.preSelectedClientId != null
                  ? Text(
                      _clients
                          .firstWhere(
                            (c) => c.uid == widget.preSelectedClientId,
                            orElse: () => AppUser(
                              uid: '',
                              email: '',
                              name: 'Client',
                              role: UserRole.client,
                            ),
                          )
                          .name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                      maxLines: 1,
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _assignedClientId,
                        hint: const Text(
                          'Pick Client',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.mutedTextColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        isExpanded: true,
                        icon: const Icon(
                          Icons.arrow_drop_down_rounded,
                          color: AppTheme.primaryColor,
                        ),
                        dropdownColor: AppTheme.surfaceColor,
                        items: _clients
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.uid,
                                child: Text(
                                  c.name,
                                  style: const TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _assignedClientId = v),
                      ),
                    ),
            ),
          ],
          const SizedBox(height: 12),
          _buildInputBox(
            label: 'PROGRAM ACCESSIBILITY',
            icon: widget.preSelectedClientId != null
                ? Icons.lock_rounded
                : Icons.visibility_rounded,
            child: widget.preSelectedClientId != null
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(
                      'Personal Program (Locked)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white70,
                      ),
                    ),
                  )
                : DropdownButtonHideUnderline(
                    child: DropdownButton<ProgramType>(
                      value: _selectedType,
                      hint: const Text(
                        'Select visibility for this program...',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.mutedTextColor,
                        ),
                      ),
                      isExpanded: true,
                      icon: const Icon(
                        Icons.arrow_drop_down_rounded,
                        color: AppTheme.primaryColor,
                      ),
                      dropdownColor: AppTheme.surfaceColor,
                      items: const [
                        DropdownMenuItem(
                          value: ProgramType.personal,
                          child: Text(
                            'Personal Program (Client Specific)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: ProgramType.allUsers,
                          child: Text(
                            'Public Program (All Clients)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        DropdownMenuItem(
                          value: ProgramType.template,
                          child: Text(
                            'Private Template (Internal Use)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() {
                          _selectedType = v;
                          if (_selectedType != ProgramType.personal)
                            _assignedClientId = null;
                        });
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBox({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppTheme.mutedTextColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.mutedTextColor,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildDaysList() {
    final filteredDays = _days.where((d) => d.week == _selectedWeek).toList();
    return Column(
      children: filteredDays.asMap().entries.map((entry) {
        final day = entry.value;
        final indexInAll = _days.indexOf(day);
        return Padding(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.flash_on_rounded,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'DAY ${day.day}: ${day.muscleGroup}'.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_sweep_rounded,
                        size: 20,
                        color: Colors.redAccent,
                      ),
                      onPressed: () {
                        setState(() {
                          final removed = _days.removeAt(indexInAll);
                          if (removed.id != null)
                            _deletedDayIds.add(removed.id!);
                        });
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ..._buildExercisesWithSupersets(day, indexInAll),
              const SizedBox(height: 8),
              _buildSecondaryButton(
                'Add Exercise to Training',
                () => _addExerciseToDay(indexInAll),
                icon: Icons.add_circle_outline_rounded,
                color: Colors.orangeAccent,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWorkoutExerciseCard(Exercise e, int dayIndex, int exIndex) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.fitness_center_rounded,
              color: AppTheme.primaryColor,
              size: 20,
            ),
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
                        e.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(
                        () => _days[dayIndex].exercises.removeAt(exIndex),
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.remove_rounded,
                          size: 16,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: [
                    _buildExerciseDetailTag(
                      Icons.repeat_rounded,
                      '${e.sets} Sets',
                    ),
                    _buildExerciseDetailTag(
                      Icons.timer_outlined,
                      '${e.reps} Reps',
                    ),
                    if (e.tempo != null && e.tempo!.isNotEmpty)
                      _buildExerciseDetailTag(
                        Icons.speed_rounded,
                        'Tempo: ${e.tempo}',
                      ),
                    if (e.rpe != null && e.rpe!.isNotEmpty)
                      _buildExerciseDetailTag(
                        Icons.bolt_rounded,
                        'RPE ${e.rpe}',
                        color: Colors.orangeAccent,
                      ),
                  ],
                ),
                if (e.targetWeight != null && e.targetWeight!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Target: ${e.targetWeight}',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
                if (e.note != null && e.note!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      e.note!,
                      style: const TextStyle(
                        color: AppTheme.mutedTextColor,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseDetailTag(
    IconData icon,
    String label, {
    Color color = AppTheme.mutedTextColor,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color.withOpacity(0.7)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildExercisesWithSupersets(WorkoutDay day, int dayIndex) {
    List<Widget> list = [];
    String? currentSuperset;

    for (var i = 0; i < day.exercises.length; i++) {
      final e = day.exercises[i];
      if (e.supersetLabel != null &&
          e.supersetLabel!.isNotEmpty &&
          e.supersetLabel != currentSuperset) {
        currentSuperset = e.supersetLabel;
        list.add(
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            child: Row(
              children: [
                const Icon(Icons.link, size: 14, color: AppTheme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  currentSuperset!.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        );
      } else if (e.supersetLabel == null || e.supersetLabel!.isEmpty) {
        currentSuperset = null;
      }
      list.add(_buildWorkoutExerciseCard(e, dayIndex, i));
    }
    return list;
  }

  Widget _buildSecondaryButton(
    String label,
    VoidCallback onTap, {
    IconData? icon,
    Color color = AppTheme.primaryColor,
  }) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
              ],
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addNewDay() {
    int week = _selectedWeek;
    int day = _days.where((d) => d.week == week).length + 1;
    String muscleGroup = 'Quadriceps';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          title: const Text(
            'Add Workout Day',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Which muscle group is the focus for this day?',
                style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: muscleGroup,
                    isExpanded: true,
                    dropdownColor: AppTheme.surfaceColor,
                    onChanged: (v) => setDialogState(() => muscleGroup = v!),
                    items: Exercise.muscleGroups
                        .map(
                          (g) => DropdownMenuItem(
                            value: g,
                            child: Text(
                              g.replaceAll('_', ' '),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.mutedTextColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(
                  () => _days.add(
                    WorkoutDay(
                      week: week,
                      day: day,
                      muscleGroup: muscleGroup,
                      exercises: [],
                    ),
                  ),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'ADD DAY',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addExerciseToDay(int dayIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: _ExercisePicker(
          initialExercises: _days[dayIndex].exercises,
          onSelected: (selectedExercises) {
            setState(() {
              // Keep existing configured exercises that are still in the selection
              final existing = _days[dayIndex].exercises
                  .where(
                    (oldEx) => selectedExercises.any(
                      (newEx) => newEx.name == oldEx.name,
                    ),
                  )
                  .toList();

              // Add new exercises from the picker that aren't in the day yet
              final newlyAdded = selectedExercises
                  .where(
                    (newEx) => !_days[dayIndex].exercises.any(
                      (oldEx) => oldEx.name == newEx.name,
                    ),
                  )
                  .toList();

              _days[dayIndex].exercises.clear();
              _days[dayIndex].exercises.addAll([...existing, ...newlyAdded]);
            });
          },
        ),
      ),
    );
  }

  void _saveProgram() async {
    if (_nameController.text.isEmpty || _days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a name and add at least one day.'),
        ),
      );
      return;
    }

    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a program type.')),
      );
      return;
    }

    if (_selectedType == ProgramType.personal && _assignedClientId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a client for this personal program.'),
        ),
      );
      return;
    }

    final isTemplate = _selectedType == ProgramType.template;
    final isPublic = _selectedType == ProgramType.allUsers;
    final assignedId = _selectedType == ProgramType.personal
        ? _assignedClientId
        : null;

    final program = Program(
      id: widget.programToEdit?.id,
      name: _nameController.text.trim(),
      coachId: widget.coachId,
      isTemplate: isTemplate,
      isPublic: isPublic,
      totalWeeks: _weeks,
      assignedClientId: assignedId,
      startDate: assignedId != null
          ? (widget.programToEdit?.startDate ?? DateTime.now())
          : null,
      createdForClientId:
          assignedId ?? widget.programToEdit?.createdForClientId,
    );

    // If editing a PUBLIC program, ask for update mode
    if (widget.programToEdit != null &&
        widget.programToEdit!.isPublic &&
        isPublic) {
      final bool? applyGlobally = await _showGlobalUpdateDialog();
      if (applyGlobally == null) return; // Cancelled

      setState(() => _isLoading = true);
      try {
        if (applyGlobally) {
          await _dbService.applyGlobalUpdate(program, _days);
        } else {
          // Duplicate into personal means create a NEW personal copy
          // We'll need a client for this. Let's ask or use a default.
          // For simplicity, if they choose duplicate, we ask them to select a client or just save as a new personal program.
          // But the user's requirement says "duplicate it into a personal programme".
          // I'll show a client picker if needed.
          final String? targetClientId =
              await _showClientPickerForDuplication();
          if (targetClientId == null) {
            setState(() => _isLoading = false);
            return;
          }
          await _dbService.createProgramCopy(
            program.id!,
            targetClientId,
            DateTime.now(),
          );
        }
        if (mounted) Navigator.pop(context);
        return;
      } catch (e) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
    }

    setState(() => _isLoading = true);
    try {
      String progId;
      if (widget.programToEdit != null) {
        progId = widget.programToEdit!.id!;
        await _dbService.updateProgram(program);

        // Identify and prune days that exceed the new duration
        final orphanedDays = _days.where((d) => d.week > _weeks).toList();
        for (var day in orphanedDays) {
          if (day.id != null) {
            _deletedDayIds.add(day.id!);
          }
        }
        _days.removeWhere((d) => d.week > _weeks);

        // Handle deletions
        for (var dayId in _deletedDayIds) {
          await _dbService.deleteWorkoutDay(progId, dayId);
        }

        // Update/Add days
        for (var day in _days) {
          if (day.id != null) {
            await _dbService.updateWorkoutDay(progId, day);
          } else {
            await _dbService.addWorkoutDay(progId, day);
          }
        }
      } else {
        progId = await _dbService.createProgram(program);
        for (var day in _days) {
          await _dbService.addWorkoutDay(progId, day);
        }
      }

      // Notify client if it's a personal program
      if (assignedId != null) {
        await _dbService.sendPushNotification(
          recipientId: assignedId,
          title: 'New Program Assigned',
          body:
              'Your coach has assigned you a new program: ${_nameController.text.trim()}. Tap to view.',
          data: {'type': 'new_program'},
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.programToEdit == null
                  ? 'Program created!'
                  : 'Program updated!',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving program: $e')));
      }
    }
  }

  Future<bool?> _showGlobalUpdateDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Save Public Program',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Do you want to apply these changes to all clients currently assigned to this program, or duplicate this into a new personal program for a specific client?',
          style: TextStyle(color: AppTheme.mutedTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'APPLY GLOBALLY',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'DUPLICATE TO PERSONAL',
              style: TextStyle(color: Colors.orangeAccent),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: AppTheme.mutedTextColor),
            ),
          ),
        ],
      ),
    );
  }

  Future<String?> _showClientPickerForDuplication() async {
    String? selectedId;
    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text(
            'Select Client',
            style: TextStyle(color: Colors.white),
          ),
          content: DropdownButton<String>(
            value: selectedId,
            hint: const Text(
              'Choose Client',
              style: TextStyle(color: AppTheme.mutedTextColor),
            ),
            isExpanded: true,
            dropdownColor: AppTheme.surfaceColor,
            items: _clients
                .map((c) => DropdownMenuItem(value: c.uid, child: Text(c.name)))
                .toList(),
            onChanged: (v) => setDialogState(() => selectedId = v),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedId == null
                  ? null
                  : () => Navigator.pop(context, selectedId),
              child: const Text('Duplicate'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExercisePicker extends StatefulWidget {
  final List<Exercise> initialExercises;
  final Function(List<Exercise>) onSelected;
  const _ExercisePicker({
    required this.onSelected,
    required this.initialExercises,
  });

  @override
  State<_ExercisePicker> createState() => _ExercisePickerState();
}

class _ExercisePickerState extends State<_ExercisePicker> {
  final _dbService = DatabaseService();
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<Exercise> _selectedExercises = [];
  late Stream<List<Exercise>> _exercisesStream;

  // Filter states
  String? _selectedMuscleGroup;
  int? _selectedSets;
  String? _selectedReps;

  @override
  void initState() {
    super.initState();
    _selectedExercises = List.from(widget.initialExercises);
    _exercisesStream = _dbService.getExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'LIBRARY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryColor,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'Select Exercises',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExerciseEditorScreen(
                        onExerciseCreated: (newEx) {
                          widget.onSelected([..._selectedExercises, newEx]);
                        },
                      ),
                    ),
                  ).then((_) {
                    if (mounted) Navigator.pop(context);
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            controller: _searchController,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Search movement library...',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppTheme.mutedTextColor,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) =>
                setState(() => _searchQuery = val.toLowerCase()),
          ),
        ),
        const SizedBox(height: 16),
        // Muscle Group Filters
        SizedBox(
          height: 38,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            itemCount: Exercise.muscleGroups.length + 1,
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final group = isAll ? null : Exercise.muscleGroups[index - 1];
              final isSelected = _selectedMuscleGroup == group;
              final label = isAll ? 'All' : group!.replaceAll('_', ' ');

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedMuscleGroup = selected ? group : null;
                    });
                  },
                  backgroundColor: Colors.white.withOpacity(0.05),
                  selectedColor: AppTheme.primaryColor.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color: isSelected ? AppTheme.primaryColor : Colors.white60,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected
                          ? AppTheme.primaryColor.withOpacity(0.5)
                          : Colors.transparent,
                    ),
                  ),
                  showCheckmark: false,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Sets and Reps Quick Filters
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              _buildDropdownFilter<int>(
                label: 'Sets',
                value: _selectedSets,
                items: [1, 2, 3, 4, 5],
                onChanged: (v) => setState(() => _selectedSets = v),
              ),
              const SizedBox(width: 12),
              _buildDropdownFilter<String>(
                label: 'Reps',
                value: _selectedReps,
                items: ['5', '8', '10', '12', '15', '20'],
                onChanged: (v) => setState(() => _selectedReps = v),
              ),
              const Spacer(),
              if (_selectedMuscleGroup != null ||
                  _selectedSets != null ||
                  _selectedReps != null)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedMuscleGroup = null;
                      _selectedSets = null;
                      _selectedReps = null;
                    });
                  },
                  child: const Text(
                    'CLEAR FILTERS',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: StreamBuilder<List<Exercise>>(
            stream: _exercisesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              final exercises = snapshot.data ?? [];

              final filtered = exercises.where((e) {
                // Search query match
                final nameMatch =
                    e.name.toLowerCase().contains(_searchQuery) ||
                    e.muscleGroup.toLowerCase().contains(_searchQuery);

                // Muscle group filter
                final muscleMatch =
                    _selectedMuscleGroup == null ||
                    e.muscleGroup == _selectedMuscleGroup;

                // Sets filter
                final setsMatch =
                    _selectedSets == null || e.sets == _selectedSets;

                // Reps filter
                final repsMatch =
                    _selectedReps == null || e.reps == _selectedReps;

                return nameMatch && muscleMatch && setsMatch && repsMatch;
              }).toList();

              if (filtered.isEmpty)
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 48,
                        color: Colors.white12,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No results found',
                        style: TextStyle(color: AppTheme.mutedTextColor),
                      ),
                    ],
                  ),
                );

              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final ex = filtered[index];
                  final isSelected = _selectedExercises.any(
                    (selected) => selected.id == ex.id,
                  );
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryColor.withOpacity(0.05)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: CheckboxListTile(
                      title: Text(
                        ex.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppTheme.primaryColor
                              : Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        '${ex.muscleGroup.replaceAll('_', ' ')} • ${ex.sets ?? "-"} Sets • ${ex.reps ?? "-"} Reps',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedTextColor,
                        ),
                      ),
                      value: isSelected,
                      activeColor: AppTheme.primaryColor,
                      checkColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            _selectedExercises.add(ex);
                          } else {
                            _selectedExercises.removeWhere(
                              (selected) => selected.id == ex.id,
                            );
                          }
                        });
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.05)),
            ),
          ),
          child: ElevatedButton(
            onPressed: _selectedExercises.isEmpty
                ? null
                : () {
                    widget.onSelected(_selectedExercises);
                    Navigator.pop(context);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'ADD ${_selectedExercises.length} EXERCISES'.toUpperCase(),
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownFilter<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value != null
              ? AppTheme.primaryColor.withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.white60),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, size: 16),
          style: const TextStyle(fontSize: 12, color: Colors.white),
          dropdownColor: AppTheme.surfaceColor,
          items: [
            DropdownMenuItem<T>(value: null, child: Text('Any $label')),
            ...items.map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(item.toString()),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
