enum UserRole { coach, client }

class AppUser {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String? coachId;
  final String? phone;
  final String? notes;
  final bool isBlocked;
  final String? pushToken;

  // Onboarding Data
  final int? age;
  final double? height;
  final double? weight;
  final String? gender;
  final String? goal;
  final String? goalDetails;
  final String? timeCommitment;
  final bool isOnboardingComplete;
  final bool isCoachCreated;


  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.coachId,
    this.phone,
    this.notes,
    this.isBlocked = false,
    this.pushToken,
    this.age,
    this.height,
    this.weight,
    this.gender,
    this.goal,
    this.goalDetails,
    this.timeCommitment,
    this.isOnboardingComplete = true, // Default to true for backward compatibility/coaches
    this.isCoachCreated = false,
  });


  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'role': role.index,
      'coachId': coachId,
      'phone': phone,
      'notes': notes,
      'isBlocked': isBlocked,
      'pushToken': pushToken,
      'age': age,
      'height': height,
      'weight': weight,
      'gender': gender,
      'goal': goal,
      'goalDetails': goalDetails,
      'timeCommitment': timeCommitment,
      'isOnboardingComplete': isOnboardingComplete,
      'isCoachCreated': isCoachCreated,
    };

  }

  factory AppUser.fromMap(Map<String, dynamic> map, String documentId) {
    return AppUser(
      uid: documentId,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: UserRole.values[map['role'] ?? 1],
      coachId: map['coachId'],
      phone: map['phone'],
      notes: map['notes'],
      isBlocked: map['isBlocked'] ?? false,
      pushToken: map['pushToken'] ?? map['fcmToken'],
      age: map['age'],
      height: (map['height'] as num?)?.toDouble(),
      weight: (map['weight'] as num?)?.toDouble(),
      gender: map['gender'],
      goal: map['goal'],
      goalDetails: map['goalDetails'],
      timeCommitment: map['timeCommitment'],
      isOnboardingComplete: map['isOnboardingComplete'] ?? true,
      isCoachCreated: map['isCoachCreated'] ?? false,
    );

  }
}
