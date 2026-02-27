import 'package:flutter/material.dart';
import 'package:ptapp/utils/theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'PRIVACY POLICY',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last Updated: February 2026',
              style: TextStyle(color: AppTheme.mutedTextColor, fontSize: 12),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Introduction',
              'This Privacy Policy explains how we collect, use, and protect your personal data when you use the PT Programme Mobile App. Our goal is to provide a professional, secure, and personalized coaching experience.',
            ),
            _buildSection(
              '2. Data We Collect',
              'To provide our services, we collect the following information:\n'
                  '• Personal Identification: Name, Email, and Phone Number (provided by your coach).\n'
                  '• Health & Bio Data: Age, Gender, Height, and Weight.\n'
                  '• Fitness Data: Goals, commitment levels, and exercise performance logs (weight used, reps, and notes).',
            ),
            _buildSection(
              '3. Why We Collect Your Data',
              'Your data is processed based on your explicit consent for the following purposes:\n'
                  '• Creating personalized training and nutrition programs.\n'
                  '• Tracking your fitness progress over time.\n'
                  '• Enabling direct communication with your PT coach.\n'
                  '• Providing feedback on your performance.',
            ),
            _buildSection(
              '4. Data Storage and Security',
              'Your data is stored securely using encrypted storage where applicable. We ensure data isolation, meaning your personal information is only accessible to you and your assigned PT coach. We retain your data only for as long as your account is active.',
            ),
            _buildSection(
              '5. Your Rights (UK GDPR)',
              'As a user, you have the following rights:\n'
                  '• Right to access your data at any time.\n'
                  '• Right to withdraw your consent (which will limit app functionality).\n'
                  '• Right to request deletion of your account and all associated data.',
            ),
            _buildSection(
              '6. Contact',
              'For any questions regarding your privacy, please contact your PT coach or the system administrator.',
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.white,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
