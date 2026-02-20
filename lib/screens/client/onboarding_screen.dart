import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ptapp/providers/auth_provider.dart';
import 'package:ptapp/utils/theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Bio Data
  final _ageController = TextEditingController();
  String _selectedGender = 'Male';

  // Physical Data
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  // Goals Data
  String _selectedGoal = 'Fat Loss';
  final _goalDetailsController = TextEditingController();

  // Commitment
  final _commitmentController = TextEditingController(text: '3');
  bool _commitmentAgreed = false;

  bool _isLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _goalDetailsController.dispose();
    _commitmentController.dispose();
    super.dispose();
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      if (_ageController.text.isEmpty) {
        _showError('Please enter your age.');
        return false;
      }
      final age = int.tryParse(_ageController.text);
      if (age == null || age < 12) {
        _showError('Please enter a valid age (minimum 12).');
        return false;
      }
    } else if (_currentStep == 1) {
      if (_heightController.text.isEmpty || _weightController.text.isEmpty) {
        _showError('Please enter both height and weight.');
        return false;
      }
      final height = double.tryParse(_heightController.text);
      final weight = double.tryParse(_weightController.text);
      if (height == null || height < 20 || weight == null || weight < 20) {
        _showError('Please enter realistic physical metrics.');
        return false;
      }
    } else if (_currentStep == 2) {
      if ((_selectedGoal == 'Event Specific' || _selectedGoal == 'Other') &&
          _goalDetailsController.text.trim().isEmpty) {
        _showError('Please provide details for your selected goal.');
        return false;
      }
    } else if (_currentStep == 3) {
      if (_commitmentController.text.isEmpty) {
        _showError('Please enter your commitment period.');
        return false;
      }
      final months = int.tryParse(_commitmentController.text);
      if (months == null || months < 3) {
        _showError('Consistency is key. Please commit to at least 3 months.');
        return false;
      }
      if (!_commitmentAgreed) {
        _showError('Please agree to the commitment terms.');
        return false;
      }
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _nextStep() {
    if (!_validateCurrentStep()) return;

    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() async {
    if (!_commitmentAgreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the time commitment.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.updateOnboardingData(
        age: int.tryParse(_ageController.text) ?? 20,
        height: double.tryParse(_heightController.text) ?? 67,
        weight: double.tryParse(_weightController.text) ?? 70,
        gender: _selectedGender,
        goal: _selectedGoal,
        goalDetails: _goalDetailsController.text.trim(),
        timeCommitment: '${_commitmentController.text} Months',
      );

      // Navigation will be handled by AuthWrapper in main.dart as profile updates
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildProgressBar(),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (index) =>
                          setState(() => _currentStep = index),
                      children: [
                        _buildBioStep(),
                        _buildPhysicalStep(),
                        _buildGoalStep(),
                        _buildCommitmentStep(),
                      ],
                    ),
                  ),
                  _buildNavigationButtons(),
                ],
              ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Step ${_currentStep + 1} of $_totalSteps',
                style: const TextStyle(
                  color: AppTheme.mutedTextColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${((_currentStep + 1) / _totalSteps * 100).toInt()}%',
                style: const TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: AppTheme.surfaceColor,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppTheme.primaryColor,
              ),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioStep() {
    return _stepLayout(
      title: "Tell us about yourself",
      subtitle: "Help your coach understand who you are.",
      child: Column(
        children: [
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(2),
            ],
            decoration: const InputDecoration(
              labelText: 'Age',
              prefixIcon: Icon(Icons.calendar_today_outlined),
            ),
          ),
          const SizedBox(height: 24),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Gender',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _choiceChip('Male'),
              const SizedBox(width: 12),
              _choiceChip('Female'),
              const SizedBox(width: 12),
              _choiceChip('Prefer not to say'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhysicalStep() {
    return _stepLayout(
      title: "Your stats",
      subtitle: "Accurate metrics help in tracking your transformation.",
      child: Column(
        children: [
          TextField(
            controller: _heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              LengthLimitingTextInputFormatter(5),
            ],
            decoration: const InputDecoration(
              labelText: 'Height (in)',
              prefixIcon: Icon(Icons.height),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              LengthLimitingTextInputFormatter(5),
            ],
            decoration: const InputDecoration(
              labelText: 'Current Weight (kg)',
              prefixIcon: Icon(Icons.monitor_weight_outlined),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalStep() {
    final goals = [
      'Fat Loss',
      'Strength',
      'Muscle Gain',
      'Event Specific',
      'Other',
    ];
    return _stepLayout(
      title: "What's your goal?",
      subtitle: "Choose the one that best describes your focus.",
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: goals.map((goal) => _goalChip(goal)).toList(),
          ),
          AnimatedOpacity(
            opacity:
                (_selectedGoal == 'Event Specific' || _selectedGoal == 'Other')
                ? 1.0
                : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Visibility(
              visible:
                  (_selectedGoal == 'Event Specific' ||
                  _selectedGoal == 'Other'),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: TextField(
                      controller: _goalDetailsController,
                      inputFormatters: [LengthLimitingTextInputFormatter(300)],
                      maxLines: 1,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: InputDecoration(
                        labelText: _selectedGoal == 'Event Specific'
                            ? 'Event Details'
                            : 'Additional Information',
                        hintText: 'Share more details...',
                        prefixIcon: const Icon(Icons.edit_note, size: 24),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(
                            color: AppTheme.primaryColor,
                            width: 2,
                          ),
                        ),
                        floatingLabelStyle: const TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  Widget _buildCommitmentStep() {
    return _stepLayout(
      title: "The Commitment",
      subtitle: "Transformation takes time and consistency.",
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppTheme.surfaceColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                size: 48,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(height: 16),
              const Text(
                'The Commitment Plan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'I commit to minimum of ',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  Container(
                    width: 70,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryColor.withOpacity(0.5),
                      ),
                    ),
                    child: TextField(
                      controller: _commitmentController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                  ),
                  const Text(
                    ' months',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Consistency is the bridge between goals and accomplishment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.mutedTextColor,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 32),
              GestureDetector(
                onTap: () =>
                    setState(() => _commitmentAgreed = !_commitmentAgreed),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: _commitmentAgreed
                        ? AppTheme.primaryColor.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _commitmentAgreed
                          ? AppTheme.primaryColor
                          : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: _commitmentAgreed
                              ? AppTheme.primaryColor
                              : Colors.transparent,
                          border: Border.all(
                            color: _commitmentAgreed
                                ? AppTheme.primaryColor
                                : AppTheme.mutedTextColor,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: _commitmentAgreed
                            ? const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.black,
                              )
                            : null,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'I am ready to commit to this journey.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepLayout({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.mutedTextColor,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 48),
          child,
        ],
      ),
    );
  }

  Widget _choiceChip(String label) {
    final isSelected = _selectedGender == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _goalChip(String label) {
    final isSelected = _selectedGoal == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedGoal = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.white10,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: TextButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Text(
                  'BACK',
                  style: TextStyle(
                    color: AppTheme.mutedTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _currentStep == _totalSteps - 1 ? 'FINISH' : 'NEXT',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
