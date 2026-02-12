import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ptapp/screens/coach/coach_home.dart';
import 'package:ptapp/screens/common/exercise_library.dart';
import 'package:ptapp/screens/coach/coach_profile_screen.dart';
import 'package:ptapp/utils/theme.dart';

import 'package:ptapp/screens/coach/coach_chat_list_screen.dart';
import 'package:ptapp/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:ptapp/services/database_service.dart';

class CoachNavigationWrapper extends StatefulWidget {
  const CoachNavigationWrapper({super.key});

  @override
  State<CoachNavigationWrapper> createState() => _CoachNavigationWrapperState();
}

class _CoachNavigationWrapperState extends State<CoachNavigationWrapper> {
  int _selectedIndex = 0;
  final _dbService = DatabaseService();
  Stream<int>? _totalUnreadStream;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final coachId = Provider.of<AuthProvider>(context).userProfile?.uid ?? '';
    _totalUnreadStream ??= _dbService.getTotalUnreadCountForCoach(coachId);
  }

  final List<Widget> _screens = [
    const CoachHomeScreen(),
    const CoachChatListScreen(),
    const ExerciseLibraryScreen(),
    const CoachProfileScreen(),
  ];

  Future<bool> _showExitDialog() async {
    return await showDialog(
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
          return false;
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            backgroundColor: AppTheme.backgroundColor,
            selectedItemColor: AppTheme.primaryColor,
            unselectedItemColor: AppTheme.mutedTextColor,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
            unselectedLabelStyle: const TextStyle(fontSize: 11),
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'HOME',
              ),
              BottomNavigationBarItem(
                icon: StreamBuilder<int>(
                  stream: _totalUnreadStream,
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;
                    return Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.chat_bubble_outline),
                        if (count > 0)
                          Positioned(
                            right: -5,
                            top: -5,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                              child: Text('$count', style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    );
                  },
                ),
                activeIcon: const Icon(Icons.chat_bubble),
                label: 'CHATS',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.fitness_center_outlined),
                activeIcon: Icon(Icons.fitness_center),
                label: 'LIBRARY',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'PROFILE',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
