import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:untitled3/screens/client/client_home.dart';
import 'package:untitled3/screens/client/workout_history.dart';
import 'package:untitled3/screens/common/nutrition_screen.dart';
import 'package:untitled3/screens/client/client_profile_screen.dart';
import 'package:untitled3/utils/theme.dart';
import 'package:untitled3/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:untitled3/screens/client/assigned_programs_screen.dart';
import 'package:untitled3/services/database_service.dart';
import 'package:untitled3/models/program_model.dart';

class ClientNavigationWrapper extends StatefulWidget {
  const ClientNavigationWrapper({super.key});

  @override
  State<ClientNavigationWrapper> createState() => _ClientNavigationWrapperState();
}

class _ClientNavigationWrapperState extends State<ClientNavigationWrapper> {
  int _selectedIndex = 0;
  final _dbService = DatabaseService();
  Stream<List<Program>>? _programsBadgeStream;
  Stream<int>? _unreadCountStream;

  // We define screens here but we need the userId, so we'll construct them in build
  // or use a method to avoid context issues.

  Future<bool> _showExitDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceColor,
        title: const Text('Exit App', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to exit the app?', style: TextStyle(color: AppTheme.mutedTextColor)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL', style: TextStyle(color: AppTheme.mutedTextColor)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('EXIT', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userProfile;

    if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    _programsBadgeStream ??= _dbService.getClientPrograms(user.uid);
    _unreadCountStream ??= _dbService.getUnreadCount(user.coachId ?? '', user.uid);

    final List<Widget> screens = [
      const ClientHomeScreen(),
      const AssignedProgramsScreen(),
      WorkoutHistoryScreen(clientId: user.uid),
      NutritionScreen(clientId: user.uid, isCoach: false),
      const ClientProfileScreen(),
    ];

    return WillPopScope(
      onWillPop: () async {
        if (_selectedIndex != 0) {
          setState(() => _selectedIndex = 0);
          return false;
        } else {
          final shouldExit = await _showExitDialog();
          if (shouldExit) {
            SystemNavigator.pop();
          }
          return false; // We handle exit via SystemNavigator.pop()
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: screens,
        ),
        bottomNavigationBar: _buildModernNavBar(),
      ),
    );
  }

  Widget _buildModernNavBar() {
    return StreamBuilder<int>(
      stream: _unreadCountStream,
      builder: (context, unreadSnapshot) {
        final unreadCount = unreadSnapshot.data ?? 0;

        return StreamBuilder<List<Program>>(
          stream: _programsBadgeStream,
          builder: (context, snapshot) {
            final programs = snapshot.data ?? [];
            final unstartedCount = programs.where((p) => p.status == ProgramStatus.assigned).length;

            final items = [
              _NavItem(Icons.home_outlined, Icons.home, 'Home', hasCounter: unreadCount > 0, counterValue: unreadCount),
              _NavItem(Icons.folder_outlined, Icons.folder, 'Programs', hasCounter: unstartedCount > 0, counterValue: unstartedCount),
              _NavItem(Icons.history, Icons.history, 'History', hasCounter: false),
              _NavItem(Icons.restaurant_outlined, Icons.restaurant, 'Nutrition', hasCounter: false),
              _NavItem(Icons.person_outline, Icons.person, 'Profile', hasCounter: false),
            ];

            return Container(
              height: 85,
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = _selectedIndex == index;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedIndex = index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Icon(
                                isSelected ? item.activeIcon : item.icon,
                                color: isSelected ? AppTheme.primaryColor : AppTheme.mutedTextColor,
                                size: 26,
                              ),
                              if (item.hasCounter)
                                Positioned(
                                  right: -8,
                                  top: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    child: Center(
                                      child: Text(
                                        item.counterValue.toString(),
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 300),
                            style: TextStyle(
                              color: isSelected ? AppTheme.primaryColor : AppTheme.mutedTextColor,
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            child: Text(item.label),
                          ),
                          const SizedBox(height: 4),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 3,
                            width: isSelected ? 12 : 0,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        );
      },
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool hasCounter;
  final int counterValue;

  _NavItem(this.icon, this.activeIcon, this.label, {this.hasCounter = false, this.counterValue = 0});
}
