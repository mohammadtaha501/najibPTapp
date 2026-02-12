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
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'PHASE / WEEK',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.mutedTextColor,
            ),
          ),
          TextButton.icon(
            onPressed: _duplicateCurrentWeek,
            icon: const Icon(Icons.copy, size: 14),
            label: const Text(
              'Duplicate to Next Week',
              style: TextStyle(fontSize: 12),
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
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _weeks,
        itemBuilder: (context, index) {
          final week = index + 1;
          final isSelected = _selectedWeek == week;
          return GestureDetector(
            onTap: () => setState(() => _selectedWeek = week),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryColor
                    : AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : Colors.white.withOpacity(0.05),
                ),
              ),
              child: Text(
                'Week $week',
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgramHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'PROGRAM NAME',
            style: TextStyle(
              color: AppTheme.mutedTextColor,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g., Full Body Strength',
                    hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.2),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              Text(
                'Duration (Weeks):',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 60,
                child: TextField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 16,
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
                      vertical: 12,
                      horizontal: 8,
                    ),
                    border: UnderlineInputBorder(
                      borderSide: BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                  onChanged: (val) {
                    final n = int.tryParse(val);
                    if (n != null) {
                      if (n > 20) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Maximum duration is 20 weeks'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                        _durationController.text = '20';
                        _durationController.selection =
                            TextSelection.fromPosition(
                              const TextPosition(offset: 2),
                            );
                        setState(() {
                          _weeks = 20;
                        });
                      } else if (n > 0) {
                        setState(() {
                          _weeks = n;
                          if (_selectedWeek > _weeks) _selectedWeek = _weeks;
                        });
                      }
                    } else {
                      setState(() => _weeks = 0);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // If coming from client detail (preSelectedClientId != null), lock to personal
        if (widget.preSelectedClientId != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock, size: 18, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Creating Personal Program For:',
                        style: TextStyle(
                          color: AppTheme.mutedTextColor,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _clients
                            .firstWhere(
                              (c) => c.uid == widget.preSelectedClientId,
                              orElse: () => AppUser(
                                uid: '',
                                email: '',
                                name: 'Loading...',
                                role: UserRole.client,
                              ),
                            )
                            .name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          // Otherwise, show Dropdown to select type
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _selectedType == null
                    ? Colors.orangeAccent.withOpacity(0.5)
                    : Colors.white10,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ProgramType>(
                value: _selectedType,
                hint: const Text(
                  'Select Program Type',
                  style: TextStyle(color: Colors.orangeAccent),
                ),
                isExpanded: true,
                dropdownColor: AppTheme.surfaceColor,
                items: const [
                  DropdownMenuItem(
                    value: ProgramType.personal,
                    child: Text('For Personal Client'),
                  ),
                  DropdownMenuItem(
                    value: ProgramType.allUsers,
                    child: Text('For All Users'),
                  ),
                  DropdownMenuItem(
                    value: ProgramType.template,
                    child: Text('For Later Use'),
                  ),
                ],
                onChanged: (newValue) {
                  setState(() {
                    if (newValue != null) {
                      _selectedType = newValue;
                      if (_selectedType == ProgramType.personal &&
                          widget.preSelectedClientId != null) {
                        _assignedClientId = widget.preSelectedClientId;
                      } else if (_selectedType != ProgramType.personal) {
                        _assignedClientId = null;
                      }
                    }
                  });
                },
              ),
            ),
          ),

        if (_selectedType == ProgramType.personal &&
            widget.preSelectedClientId == null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _assignedClientId,
                hint: const Text(
                  'Select Client',
                  style: TextStyle(color: AppTheme.mutedTextColor),
                ),
                isExpanded: true,
                dropdownColor: AppTheme.surfaceColor,
                items: _clients.map((client) {
                  return DropdownMenuItem<String>(
                    value: client.uid,
                    child: Text(client.name),
                  );
                }).toList(),
                onChanged: (v) => setState(() => _assignedClientId = v),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDaysList() {
    final filteredDays = _days.where((d) => d.week == _selectedWeek).toList();
    return Column(
      children: filteredDays.asMap().entries.map((entry) {
        final day = entry.value;
        final indexInAll = _days.indexOf(day);
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Day ${day.day}: ${day.muscleGroup}'.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: AppTheme.mutedTextColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 18,
                      color: Colors.white24,
                    ),
                    onPressed: () {
                      setState(() {
                        final removed = _days.removeAt(indexInAll);
                        if (removed.id != null) {
                          _deletedDayIds.add(removed.id!);
                        }
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ..._buildExercisesWithSupersets(day, indexInAll),
              _buildSecondaryButton(
                'Add Exercise',
                () => _addExerciseToDay(indexInAll),
                icon: Icons.add_circle_outline,
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
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.fitness_center,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${e.sets} Sets • ${e.reps} Reps ${e.tempo != null && e.tempo!.isNotEmpty ? "• T: ${e.tempo}" : ""} ${e.rpe != null && e.rpe!.isNotEmpty ? "@ RPE ${e.rpe}" : ""}',
                  style: const TextStyle(
                    color: AppTheme.mutedTextColor,
                    fontSize: 12,
                  ),
                ),
                if (e.targetWeight != null && e.targetWeight!.isNotEmpty)
                  Text(
                    'Target: ${e.targetWeight}',
                    style: const TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                if (e.duration != null && e.duration!.isNotEmpty)
                  Text(
                    'Duration: ${e.duration}',
                    style: const TextStyle(
                      color: Colors.lightBlueAccent,
                      fontSize: 11,
                    ),
                  ),
                if (e.totalReps != null)
                  Text(
                    'Total Reps: ${e.totalReps}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                if (e.volume != null)
                  Text(
                    'Volume: ${e.volume}',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                if (e.note != null && e.note!.isNotEmpty)
                  Text(
                    'Note: ${e.note}',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                if (e.altExercise != null && e.altExercise!.isNotEmpty)
                  Text(
                    'Alt: ${e.altExercise}',
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline,
              size: 20,
              color: Colors.redAccent,
            ),
            onPressed: () =>
                setState(() => _days[dayIndex].exercises.removeAt(exIndex)),
          ),
        ],
      ),
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
  }) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: Theme.of(context).cardTheme.color,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        minimumSize: const Size(double.infinity, 48),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
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
          title: const Text('Add Workout Day'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: muscleGroup,
                items:
                    [
                          'Quadriceps',
                          'Glutes_Hamstrings',
                          'Calves',
                          'Chest',
                          'Back',
                          'Shoulders',
                          'Triceps',
                          'Biceps',
                          'Abs',
                          'Other',
                        ]
                        .map(
                          (g) => DropdownMenuItem(
                            value: g,
                            child: Text(g.replaceAll('_', ' ')),
                          ),
                        )
                        .toList(),
                onChanged: (v) => setDialogState(() => muscleGroup = v!),
                decoration: const InputDecoration(labelText: 'Focus'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _days.add(
                    WorkoutDay(
                      week: week,
                      day: day,
                      muscleGroup: muscleGroup,
                      exercises: [],
                    ),
                  );
                });
                Navigator.pop(context);
              },
              child: const Text('Add'),
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

  @override
  void initState() {
    super.initState();
    _selectedExercises = List.from(widget.initialExercises);
    _exercisesStream = _dbService.getExercises();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Add Exercises',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ExerciseEditorScreen(
                        onExerciseCreated: (newEx) {
                          widget.onSelected([newEx]);
                        },
                      ),
                    ),
                  ).then((_) {
                    if (mounted)
                      Navigator.pop(context); // Close picker after creation
                  });
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New'),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search Exercises...',
              prefixIcon: const Icon(
                Icons.search,
                color: AppTheme.mutedTextColor,
              ),
              filled: true,
              fillColor: Colors.white.withOpacity(0.05),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) =>
                setState(() => _searchQuery = val.toLowerCase()),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: StreamBuilder<List<Exercise>>(
            stream: _exercisesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              final exercises = snapshot.data ?? [];
              final filtered = exercises
                  .where(
                    (e) =>
                        e.name.toLowerCase().contains(_searchQuery) ||
                        e.muscleGroup.toLowerCase().contains(_searchQuery),
                  )
                  .toList();

              if (filtered.isEmpty) {
                return const Center(
                  child: Text(
                    'No exercises found',
                    style: TextStyle(color: AppTheme.mutedTextColor),
                  ),
                );
              }

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final ex = filtered[index];
                  final isSelected = _selectedExercises.any(
                    (selected) => selected.id == ex.id,
                  );
                  return CheckboxListTile(
                    title: Text(
                      ex.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      ex.muscleGroup.replaceAll('_', ' '),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedTextColor,
                      ),
                    ),
                    value: isSelected,
                    activeColor: AppTheme.primaryColor,
                    checkColor: Colors.black,
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
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: ElevatedButton(
            onPressed: _selectedExercises.isEmpty
                ? null
                : () {
                    widget.onSelected(_selectedExercises);
                    Navigator.pop(context);
                  },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
            ),
            child: Text('Add ${_selectedExercises.length} Selected'),
          ),
        ),
      ],
    );
  }
}
