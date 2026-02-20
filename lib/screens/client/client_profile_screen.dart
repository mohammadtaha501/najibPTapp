import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ptapp/utils/theme.dart';
import 'package:ptapp/widgets/common_widgets.dart';
import 'package:ptapp/screens/common/change_password_screen.dart';
import 'package:ptapp/screens/client/completed_programs_screen.dart';
import 'package:ptapp/models/user_model.dart';

import '../../providers/auth_provider.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final _nameController = TextEditingController();
  final firebase_auth.User? _currentUser =
      firebase_auth.FirebaseAuth.instance.currentUser;
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _nameController.text = _currentUser.displayName ?? '';
      FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser.uid)
          .get()
          .then((doc) {
            if (doc.exists && mounted) {
              setState(() {
                _nameController.text = doc.data()?['name'] ?? '';
              });
            }
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).userProfile;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'PROFILE',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(user),
                  const SizedBox(height: 32),
                  _buildPersonalSection(),
                  const SizedBox(height: 24),
                  if (!user.isCoachCreated ||
                      (user.age != null ||
                          user.height != null ||
                          user.weight != null))
                    _buildStatsSection(user),
                  const SizedBox(height: 24),
                  _buildSecuritySection(),
                  const SizedBox(height: 24),
                  _buildHistorySection(),
                  const SizedBox(height: 40),
                  _buildDangerZone(context),
                  const SizedBox(height: 48),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(AppUser user) {
    return Center(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppTheme.primaryColor.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.surfaceColor,
              child: Text(
                (user.name.isNotEmpty ? user.name[0] : 'U').toUpperCase(),
                style: const TextStyle(
                  fontSize: 40,
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            user.name.toUpperCase(),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            user.email.toLowerCase(),
            style: TextStyle(
              color: AppTheme.mutedTextColor.withOpacity(0.7),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Display Name'),
        CustomCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(
              Icons.person_outline,
              color: AppTheme.primaryColor,
            ),
            title: _isEditingName
                ? TextField(
                    controller: _nameController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter name',
                    ),
                  )
                : Text(
                    _nameController.text,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
            trailing: IconButton(
              icon: Icon(
                _isEditingName ? Icons.check_circle : Icons.edit_outlined,
                color: _isEditingName ? Colors.greenAccent : Colors.white54,
              ),
              onPressed: () {
                if (_isEditingName) {
                  _updateName();
                } else {
                  setState(() => _isEditingName = true);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(AppUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Body Stats',
          actionLabel: 'Edit',
          onActionPressed: () => _showEditStatsSheet(context, user),
        ),
        CustomCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _buildStatRow(
                Icons.cake_outlined,
                'Age',
                '${user.age ?? '--'} years',
              ),
              const Divider(color: Colors.white10, height: 24),
              _buildStatRow(
                Icons.height,
                'Height',
                '${user.height ?? '--'} cm',
              ),
              const Divider(color: Colors.white10, height: 24),
              _buildStatRow(
                Icons.monitor_weight_outlined,
                'Weight',
                '${user.weight ?? '--'} kg',
              ),
              const Divider(color: Colors.white10, height: 24),
              _buildStatRow(Icons.flag_outlined, 'Goal', user.goal ?? '--'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor.withOpacity(0.7)),
        const SizedBox(width: 16),
        Text(label, style: const TextStyle(color: AppTheme.mutedTextColor)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildSecuritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Security'),
        CustomCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(
              Icons.lock_reset_outlined,
              color: Colors.orangeAccent,
            ),
            title: const Text(
              'Change Password',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white24),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Activity'),
        CustomCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: const Icon(
              Icons.history_rounded,
              color: Colors.blueAccent,
            ),
            title: const Text(
              'Program History',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white24),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CompletedProgramsScreen(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'DANGER ZONE',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontSize: 12,
            ),
          ),
        ),
        CustomCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Colors.white70,
                ),
                title: const Text('Log Out'),
                onTap: () => _showLogoutConfirmation(context),
              ),
              const Divider(color: Colors.white10, height: 1),
              ListTile(
                leading: const Icon(
                  Icons.delete_forever_outlined,
                  color: Colors.redAccent,
                ),
                title: const Text(
                  'Delete Account',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: const Text(
                  'Permanently remove your data',
                  style: TextStyle(fontSize: 12),
                ),
                onTap: () => _showDeleteAccountConfirmation(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showEditStatsSheet(BuildContext context, AppUser user) {
    final ageController = TextEditingController(
      text: user.age?.toString() ?? '',
    );
    final heightController = TextEditingController(
      text: user.height?.toString() ?? '',
    );
    final weightController = TextEditingController(
      text: user.weight?.toString() ?? '',
    );
    String selectedGoal = user.goal ?? 'Muscle Gain';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 40,
          top: 32,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Update Body Stats',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Keep your physical metrics up to date for better tracking.',
              style: TextStyle(color: AppTheme.mutedTextColor),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: _buildSheetInput(
                    'Age',
                    ageController,
                    Icons.cake,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSheetInput(
                    'Weight (kg)',
                    weightController,
                    Icons.monitor_weight,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildSheetInput(
              'Height (cm)',
              heightController,
              Icons.height,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final age = int.tryParse(ageController.text);
                  final height = double.tryParse(heightController.text);
                  final weight = double.tryParse(weightController.text);

                  if (age == null || height == null || weight == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter valid numbers'),
                      ),
                    );
                    return;
                  }

                  await Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  ).updateOnboardingData(
                    age: age,
                    height: height,
                    weight: weight,
                    gender: user.gender ?? 'Other',
                    goal: selectedGoal,
                    timeCommitment: user.timeCommitment ?? 'Moderate',
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetInput(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppTheme.mutedTextColor,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              prefixIcon: Icon(icon, size: 18, color: AppTheme.primaryColor),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _updateName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    try {
      await Provider.of<AuthProvider>(context, listen: false).updateName(name);
      if (mounted) {
        setState(() => _isEditingName = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name updated successfully')),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Log Out',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Are you sure you want to end your current session?',
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
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.2),
              foregroundColor: Colors.redAccent,
              elevation: 0,
            ),
            child: const Text(
              'Log Out',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'DELETE ACCOUNT',
          style: TextStyle(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: Colors.orangeAccent,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'This action is permanent and cannot be undone. All your progress, history, and records will be deleted.',
              textAlign: TextAlign.center,
              style: TextStyle(height: 1.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Are you absolutely sure?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Keep My Account',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await Provider.of<AuthProvider>(
                  context,
                  listen: false,
                ).deleteAccount();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error: $e. You might need to re-login to delete.',
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 4,
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
}
