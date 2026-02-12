import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled3/models/program_model.dart';
import 'package:untitled3/models/user_model.dart';
import 'package:untitled3/models/nutrition_checkin_model.dart';
import 'package:untitled3/services/database_service.dart';
import 'package:untitled3/utils/theme.dart';
import 'package:untitled3/widgets/common_widgets.dart';
import 'package:untitled3/screens/common/chat_screen.dart';
import 'package:untitled3/screens/coach/nutrition_management_screen.dart';
import 'package:untitled3/screens/coach/program_editor.dart';
import 'package:untitled3/screens/coach/program_report_screen.dart';
import 'package:intl/intl.dart';

class ClientDetailScreen extends StatefulWidget {
  final AppUser client;
  const ClientDetailScreen({super.key, required this.client});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

enum _ToggleView { training, nutrition }

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  _ToggleView _activeView = _ToggleView.training;
  final _dbService = DatabaseService();
  late Stream<int> _unreadCountStream;
  late Stream<List<Program>> _programHistoryStream;
  late Stream<List<WeeklyNutritionCheckIn>> _nutritionHistoryStream;

  @override
  void initState() {
    super.initState();
    _unreadCountStream = _dbService.getUnreadCount(widget.client.uid, widget.client.coachId ?? '');
    _programHistoryStream = _dbService.getClientPrograms(widget.client.uid);
    _nutritionHistoryStream = _dbService.getWeeklyCheckInHistory(widget.client.uid);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: Text(widget.client.name.toUpperCase())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(context),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAssignProgramDialog(context, _dbService),
              icon: const Icon(Icons.add),
              label: const Text('Assign New Program'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: StreamBuilder<int>(
                    stream: _unreadCountStream,
                    builder: (context, snapshot) {
                      final count = snapshot.data ?? 0;
                      return ElevatedButton.icon(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatScreen(
                          currentUserId: widget.client.coachId ?? '',
                          otherUserId: widget.client.uid,
                          otherUserName: widget.client.name,
                        ))),
                        icon: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            const Icon(Icons.chat),
                            if (count > 0)
                              Positioned(
                                right: -8,
                                top: -8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                                  child: Text('$count', style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
                                ),
                              ),
                          ],
                        ),
                        label: const Text('Chat'),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NutritionManagementScreen(
                      clientId: widget.client.uid,
                      clientName: widget.client.name,
                    ))),
                    icon: const Icon(Icons.restaurant),
                    label: const Text('Nutrition'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildViewToggle(),
            const SizedBox(height: 16),
            if (_activeView == _ToggleView.training) ...[
              _buildProgramHistory(_dbService),
            ] else ...[
              _buildNutritionHistory(_dbService),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          _buildToggleOption(
            'TRAINING LOGS', 
            _ToggleView.training, 
            Icons.fitness_center,
          ),
          _buildToggleOption(
            'NUTRITION LOGS', 
            _ToggleView.nutrition, 
            Icons.restaurant,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleOption(String label, _ToggleView view, IconData icon) {
    final bool isSelected = _activeView == view;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeView = view),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon, 
                size: 16, 
                color: isSelected ? Colors.black : AppTheme.mutedTextColor,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : AppTheme.mutedTextColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Widget _buildProfileCard(BuildContext context) {
    return CustomCard(
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: widget.client.isBlocked ? Colors.red.withOpacity(0.2) : AppTheme.primaryColor.withOpacity(0.2),
                child: Text(widget.client.name[0].toUpperCase(), style: TextStyle(fontSize: 24, color: widget.client.isBlocked ? Colors.red : Colors.white)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.client.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(widget.client.email, style: const TextStyle(color: AppTheme.mutedTextColor)),
                  ],
                ),
              ),
              if (widget.client.isBlocked)
                const Chip(label: Text('BLOCKED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)), backgroundColor: Colors.red),
            ],
          ),
          const Divider(height: 32, color: Colors.white10),
          const Divider(height: 32, color: Colors.white10),
          Row(
            children: [
              Expanded(
                child: _buildAdminButton(
                  context, 
                  'Reset PW', 
                  Icons.lock_reset,
                  Colors.blue,
                  () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Send Password Reset?'),
                        content: Text('Send a password reset email to ${widget.client.email}?'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(c, true), 
                            child: const Text('Send'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.client.email);
                        if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password reset email sent')));
                      } catch (e) {
                         if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  }
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAdminButton(
                  context, 
                  widget.client.isBlocked ? 'Unblock' : 'Block', 
                  widget.client.isBlocked ? Icons.lock_open : Icons.block,
                  widget.client.isBlocked ? Colors.green : Colors.orange,
                  () async {
                    final db = DatabaseService();
                    await db.toggleBlockClient(widget.client.uid, !widget.client.isBlocked);
                    if (context.mounted) Navigator.pop(context); // Minimal feedback for this version
                  }
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildAdminButton(
                  context, 
                  'Delete', 
                  Icons.delete_forever,
                  Colors.red,
                  () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (c) => AlertDialog(
                        title: const Text('Delete Client?'),
                        content: const Text('This action is permanent and cannot be undone.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                          ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Delete')),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      final db = DatabaseService();
                      await db.deleteClient(widget.client.uid);
                      if (context.mounted) Navigator.pop(context);
                    }
                  }
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdminButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }




  void _showAssignProgramDialog(BuildContext context, DatabaseService dbService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Assign Program', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            
            // Option 1: Create New Specific Program
            InkWell(
              onTap: () {
                Navigator.pop(context); // Close sheet
                Navigator.push(context, MaterialPageRoute(builder: (_) => ProgramEditor(
                  coachId: widget.client.coachId ?? FirebaseAuth.instance.currentUser!.uid,
                  preSelectedClientId: widget.client.uid,
                )));
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primaryColor),
                  borderRadius: BorderRadius.circular(12),
                  color: AppTheme.primaryColor.withOpacity(0.1),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Create New Private Program', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                        Text('Build a specific plan just for ${'this client'}', style: TextStyle(fontSize: 12, color: AppTheme.mutedTextColor)),
                      ],
                    )
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            const Text('OR Select from Templates', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            
            Expanded(
              child: StreamBuilder<List<Program>>(
                // Fetch ONLY templates created by this coach
                stream: dbService.getProgramTemplates(widget.client.coachId ?? FirebaseAuth.instance.currentUser!.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final programs = snapshot.data ?? [];
                  
                  if (programs.isEmpty) {
                    return const Center(child: Text('No templates found. Create one from your dashboard.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.mutedTextColor)));
                  }

                  return ListView.separated(
                    itemCount: programs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final p = programs[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${p.totalWeeks} Weeks • Template', style: const TextStyle(fontSize: 12, color: AppTheme.mutedTextColor)),
                          trailing: const Icon(Icons.copy, size: 20, color: Colors.white54),
                          onTap: () => _confirmAssignTemplate(context, dbService, p),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAssignTemplate(BuildContext context, DatabaseService dbService, Program template) {
    DateTime selectedDate = DateTime.now();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Assign "${template.name}"?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This will create a copy of the template assigned to this client.'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Start Date:'),
                  TextButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 30)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setState(() => selectedDate = picked);
                    },
                    child: Text(selectedDate.toString().split(' ')[0]),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close confirm
                Navigator.pop(context); // Close bottom sheet
                
                await dbService.createProgramCopy(template.id!, widget.client.uid, selectedDate);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Program assigned successfully')));
                }
              },
              child: const Text('Assign'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramHistory(DatabaseService dbService) {
    return StreamBuilder<List<Program>>(
      stream: _programHistoryStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
        final programs = snapshot.data ?? [];
        if (programs.isEmpty) return const Text('No program history found.', style: TextStyle(color: AppTheme.mutedTextColor));
        
        return Column(
          children: programs.map((p) => _buildProgramHistoryCard(context, dbService, p)).toList(),
        );
      },
    );
  }

  Widget _buildProgramHistoryCard(BuildContext context, DatabaseService dbService, Program program) {
    final bool isActive = program.status == ProgramStatus.active;
    final bool isAssigned = program.status == ProgramStatus.assigned;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isActive ? AppTheme.primaryColor.withOpacity(0.3) : Colors.white.withOpacity(0.05)),
      ),
      child: ListTile(
        onTap: isAssigned ? null : () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProgramReportScreen(program: program, client: widget.client),
            ),
          );
        },
        title: Row(
          children: [
            Expanded(child: Text(program.name, style: const TextStyle(fontWeight: FontWeight.bold))),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppTheme.primaryColor, width: 0.5),
                ),
                child: const Text('STARTED', style: TextStyle(color: AppTheme.primaryColor, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
          ],
        ),
        subtitle: Text(
          isAssigned
            ? 'NOT STARTED YET'
            : '${program.totalWeeks} Weeks • ${program.status.name.toUpperCase()}',
          style: TextStyle(
            color: isActive ? AppTheme.primaryColor : (isAssigned ? Colors.orange : AppTheme.mutedTextColor),
            fontSize: 12,
            fontWeight: isAssigned ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.white54),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ProgramEditor(
                  coachId: widget.client.coachId ?? FirebaseAuth.instance.currentUser!.uid,
                  programToEdit: program,
                ))
              ),
            ),
            IconButton(
              icon: Icon(Icons.note_add_outlined, size: 20, color: program.coachNotes != null ? AppTheme.primaryColor : Colors.white54),
              onPressed: () => _showProgramNotesDialog(context, dbService, program),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
              onPressed: () => _confirmDeleteProgram(context, dbService, program),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteProgram(BuildContext context, DatabaseService dbService, Program program) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Delete Program?', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete "${program.name}"?', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 12),
            const Text(
              'WARNING: This will permanently delete the program, all workout logs, and all progress data for this client.',
              style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.mutedTextColor)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await dbService.deleteProgramCompletely(program.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Program and all associated data deleted.')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting program: $e')));
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('DELETE PERMANENTLY', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showProgramNotesDialog(BuildContext context, DatabaseService dbService, Program program) {
    final controller = TextEditingController(text: program.coachNotes);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Coach Notes: ${program.name}'),
        content: TextField(
          controller: controller,
          maxLines: 5,
          decoration: const InputDecoration(hintText: 'Enter notes about the client\'s performance, adjustments, etc.'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await dbService.updateProgramCoachNotes(program.id!, controller.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save Notes'),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionHistory(DatabaseService dbService) {
    return Column(
      children: [
        StreamBuilder<List<WeeklyNutritionCheckIn>>(
          stream: _nutritionHistoryStream,
          builder: (context, snapshot) {
            final history = snapshot.data ?? [];
            if (history.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Text(
                    'No weekly check-ins submitted yet.',
                    style: TextStyle(color: AppTheme.mutedTextColor.withOpacity(0.5)),
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...history.map((checkin) => _buildWeeklyCheckInLogCard(checkin)),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildWeeklyCheckInLogCard(WeeklyNutritionCheckIn checkin) {
    final dateStr = DateFormat('MMM dd, yyyy').format(checkin.weekStartDate);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.1)),
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
            'Submitted on ${DateFormat('MMM dd, yyyy').format(checkin.createdAt)}',
            style: TextStyle(color: AppTheme.mutedTextColor.withOpacity(0.5), fontSize: 10, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
