import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:ptapp/utils/theme.dart';
import 'package:ptapp/widgets/common_widgets.dart';
import 'package:ptapp/screens/common/change_password_screen.dart';
import 'package:ptapp/screens/client/completed_programs_screen.dart';

import '../../providers/auth_provider.dart';

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final _nameController = TextEditingController();
  final firebase_auth.User? _currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
  bool _isEditingName = false;

  @override
  void initState() {
    super.initState();
    if (_currentUser != null) {
      _nameController.text = _currentUser.displayName ?? '';
      if (_nameController.text.isEmpty) {
        FirebaseFirestore.instance.collection('users').doc(_currentUser.uid).get().then((doc) {
          if (doc.exists && mounted) {
            setState(() {
              _nameController.text = doc.data()?['name'] ?? '';
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('My Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    child: Text(
                      (_nameController.text.isNotEmpty ? _nameController.text[0] : 'U').toUpperCase(),
                      style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(_currentUser?.email ?? '', style: const TextStyle(color: AppTheme.mutedTextColor, fontSize: 16)),
                ],
              ),
            ),
            const SizedBox(height: 48),
            const SectionHeader(title: 'Personal Details'),
            CustomCard(
              child: TextField(
                controller: _nameController,
                readOnly: !_isEditingName,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_isEditingName ? Icons.check : Icons.edit, color: _isEditingName ? AppTheme.primaryColor : Colors.white54),
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
            ),
            CustomCard(
              child: ListTile(
                leading: const Icon(Icons.emoji_events_outlined, color: AppTheme.primaryColor),
                title: const Text('Completed Programs', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('View your training history', style: TextStyle(color: AppTheme.mutedTextColor)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompletedProgramsScreen())),
              ),
            ),
            const SizedBox(height: 32),
            const SectionHeader(title: 'Security'),
            CustomCard(
              child: ListTile(
                leading: const Icon(Icons.lock_outline, color: AppTheme.primaryColor),
                title: const Text('Password', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Change your password securely', style: TextStyle(color: AppTheme.mutedTextColor)),
                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showLogoutConfirmation(context),
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Future<void> _updateName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    try {
      await _currentUser?.updateDisplayName(name);
      await FirebaseFirestore.instance.collection('users').doc(_currentUser?.uid).update({'name': name});
      if (mounted) {
        setState(() => _isEditingName = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name updated successfully')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Logout', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: AppTheme.mutedTextColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.mutedTextColor)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
            child: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
