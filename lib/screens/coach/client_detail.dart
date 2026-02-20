import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:ptapp/models/program_model.dart';
import 'package:provider/provider.dart';
import 'package:ptapp/providers/auth_provider.dart';
import 'package:ptapp/models/user_model.dart';
import 'package:ptapp/models/nutrition_checkin_model.dart';
import 'package:ptapp/services/database_service.dart';
import 'package:ptapp/utils/theme.dart';
import 'package:ptapp/screens/common/chat_screen.dart';
import 'package:ptapp/screens/coach/nutrition_management_screen.dart';
import 'package:ptapp/screens/coach/program_editor.dart';
import 'package:intl/intl.dart';
import 'package:ptapp/screens/coach/program_report_screen.dart';

import '../../services/auth_service.dart';

class ClientDetailScreen extends StatefulWidget {
  final AppUser client;
  const ClientDetailScreen({super.key, required this.client});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

enum _ToggleView { training, nutrition, assessment }

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  _ToggleView _activeView = _ToggleView.training;
  final _dbService = DatabaseService();
  late Stream<int> _unreadCountStream;
  late Stream<List<Program>> _programHistoryStream;
  late Stream<List<WeeklyNutritionCheckIn>> _nutritionHistoryStream;
  late AppUser _client;

  @override
  void initState() {
    super.initState();
    _client = widget.client;
    _unreadCountStream = _dbService.getUnreadCount(
      _client.uid,
      _client.coachId ?? '',
    );
    _programHistoryStream = _dbService.getClientPrograms(_client.uid);
    _nutritionHistoryStream = _dbService.getWeeklyCheckInHistory(_client.uid);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_client.name.toUpperCase())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileCard(context),
            _buildMainActionBanner(context),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildQuickAction(
                  context: context,
                  label: 'CHAT',
                  icon: Icons.chat_bubble_outline_rounded,
                  color: AppTheme.primaryColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        currentUserId: _client.coachId ?? '',
                        otherUserId: _client.uid,
                        otherUserName: _client.name,
                      ),
                    ),
                  ),
                  showBadge: true,
                ),
                const SizedBox(width: 12),
                _buildQuickAction(
                  context: context,
                  label: 'NUTRITION',
                  icon: Icons.restaurant_menu_rounded,
                  color: Colors.pinkAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => NutritionManagementScreen(
                        clientId: _client.uid,
                        clientName: _client.name,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildViewToggle(),
            const SizedBox(height: 24),
            if (_activeView == _ToggleView.training) ...[
              _buildProgramActiveOverview(_dbService),
              const SizedBox(height: 24),
              _buildTrainingStatsGrid(_dbService),
              const SizedBox(height: 32),
              const Text(
                'PROGRAM HISTORY',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.mutedTextColor,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              _buildProgramHistory(_dbService),
            ] else if (_activeView == _ToggleView.nutrition) ...[
              _buildNutritionHistory(_dbService),
            ] else ...[
              _buildAssessmentView(),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMainActionBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor.withOpacity(0.15), Colors.transparent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.add_task_rounded,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Training Program',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Assign a custom workout template',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => _showAssignProgramDialog(context, _dbService),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    Color(0xFFC0FF00),
                  ], // Vivid neon green gradient
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 0.5,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bolt_rounded, color: Colors.black, size: 18),
                  SizedBox(width: 6),
                  Text(
                    'ASSIGN',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 0.8,
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

  Widget _buildQuickAction({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool showBadge = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color, size: 28),
                  if (showBadge)
                    StreamBuilder<int>(
                      stream: _unreadCountStream,
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        if (count <= 0) return const SizedBox.shrink();
                        return Positioned(
                          right: -4,
                          top: -4,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.redAccent,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              '$count',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  color: color.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildToggleOption(
            'TRAINING',
            _ToggleView.training,
            Icons.fitness_center_rounded,
          ),
          _buildToggleOption(
            'NUTRITION',
            _ToggleView.nutrition,
            Icons.restaurant_rounded,
          ),
          _buildToggleOption(
            'ASSESS',
            _ToggleView.assessment,
            Icons.analytics_outlined,
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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
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
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: _client.isBlocked
                        ? [Colors.redAccent, Colors.red]
                        : [
                            AppTheme.primaryColor,
                            AppTheme.primaryColor.withOpacity(0.7),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          (_client.isBlocked
                                  ? Colors.red
                                  : AppTheme.primaryColor)
                              .withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _client.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _client.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _client.email,
                      style: const TextStyle(
                        color: AppTheme.mutedTextColor,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (_client.isBlocked)
                          _buildStatusBadge('BLOCKED', Colors.red),
                        if (_client.isCoachCreated) ...[
                          if (_client.isBlocked) const SizedBox(width: 8),
                          _buildStatusBadge('COACH CREATED', Colors.blue),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ACCOUNT MANAGEMENT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.mutedTextColor,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildAdminButton(
                        context,
                        'Reset Pass',
                        Icons.lock_reset,
                        Colors.blue,
                        () async {
                          final confirm = await _showConfirmDialog(
                            context,
                            'Reset Password?',
                            'Send a password reset email to ${_client.email}?',
                            'Send',
                          );
                          if (confirm == true) {
                            try {
                              await FirebaseAuth.instance
                                  .sendPasswordResetEmail(email: _client.email);
                              if (context.mounted) {
                                _showSnackBar(
                                  context,
                                  'Password reset email sent',
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                _showSnackBar(
                                  context,
                                  'Error: $e',
                                  isError: true,
                                );
                              }
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildAdminButton(
                        context,
                        _client.isBlocked ? 'Unblock' : 'Block',
                        _client.isBlocked ? Icons.lock_open : Icons.block,
                        _client.isBlocked ? Colors.green : Colors.orange,
                        () async {
                          final db = DatabaseService();
                          await db.toggleBlockClient(
                            _client.uid,
                            !_client.isBlocked,
                          );
                          if (context.mounted) Navigator.pop(context);
                        },
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
                          final confirm = await _showConfirmDialog(
                            context,
                            'Delete Client?',
                            'This action is permanent and cannot be undone.',
                            'Delete',
                            isCritical: true,
                          );
                          if (confirm == true) {
                            final db = DatabaseService();
                            await db.deleteClient(_client.uid);
                            if (context.mounted) Navigator.pop(context);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Future<bool?> _showConfirmDialog(
    BuildContext context,
    String title,
    String content,
    String confirmLabel, {
    bool isCritical = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          content,
          style: const TextStyle(color: AppTheme.mutedTextColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppTheme.mutedTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCritical ? Colors.red : AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildAdminButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
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
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignProgramDialog(
    BuildContext context,
    DatabaseService dbService,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assign Program',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Option 1: Create New Specific Program
            InkWell(
              onTap: () {
                Navigator.pop(context); // Close sheet
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProgramEditor(
                      coachId:
                          _client.coachId ??
                          FirebaseAuth.instance.currentUser!.uid,
                      preSelectedClientId: _client.uid,
                    ),
                  ),
                );
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
                    Icon(
                      Icons.add_circle_outline,
                      color: AppTheme.primaryColor,
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create New Private Program',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Text(
                          'Build a specific plan just for ${'this client'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.mutedTextColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            const Text(
              'OR Select from Templates',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<List<Program>>(
                // Fetch ONLY templates created by this coach
                stream: dbService.getProgramTemplates(
                  _client.coachId ?? FirebaseAuth.instance.currentUser!.uid,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator());
                  final programs = snapshot.data ?? [];

                  if (programs.isEmpty) {
                    return const Center(
                      child: Text(
                        'No templates found. Create one from your dashboard.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.mutedTextColor),
                      ),
                    );
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
                          title: Text(
                            p.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            '${p.totalWeeks} Weeks • Template',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.mutedTextColor,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.copy,
                            size: 20,
                            color: Colors.white54,
                          ),
                          onTap: () =>
                              _confirmAssignTemplate(context, dbService, p),
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

  void _confirmAssignTemplate(
    BuildContext context,
    DatabaseService dbService,
    Program template,
  ) {
    DateTime selectedDate = DateTime.now();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Assign "${template.name}"?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'This will create a copy of the template assigned to this client.',
              ),
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
                        firstDate: DateTime.now().subtract(
                          const Duration(days: 30),
                        ),
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
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close confirm
                Navigator.pop(context); // Close bottom sheet

                await dbService.createProgramCopy(
                  template.id!,
                  _client.uid,
                  selectedDate,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Program assigned successfully'),
                    ),
                  );
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        final programs = snapshot.data ?? [];
        if (programs.isEmpty) {
          return const Text(
            'No program history found.',
            style: TextStyle(color: AppTheme.mutedTextColor),
          );
        }

        return Column(
          children: programs
              .map((p) => _buildProgramHistoryCard(context, dbService, p))
              .toList(),
        );
      },
    );
  }

  Widget _buildProgramHistoryCard(
    BuildContext context,
    DatabaseService dbService,
    Program program,
  ) {
    final bool isActive = program.status == ProgramStatus.active;
    final bool isAssigned = program.status == ProgramStatus.assigned;
    final color = isActive
        ? AppTheme.primaryColor
        : (isAssigned ? Colors.orange : Colors.white);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? AppTheme.primaryColor.withOpacity(0.3)
              : Colors.white.withOpacity(0.05),
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isAssigned
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProgramReportScreen(
                          program: program,
                          client: _client,
                        ),
                      ),
                    );
                  },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isActive
                          ? Icons.play_arrow_rounded
                          : (isAssigned
                                ? Icons.schedule_rounded
                                : Icons.history_rounded),
                      color: color,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          program.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isAssigned
                              ? 'NOT STARTED'
                              : '${program.totalWeeks} WEEKS • ${program.status.name.toUpperCase()}',
                          style: TextStyle(
                            color: color.withOpacity(0.6),
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildProgramActions(context, dbService, program),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgramActions(
    BuildContext context,
    DatabaseService dbService,
    Program program,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _miniActionCircle(
          icon: Icons.edit_note_rounded,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ProgramEditor(
                programToEdit: program,
                coachId: program.coachId,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _miniActionCircle(
          icon: Icons.delete_outline_rounded,
          color: Colors.redAccent,
          onTap: () => _confirmDeleteProgram(context, dbService, program),
        ),
      ],
    );
  }

  Widget _miniActionCircle({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.white54,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  void _confirmDeleteProgram(
    BuildContext context,
    DatabaseService dbService,
    Program program,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Delete Program?',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete "${program.name}"?',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 12),
            const Text(
              'WARNING: This will permanently delete the program, all workout logs, and all progress data for this client.',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: AppTheme.mutedTextColor),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await dbService.deleteProgramCompletely(program.id!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Program and all associated data deleted.'),
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting program: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text(
              'DELETE PERMANENTLY',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
                    style: TextStyle(
                      color: AppTheme.mutedTextColor.withOpacity(0.5),
                    ),
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...history.map(
                  (checkin) => _buildWeeklyCheckInLogCard(checkin),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildWeeklyCheckInLogCard(WeeklyNutritionCheckIn checkin) {
    final dateStr = DateFormat('MMM dd, yyyy').format(checkin.weekStartDate);
    final statusColor = checkin.status.label.contains('missed')
        ? Colors.redAccent
        : AppTheme.primaryColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    checkin.status.emoji,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Week of $dateStr',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        checkin.status.label.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.white.withOpacity(0.2),
                ),
              ],
            ),
            if (checkin.notes.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  checkin.notes,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'SUBMISSION DATE',
                  style: TextStyle(
                    color: AppTheme.mutedTextColor,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy').format(checkin.createdAt),
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentView() {
    if (!_client.isOnboardingComplete && !_client.isCoachCreated) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Text(
            'Client has not completed onboarding yet.',
            style: TextStyle(color: AppTheme.mutedTextColor),
          ),
        ),
      );
    }

    return Column(
      children: [
        _assessmentGroup("Physical Metrics", [
          _assessmentRow(
            "Age",
            "${_client.age ?? 'N/A'} years",
            Icons.calendar_today_rounded,
          ),
          _assessmentRow(
            "Height",
            "${_client.height ?? 'N/A'} in",
            Icons.height_rounded,
          ),
          _assessmentRow(
            "Weight",
            "${_client.weight ?? 'N/A'} kg",
            Icons.monitor_weight_outlined,
          ),
          _assessmentRow(
            "Gender",
            _client.gender ?? 'N/A',
            Icons.person_outline_rounded,
          ),
        ], onEdit: _showEditPhysicalMetricsDialog),
        const SizedBox(height: 16),
        _assessmentGroup("Goals & Commitment", [
          _assessmentRow(
            "Primary Goal",
            _client.goal ?? 'N/A',
            Icons.track_changes_rounded,
          ),
          if (_client.goalDetails != null && _client.goalDetails!.isNotEmpty)
            _assessmentRow(
              "Goal Details",
              _client.goalDetails!,
              Icons.notes_rounded,
            ),
          _assessmentRow(
            "Commitment",
            _client.timeCommitment ?? 'N/A',
            Icons.timer_outlined,
          ),
        ], onEdit: _showEditGoalsDialog),
      ],
    );
  }

  Widget _assessmentGroup(
    String title,
    List<Widget> children, {
    VoidCallback? onEdit,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                  letterSpacing: 1.5,
                ),
              ),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit_road_rounded,
                    size: 16,
                    color: AppTheme.primaryColor,
                  ),
                  tooltip: 'Edit Section',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _assessmentRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppTheme.mutedTextColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppTheme.mutedTextColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditPhysicalMetricsDialog() async {
    final ageController = TextEditingController(
      text: _client.age?.toString() ?? '',
    );
    final heightController = TextEditingController(
      text: _client.height?.toString() ?? '',
    );
    final weightController = TextEditingController(
      text: _client.weight?.toString() ?? '',
    );
    String selectedGender = _client.gender ?? 'Male';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text('Edit Physical Metrics'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildEditField(
                  ageController,
                  'Age',
                  Icons.calendar_today,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildEditField(
                  heightController,
                  'Height (in)',
                  Icons.height,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 16),
                _buildEditField(
                  weightController,
                  'Weight (kg)',
                  Icons.monitor_weight_outlined,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  items: ['Male', 'Female', 'Other']
                      .map((i) => DropdownMenuItem(value: i, child: Text(i)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedGender = v!),
                  dropdownColor: AppTheme.surfaceColor,
                  decoration: const InputDecoration(
                    labelText: 'Gender',
                    prefixIcon: Icon(
                      Icons.person_search,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
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
              onPressed: () async {
                final data = {
                  'age': int.tryParse(ageController.text),
                  'height': double.tryParse(heightController.text),
                  'weight': double.tryParse(weightController.text),
                  'gender': selectedGender,
                  'isOnboardingComplete': true,
                };
                await _updateClientData(data);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGoalsDialog() async {
    final goalDetailsController = TextEditingController(
      text: _client.goalDetails ?? '',
    );
    final commitmentController = TextEditingController(
      text: _client.timeCommitment?.split(' ')[0] ?? '3',
    );
    String selectedGoal = _client.goal ?? 'Fat Loss';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.surfaceColor,
          title: const Text('Edit Goals & Commitment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedGoal,
                  items:
                      [
                            'Fat Loss',
                            'Strength',
                            'Muscle Gain',
                            'Event Specific',
                            'Other',
                          ]
                          .map(
                            (i) => DropdownMenuItem(value: i, child: Text(i)),
                          )
                          .toList(),
                  onChanged: (v) => setDialogState(() => selectedGoal = v!),
                  dropdownColor: AppTheme.surfaceColor,
                  decoration: const InputDecoration(
                    labelText: 'Primary Goal',
                    prefixIcon: Icon(
                      Icons.track_changes,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildEditField(
                  goalDetailsController,
                  'Goal Details',
                  Icons.notes,
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                _buildEditField(
                  commitmentController,
                  'Commitment (Months)',
                  Icons.timer_outlined,
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
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
              onPressed: () async {
                final data = {
                  'goal': selectedGoal,
                  'goalDetails': goalDetailsController.text.trim(),
                  'timeCommitment': '${commitmentController.text} Months',
                  'isOnboardingComplete': true,
                };
                await _updateClientData(data);
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
    );
  }

  Future<void> _updateClientData(Map<String, dynamic> data) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Show non-dismissible loading overlay dialog (covers current dialog)
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const PopScope(
        canPop: false,
        child: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
        ),
      ),
    );

    try {
      await authProvider.updateClientProfile(_client.uid, data);

      // Fetch fresh profile to update local state
      final freshProfile = await AuthService().getProfile(_client.uid);
      if (freshProfile != null) {
        setState(() => _client = freshProfile);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Client assessment updated successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating client: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        Navigator.pop(context); // Remove the loading overlay
      }
    }
  }

  Widget _buildProgramActiveOverview(DatabaseService dbService) {
    return StreamBuilder<List<Program>>(
      stream: _programHistoryStream,
      builder: (context, snapshot) {
        final programs = snapshot.data ?? [];
        final activeProgram = programs.isEmpty
            ? null
            : programs.firstWhere(
                (p) => p.status == ProgramStatus.active,
                orElse: () => programs.first,
              );

        if (activeProgram == null ||
            activeProgram.status != ProgramStatus.active) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryColor.withOpacity(0.05),
                AppTheme.surfaceColor,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ACTIVE PROGRAM',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activeProgram.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.trending_up_rounded,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              FutureBuilder<double>(
                future: dbService.getProgramProgressStatic(activeProgram.id!),
                builder: (context, progressSnap) {
                  final progress = progressSnap.data ?? 0.0;
                  final percentage = (progress * 100).toInt();

                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Completion Rate',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            '$percentage%',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: Colors.white.withOpacity(0.05),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrainingStatsGrid(DatabaseService dbService) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: dbService.getClientStats(_client.uid),
      builder: (context, snapshot) {
        final stats = snapshot.data ?? {};
        final sessions = stats['sessions'] ?? 0;
        final avgRating = (stats['avgRating'] ?? 0.0) as double;

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.2,
          children: [
            _buildStatCard(
              'Sessions Done',
              sessions.toString(),
              Icons.event_available_rounded,
              Colors.blueAccent,
            ),
            _buildStatCard(
              'Avg Rating',
              avgRating > 0 ? '${avgRating.toStringAsFixed(1)}/10' : '—',
              Icons.star_rounded,
              Colors.amberAccent,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Icon(icon, size: 14, color: color.withOpacity(0.7)),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
