import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:untitled3/firebase_options.dart';
import 'package:untitled3/providers/auth_provider.dart';
import 'package:untitled3/screens/auth/login_screen.dart';
import 'package:untitled3/screens/coach/coach_navigation_wrapper.dart';
import 'package:untitled3/models/user_model.dart';
import 'package:untitled3/utils/theme.dart';
import 'package:untitled3/screens/client/client_navigation_wrapper.dart';
import 'package:untitled3/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Notification Service (Requests permission & resets badge on iOS)
  await NotificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Nijib Trainer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.dark, // Default to dark as per your current preference
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!authProvider.isAuthenticated) {
      return const LoginScreen();
    }

    // Role-based routing
    final user = authProvider.userProfile!;

    if (user.isBlocked) {
      return const Scaffold(
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.block, color: Colors.red, size: 64),
                SizedBox(height: 24),
                Text('ACCOUNT BLOCKED', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                SizedBox(height: 12),
                Text('Your account has been deactivated. Please contact your coach for more information.', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.mutedTextColor)),
              ],
            ),
          ),
        ),
      );
    }

    if (user.role == UserRole.coach) {
      return const CoachNavigationWrapper();
    } else {
      return const ClientNavigationWrapper();
    }
  }
}
