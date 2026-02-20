import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ptapp/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of user auth changes
  Stream<User?> get user => _auth.authStateChanges();

  // Sign up with email/password and automatic coach assignment
  Future<UserCredential?> signUp({
    required String email,
    required String password,
    required String name,
    required UserRole role,
  }) async {
    try {
      String? assignedCoachId;
      if (role == UserRole.client) {
        assignedCoachId = await getRandomCoachId();
        if (assignedCoachId == null) {
          throw Exception(
            "No coaches available to assign. Please try again later.",
          );
        }
      }

      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        AppUser newUser = AppUser(
          uid: user.uid,
          email: email,
          name: name,
          role: role,
          coachId: assignedCoachId,
          isOnboardingComplete:
              role == UserRole.coach, // Coaches don't need onboarding
          isCoachCreated: false,
        );
        await _db.collection('users').doc(user.uid).set(newUser.toMap());
      }
      return result;
    } catch (e) {
      print("Error signing up: $e");
      rethrow; // Rethrow to handle in UI
    }
  }

  Future<String?> getRandomCoachId() async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('role', isEqualTo: UserRole.coach.index)
          .limit(5)
          .get();

      if (snapshot.docs.isEmpty) return null;

      final random = Random();
      final randomIndex = random.nextInt(snapshot.docs.length);
      return snapshot.docs[randomIndex].id;
    } catch (e) {
      print("Error fetching coaches: $e");
      return null;
    }
  }

  // Get current user profile from Firestore
  Future<AppUser?> getProfile(String uid) async {
    try {
      DocumentSnapshot doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print("Error getting profile: $e");
      return null;
    }
  }

  // Sign in with email/password
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print("Error signing in: $e");
      rethrow;
    }
  }

  // Admin: Create client account
  Future<String?> createClientAccount({
    required String email,
    required String password,
    required String name,
    required String coachId,
    String? phone,
    String? notes,
    int? age,
    double? height,
    double? weight,
    String? gender,
    String? goal,
    String? goalDetails,
    String? timeCommitment,
  }) async {
    FirebaseApp? tempApp;
    try {
      // Create a secondary Firebase App instance to create the user
      // This prevents the automatic sign-in on the main auth instance
      // We use the default app's options to modify the current project
      FirebaseApp defaultApp = Firebase.app();

      tempApp = await Firebase.initializeApp(
        name: 'tempClientCreationApp',
        options: defaultApp.options,
      );

      FirebaseAuth tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      UserCredential result = await tempAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        AppUser newUser = AppUser(
          uid: user.uid,
          email: email,
          name: name,
          role: UserRole.client,
          coachId: coachId,
          phone: phone,
          notes: notes,
          age: age,
          height: height,
          weight: weight,
          gender: gender,
          goal: goal,
          goalDetails: goalDetails,
          timeCommitment: timeCommitment,
          isOnboardingComplete: true, // Coach created accounts skip onboarding
          isCoachCreated: true,
        );

        // Use the main DB instance to save the user data
        await _db.collection('users').doc(user.uid).set(newUser.toMap());

        return user.uid;
      }
      return null;
    } catch (e) {
      print("Error creating client: $e");
      rethrow;
    } finally {
      // Always delete the temporary app
      if (tempApp != null) {
        await tempApp.delete();
      }
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Update FCM/APN tokens
  Future<void> updateTokens(String uid, {String? pushToken}) async {
    if (pushToken != null) {
      await _db.collection('users').doc(uid).update({
        'pushToken': pushToken,
        'fcmToken': FieldValue.delete(),
        'apnsToken': FieldValue.delete(),
      });
    }
  }

  // Update Display Name
  Future<void> updateName(String uid, String newName) async {
    await _db.collection('users').doc(uid).update({'name': newName});
  }

  // Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Check if user exists by email
  Future<bool> checkUserExists(String email) async {
    try {
      final querySnapshot = await _db
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print("Error checking user existence: $e");
      return false;
    }
  }

  // Re-authenticate user
  Future<void> reauthenticate(String email, String password) async {
    final user = _auth.currentUser;
    if (user != null) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    } else {
      throw Exception('No user signed in');
    }
  }

  // Update Password
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    } else {
      throw Exception('No user signed in');
    }
  }

  // Delete Account
  Future<void> deleteAccount(String uid) async {
    final user = _auth.currentUser;
    if (user != null && user.uid == uid) {
      // 1. Delete Firestore document
      await _db.collection('users').doc(uid).delete();
      // 2. Delete Auth account
      await user.delete();
    } else {
      throw Exception('No user signed in or UID mismatch');
    }
  }

  // Update Profile Data
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }
}
