// ============================================================================
// File: lib/core/data/models/contact_model.dart
// ============================================================================

import 'package:flutter_contacts/flutter_contacts.dart';
import '../../constants/firebase_constants.dart';
import 'dart:typed_data'; // Import added for Uint8List
enum ContactType {
  deviceOnly,    // Contact exists only on device
  appUser,      // Contact is registered app user
  both,         // Contact exists on device and is app user
}

class ContactModel {
  final String id;
  final String displayName;
  final String? phoneNumber;
  final String? email;
  final Uint8List? photo;
  final ContactType type;

  // App user specific fields (when type includes appUser)
  final String? userId;
  final String? photoUrl;
  final String? status;
  final bool? isOnline;
  final DateTime? lastSeen;

  // Device contact specific fields
  final String? deviceContactId;
  final List<String> phoneNumbers;
  final List<String> emails;

  ContactModel({
    required this.id,
    required this.displayName,
    this.phoneNumber,
    this.email,
    this.photo,
    required this.type,
    this.userId,
    this.photoUrl,
    this.status,
    this.isOnline,
    this.lastSeen,
    this.deviceContactId,
    this.phoneNumbers = const [],
    this.emails = const [],
  });

  // Create from device contact
  factory ContactModel.fromDeviceContact(Contact deviceContact) {
    // Get primary phone and email
    final primaryPhone = deviceContact.phones.isNotEmpty
        ? deviceContact.phones.first.number.replaceAll(RegExp(r'[^\d+]'), '')
        : null;
    final primaryEmail = deviceContact.emails.isNotEmpty
        ? deviceContact.emails.first.address
        : null;

    return ContactModel(
      id: 'device_${deviceContact.id}',
      displayName: deviceContact.displayName,
      phoneNumber: primaryPhone,
      email: primaryEmail,
      photo: deviceContact.photo,
      type: ContactType.deviceOnly,
      deviceContactId: deviceContact.id,
      phoneNumbers: deviceContact.phones.map((p) => p.number.replaceAll(RegExp(r'[^\d+]'), '')).toList(),
      emails: deviceContact.emails.map((e) => e.address).toList(),
    );
  }

  // Create from Firebase user
  factory ContactModel.fromFirebaseUser(Map<String, dynamic> userData) {
    return ContactModel(
      id: 'user_${userData[FirebaseConstants.userId]}',
      displayName: userData[FirebaseConstants.displayName] ?? 'Unknown User',
      email: userData[FirebaseConstants.email],
      type: ContactType.appUser,
      userId: userData[FirebaseConstants.userId],
      photoUrl: userData[FirebaseConstants.photoUrl],
      status: userData[FirebaseConstants.status],
      isOnline: userData[FirebaseConstants.isOnline] ?? false,
      lastSeen: userData[FirebaseConstants.lastSeen]?.toDate(),
    );
  }

  // Create combined contact (device + app user)
  factory ContactModel.fromCombined({
    required ContactModel deviceContact,
    required ContactModel appUser,
  }) {
    return ContactModel(
      id: 'combined_${appUser.userId}',
      displayName: deviceContact.displayName.isNotEmpty
          ? deviceContact.displayName
          : appUser.displayName,
      phoneNumber: deviceContact.phoneNumber ?? appUser.phoneNumber,
      email: deviceContact.email ?? appUser.email,
      photo: deviceContact.photo,
      type: ContactType.both,
      userId: appUser.userId,
      photoUrl: appUser.photoUrl,
      status: appUser.status,
      isOnline: appUser.isOnline,
      lastSeen: appUser.lastSeen,
      deviceContactId: deviceContact.deviceContactId,
      phoneNumbers: deviceContact.phoneNumbers,
      emails: deviceContact.emails,
    );
  }

  // Check if contact is app user
  bool get isAppUser => type == ContactType.appUser || type == ContactType.both;

  // Check if contact is device contact
  bool get isDeviceContact => type == ContactType.deviceOnly || type == ContactType.both;

  // Get display photo (device photo preferred over URL)
  dynamic get displayPhoto => photo ?? photoUrl;

  // Get formatted phone number for display
  String? get formattedPhoneNumber {
    if (phoneNumber == null) return null;

    // Simple formatting - you can enhance this
    final cleaned = phoneNumber!.replaceAll(RegExp(r'[^\d+]'), '');
    if (cleaned.startsWith('+')) {
      return cleaned;
    } else if (cleaned.length == 10) {
      return '+1$cleaned'; // Assuming US numbers, adjust as needed
    }
    return cleaned;
  }

  // Get initials for avatar fallback
  String get initials {
    final parts = displayName.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
  }

  // Convert to map for storage/transmission
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'email': email,
      'type': type.toString(),
      'userId': userId,
      'photoUrl': photoUrl,
      'status': status,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
      'deviceContactId': deviceContactId,
      'phoneNumbers': phoneNumbers,
      'emails': emails,
    };
  }

  // Create from map
  factory ContactModel.fromMap(Map<String, dynamic> map) {
    return ContactModel(
      id: map['id'] ?? '',
      displayName: map['displayName'] ?? '',
      phoneNumber: map['phoneNumber'],
      email: map['email'],
      type: ContactType.values.firstWhere(
            (e) => e.toString() == map['type'],
        orElse: () => ContactType.deviceOnly,
      ),
      userId: map['userId'],
      photoUrl: map['photoUrl'],
      status: map['status'],
      isOnline: map['isOnline'],
      lastSeen: map['lastSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastSeen'])
          : null,
      deviceContactId: map['deviceContactId'],
      phoneNumbers: List<String>.from(map['phoneNumbers'] ?? []),
      emails: List<String>.from(map['emails'] ?? []),
    );
  }

  // Create copy with updated fields
  ContactModel copyWith({
    String? id,
    String? displayName,
    String? phoneNumber,
    String? email,
    Uint8List? photo,
    ContactType? type,
    String? userId,
    String? photoUrl,
    String? status,
    bool? isOnline,
    DateTime? lastSeen,
    String? deviceContactId,
    List<String>? phoneNumbers,
    List<String>? emails,
  }) {
    return ContactModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      photo: photo ?? this.photo,
      type: type ?? this.type,
      userId: userId ?? this.userId,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      deviceContactId: deviceContactId ?? this.deviceContactId,
      phoneNumbers: phoneNumbers ?? this.phoneNumbers,
      emails: emails ?? this.emails,
    );
  }

  @override
  String toString() {
    return 'ContactModel(id: $id, displayName: $displayName, type: $type, isAppUser: $isAppUser)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}