import '../../constants/firebase_constants.dart';

class UserModel {
  final String userId;
  final String email;
  final bool emailVerified;
  final String displayName;
  final String photoUrl;
  final String status;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.userId,
    required this.email,
    required this.emailVerified,
    required this.displayName,
    required this.photoUrl,
    required this.status,
    required this.isOnline,
    this.lastSeen,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert from Firestore Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      userId: map[FirebaseConstants.userId] ?? '',
      email: map[FirebaseConstants.email] ?? '',
      emailVerified: map[FirebaseConstants.emailVerified] ?? false,
      displayName: map[FirebaseConstants.displayName] ?? '',
      photoUrl: map[FirebaseConstants.photoUrl] ??
          FirebaseConstants.defaultProfileImage,
      status: map[FirebaseConstants.status] ?? FirebaseConstants.defaultStatus,
      isOnline: map[FirebaseConstants.isOnline] ?? false,
      lastSeen: map[FirebaseConstants.lastSeen]?.toDate(),
      createdAt: map[FirebaseConstants.createdAt]?.toDate() ?? DateTime.now(),
      updatedAt: map[FirebaseConstants.updatedAt]?.toDate() ?? DateTime.now(),
    );
  }

  // Convert to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      FirebaseConstants.userId: userId,
      FirebaseConstants.email: email,
      FirebaseConstants.emailVerified: emailVerified,
      FirebaseConstants.displayName: displayName,
      FirebaseConstants.photoUrl: photoUrl,
      FirebaseConstants.status: status,
      FirebaseConstants.isOnline: isOnline,
      FirebaseConstants.lastSeen: lastSeen,
      FirebaseConstants.createdAt: createdAt,
      FirebaseConstants.updatedAt: updatedAt,
    };
  }

  // Create copy with updated fields
  UserModel copyWith({
    String? userId,
    String? email,
    bool? emailVerified,
    String? displayName,
    String? photoUrl,
    String? status,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      emailVerified: emailVerified ?? this.emailVerified,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(userId: $userId, email: $email, displayName: $displayName, emailVerified: $emailVerified, isOnline: $isOnline)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}
