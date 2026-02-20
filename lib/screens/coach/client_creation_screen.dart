import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:provider/provider.dart';
import 'package:ptapp/providers/auth_provider.dart';
import 'package:ptapp/utils/theme.dart';

class ClientCreationScreen extends StatefulWidget {
  const ClientCreationScreen({super.key});

  @override
  State<ClientCreationScreen> createState() => _ClientCreationScreenState();
}

class _ClientCreationScreenState extends State<ClientCreationScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Onboarding Fields (Optional)
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _goalDetailsController = TextEditingController();
  final _commitmentController = TextEditingController(text: '3');
  String _selectedGender = 'Male';
  String _selectedGoal = 'Fat Loss';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _goalDetailsController.dispose();
    _commitmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('ADD NEW CLIENT'), centerTitle: true),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader(
                'ACCOUNT CREDENTIALS',
                Icons.vpn_key_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _nameController,
                'Full Name',
                Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _emailController,
                'Email Address',
                Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _passwordController,
                'Password',
                Icons.lock_outline,
                obscureText: true,
              ),

              const SizedBox(height: 32),

              Theme(
                data: Theme.of(
                  context,
                ).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  title: const Text(
                    'ONBOARDING DETAILS (OPTIONAL)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.primaryColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                  tilePadding: EdgeInsets.zero,
                  childrenPadding: const EdgeInsets.symmetric(vertical: 16),
                  iconColor: AppTheme.primaryColor,
                  collapsedIconColor: AppTheme.mutedTextColor,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            _ageController,
                            'Age',
                            Icons.calendar_today_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown(
                            'Gender',
                            _selectedGender,
                            ['Male', 'Female', 'Other'],
                            (v) => setState(() => _selectedGender = v!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            _heightController,
                            'Height (in)',
                            Icons.height,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            _weightController,
                            'Weight (kg)',
                            Icons.monitor_weight_outlined,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      'Primary Goal',
                      _selectedGoal,
                      [
                        'Fat Loss',
                        'Strength',
                        'Muscle Gain',
                        'Event Specific',
                        'Other',
                      ],
                      (v) => setState(() => _selectedGoal = v!),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _goalDetailsController,
                      'Goal Details (Optional)',
                      Icons.notes,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _commitmentController,
                      'Commitment (Months)',
                      Icons.timer_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _createClient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: AppTheme.primaryColor.withOpacity(0.4),
                  ),
                  child: const Text(
                    'CREATE ACCOUNT',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppTheme.mutedTextColor),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: AppTheme.mutedTextColor,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 16, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppTheme.primaryColor),
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map(
            (i) => DropdownMenuItem(
              value: i,
              child: Text(i, style: const TextStyle(fontSize: 15)),
            ),
          )
          .toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(
          label.contains('Gender') ? Icons.person_search : Icons.track_changes,
          size: 20,
          color: AppTheme.primaryColor,
        ),
      ),
      dropdownColor: AppTheme.surfaceColor,
    );
  }

  void _createClient() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields.')),
      );
      return;
    }

    // Show non-dismissible loading overlay dialog (covers everything)
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final age = int.tryParse(_ageController.text);
      final height = double.tryParse(_heightController.text);
      final weight = double.tryParse(_weightController.text);
      final commitment = _commitmentController.text.isNotEmpty
          ? '${_commitmentController.text} Months'
          : null;

      await authProvider.createClient(
        email,
        password,
        name,
        age: age,
        height: height,
        weight: weight,
        gender: _ageController.text.isNotEmpty ? _selectedGender : null,
        goal: _ageController.text.isNotEmpty ? _selectedGoal : null,
        goalDetails: _goalDetailsController.text.trim().isNotEmpty
            ? _goalDetailsController.text.trim()
            : null,
        timeCommitment: commitment,
      );

      if (mounted) {
        Navigator.pop(context); // Remove loading overlay
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Client "$name" created successfully!')),
        );
        Navigator.pop(context); // Go back to client list
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) Navigator.pop(context); // Remove overlay
      String message = 'Error: ${e.message}';
      if (e.code == 'email-already-in-use') {
        message = 'This email address is already in use by another account.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) Navigator.pop(context); // Remove overlay
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
