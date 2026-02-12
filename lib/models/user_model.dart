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
  final String? fcmToken;
  final String? apnsToken;

  AppUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.coachId,
    this.phone,
    this.notes,
    this.isBlocked = false,
    this.fcmToken,
    this.apnsToken,
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
      'fcmToken': fcmToken,
      'apnsToken': apnsToken,
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
      fcmToken: map['fcmToken'],
      apnsToken: map['apnsToken'],
    );
  }
}
