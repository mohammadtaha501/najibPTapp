import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:ptapp/providers/auth_provider.dart';
import 'package:ptapp/screens/auth/login_screen.dart';
import 'package:ptapp/screens/client/client_navigation_wrapper.dart';
import 'package:ptapp/screens/client/onboarding_screen.dart';
import 'package:ptapp/screens/coach/coach_navigation_wrapper.dart';
import 'package:ptapp/services/notification_service.dart';
import 'package:ptapp/utils/navigation.dart';
import 'package:ptapp/utils/theme.dart';

import 'firebase_options.dart';
import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Notification Service (Requests permission & resets badge on iOS)
  await NotificationService.initialize();
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      title: 'Nijib Trainer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      builder: (context, child) {
        return Listener(
          onPointerDown: (PointerDownEvent event) {
            final FocusScopeNode currentFocus = FocusScope.of(context);
            if (!currentFocus.hasPrimaryFocus && currentFocus.hasFocus) {
              FocusManager.instance.primaryFocus?.unfocus();
            }
          },
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
                Text(
                  'ACCOUNT BLOCKED',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Your account has been deactivated. Please contact your coach for more information.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.mutedTextColor),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (user.role == UserRole.coach) {
      return const CoachNavigationWrapper();
    } else {
      // Check for onboarding
      if (!user.isOnboardingComplete) {
        return const OnboardingScreen();
      }
      return ClientNavigationWrapper(
        key: ClientNavigationWrapper.navigationKey,
      );
    }
  }
}
