import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ptapp/models/user_model.dart';
import 'package:ptapp/services/auth_service.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:ptapp/models/notification_model.dart';
import 'package:ptapp/services/database_service.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  AppUser? _userProfile;
  bool _isLoading = true;
  bool _isSigningIn = false;

  AppUser? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isSigningIn => _isSigningIn;
  bool get isAuthenticated => _userProfile != null;

  AuthProvider() {
    _init();
  }

  String? _authError;
  String? get authError => _authError;

  void _init() {
    _authService.user.listen((User? user) async {
      try {
        if (user != null) {
          // User logged in, fetch profile
          try {
            _userProfile = await _authService.getProfile(user.uid);

            if (_userProfile == null) {
              // "Zombie" User: Auth valid, but Firestore doc missing or unreadable
              _authError =
                  "Account setup incomplete. Please contact your coach.";
              await _authService.signOut(); // Force logout so they aren't stuck
              // The stream will fire again with user=null, triggering the else block
            } else {
              _authError = null; // Clear any previous errors
            }
          } catch (e) {
            _authError = "Error loading profile: $e";
            await _authService.signOut();
          }
        } else {
          _userProfile = null;
          // Do not clear _authError here, as it might have been set by the zombie logout above
        }
      } finally {
        _isSigningIn =
            false; // Clear signing in state when initialization (login flow) completes
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    _isSigningIn = true;
    notifyListeners();
    final result = await _authService.signUp(
      email: email,
      password: password,
      name: name,
      role: role,
    );

    // Note: _isSigningIn transition is handled by the initial profile fetch listener in _init()
    if (result != null && result.user != null) {
      await _saveDeviceTokens(result.user!.uid);
      return true;
    }
    _isSigningIn = false;
    notifyListeners();
    return false;
  }

  Future<bool> signIn(String email, String password) async {
    _isSigningIn = true;
    _authError = null; // Reset error on new attempt
    notifyListeners();
    try {
      final result = await _authService.signIn(email, password);

      // Note: _isSigningIn = false transition is handled by the initial profile fetch listener in _init()
      if (result != null && result.user != null) {
        await _saveDeviceTokens(result.user!.uid);
        return true;
      }
      _isSigningIn = false;
      _authError = "Login failed. Please check your credentials.";
      notifyListeners();
      return false;
    } on FirebaseAuthException catch (e) {
      _isSigningIn = false;
      _authError = _getFriendlyErrorMessage(e);
      notifyListeners();
      return false;
    } catch (e) {
      _isSigningIn = false;
      _authError = "An unexpected error occurred. Please try again.";
      notifyListeners();
      return false;
    }
  }

  String _getFriendlyErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'The email address is invalid.';
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Login failed: ${e.message}';
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
  }

  Future<void> createClient(
    String email,
    String password,
    String name, {
    int? age,
    double? height,
    double? weight,
    String? gender,
    String? goal,
    String? goalDetails,
    String? timeCommitment,
  }) async {
    if (_userProfile?.role != UserRole.coach) return;
    await _authService.createClientAccount(
      email: email,
      password: password,
      name: name,
      coachId: _userProfile!.uid,
      age: age,
      height: height,
      weight: weight,
      gender: gender,
      goal: goal,
      goalDetails: goalDetails,
      timeCommitment: timeCommitment,
    );
  }

  Future<void> updateName(String newName) async {
    if (_userProfile == null) return;
    await _authService.updateName(_userProfile!.uid, newName);
    // Refresh local profile
    _userProfile = await _authService.getProfile(_userProfile!.uid);
    notifyListeners();
  }

  Future<void> sentPasswordResetEmail(String email) async {
    await _authService.sendPasswordResetEmail(email);
  }

  Future<bool> checkUserExists(String email) async {
    return await _authService.checkUserExists(email);
  }

  Future<void> resetPassword() async {
    if (_userProfile == null) return;
    await _authService.sendPasswordResetEmail(_userProfile!.email);
  }

  Future<void> changePassword(String oldPassword, String newPassword) async {
    if (_userProfile == null) return;
    await _authService.reauthenticate(_userProfile!.email, oldPassword);
    await _authService.updatePassword(newPassword);
  }

  Future<void> _saveDeviceTokens(String uid) async {
    try {
      // Request permission
      NotificationSettings settings = await _fcm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? fcmToken = await _fcm.getToken();

        await _authService.updateTokens(uid, pushToken: fcmToken);

        // Update local profile with tokens if it exists
        if (_userProfile != null && _userProfile!.uid == uid) {
          _userProfile = await _authService.getProfile(uid);
          notifyListeners();
        }

        // Listen for token refresh
        _fcm.onTokenRefresh.listen((newToken) {
          _authService.updateTokens(uid, pushToken: newToken);
        });
      }
    } catch (e) {
      debugPrint("SYSTEM: Error saving tokens: $e");
    }
  }

  Future<void> updateOnboardingData({
    required int age,
    required double height,
    required double weight,
    required String gender,
    required String goal,
    String? goalDetails,
    required String timeCommitment,
  }) async {
    if (_userProfile == null) return;

    final updatedData = {
      'age': age,
      'height': height,
      'weight': weight,
      'gender': gender,
      'goal': goal,
      'goalDetails': goalDetails,
      'timeCommitment': timeCommitment,
      'isOnboardingComplete': true,
    };

    await _authService.updateProfile(_userProfile!.uid, updatedData);

    // Notify the coach
    if (_userProfile?.coachId != null) {
      await DatabaseService().createNotification(
        AppNotification(
          recipientId: _userProfile!.coachId!,
          senderId: _userProfile!.uid,
          senderName: _userProfile!.name,
          title: 'New Client Onboarded',
          body: '${_userProfile!.name} has completed their onboarding process.',
          type: NotificationType.onboarding,
          createdAt: DateTime.now(),
        ),
      );
    }

    // Refresh local profile
    _userProfile = await _authService.getProfile(_userProfile!.uid);
    notifyListeners();
  }

  Future<void> updateClientProfile(
    String clientUid,
    Map<String, dynamic> data,
  ) async {
    if (_userProfile?.role != UserRole.coach) return;
    await _authService.updateProfile(clientUid, data);
  }

  Future<void> deleteAccount() async {
    if (_userProfile == null) return;
    final uid = _userProfile!.uid;
    await _authService.deleteAccount(uid);
    _userProfile = null;
    notifyListeners();
  }
}
