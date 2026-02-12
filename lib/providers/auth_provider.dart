import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:untitled3/models/user_model.dart';
import 'package:untitled3/services/auth_service.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:io';

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
              _authError = "Account setup incomplete. Please contact your coach.";
              await _authService.signOut(); // Force logout so they aren't stuck
              // The stream will fire again with user=null, triggering the else block
            } else {
               _authError = null; // Clear any previous errors
               
               // --- FCM/APN Token Management ---
               try {
                 // Request permission
                 NotificationSettings settings = await _fcm.requestPermission(
                   alert: true,
                   badge: true,
                   sound: true,
                 );

                 if (settings.authorizationStatus == AuthorizationStatus.authorized) {
                   String? fcmToken = await _fcm.getToken();
                   String? apnsToken;
                   
                   if (Platform.isIOS) {
                     apnsToken = await _fcm.getAPNSToken();
                   }
                   
                   await _authService.updateTokens(user.uid, fcmToken: fcmToken, apnsToken: apnsToken);
                   
                   // Update local profile with tokens
                   _userProfile = await _authService.getProfile(user.uid);
                 }
               } catch (e) {
                 print("Error updating push tokens: $e");
               }
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
        _isSigningIn = false; // Clear signing in state when initialization (login flow) completes
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
    if (result == null) {
      _isSigningIn = false;
      notifyListeners();
      return false;
    }
    return true;
  }

  Future<bool> signIn(String email, String password) async {
    _isSigningIn = true;
    _authError = null; // Reset error on new attempt
    notifyListeners();
    try {
      final result = await _authService.signIn(email, password);
      
      // Note: _isSigningIn = false transition is handled by the initial profile fetch listener in _init()
      if (result == null) {
        _isSigningIn = false;
        _authError = "Login failed. Please check your credentials.";
        notifyListeners();
        return false;
      }
      return true;
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

  Future<void> createClient(String email, String password, String name) async {
    if (_userProfile?.role != UserRole.coach) return;
    await _authService.createClientAccount(
      email: email,
      password: password,
      name: name,
      coachId: _userProfile!.uid,
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
}
