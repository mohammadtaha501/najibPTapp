import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ptapp/providers/auth_provider.dart';
import 'package:ptapp/screens/client/privacy_policy_screen.dart';
import 'package:ptapp/utils/theme.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _isLoading = false;

  void _handleAgree() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.updateConsent(
        consentGiven: true,
        consentVersion: '1.0 (UK GDPR)',
      );
      // Navigation is handled by AuthWrapper in main.dart
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleDisagree() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text(
          'Consent Required',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Without your consent to collect and process data, we cannot create personalized programs for you. You can logout and return later if you change your mind.',
          style: TextStyle(color: AppTheme.mutedTextColor),
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
            onPressed: () {
              Navigator.pop(context);
              Provider.of<AuthProvider>(context, listen: false).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('LOGOUT', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 48),
                    const Icon(
                      Icons.security_outlined,
                      size: 64,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Your Data & Privacy',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'To provide you with a personalized coaching experience, we need to collect and process some of your data.',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppTheme.mutedTextColor,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Column(
                          children: [
                            _buildInfoItem(
                              Icons.person_pin_outlined,
                              'What we collect',
                              'Name, age, health metrics (weight, height), fitness goals, and preferences.',
                            ),
                            _buildInfoItem(
                              Icons.analytics_outlined,
                              'Why we collect it',
                              'To create personalized training and nutrition programs tailored to your specific needs.',
                            ),
                            _buildInfoItem(
                              Icons.timer_outlined,
                              'How long we store it',
                              'Your data is stored securely while your account is active to track your progress.',
                            ),
                            _buildInfoItem(
                              Icons.gavel_outlined,
                              'Your Rights',
                              'You can withdraw your consent or request data deletion at any time through account settings.',
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PrivacyPolicyScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Read our full Privacy Policy',
                                style: TextStyle(
                                  color: AppTheme.primaryColor,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0),
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: _handleAgree,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 60),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text('I AGREE'),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: _handleDisagree,
                            style: TextButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                            ),
                            child: const Text(
                              'I DO NOT AGREE',
                              style: TextStyle(color: AppTheme.mutedTextColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 24, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.mutedTextColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
