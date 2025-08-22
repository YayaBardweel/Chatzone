// ============================================================================
// File: lib/core/data/services/contact_service.dart
// ============================================================================

import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/contact_model.dart';
import '../../constants/firebase_constants.dart';

/// Contact service for managing device contacts and app users
class ContactService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================================
  // PERMISSION MANAGEMENT
  // ============================================================================

  /// Check if contacts permission is granted
  Future<bool> hasContactsPermission() async {
    try {
      final status = await Permission.contacts.status;
      return status.isGranted;
    } catch (e) {
      print('❌ ContactService: Error checking permission - $e');
      return false;
    }
  }

  /// Request contacts permission
  Future<ContactResult> requestContactsPermission() async {
    try {
      print('🔐 ContactService: Requesting contacts permission');

      final status = await Permission.contacts.request();

      switch (status) {
        case PermissionStatus.granted:
          print('✅ ContactService: Contacts permission granted');
          return ContactResult.success(null, message: 'Permission granted');

        case PermissionStatus.denied:
          print('❌ ContactService: Contacts permission denied');
          return ContactResult.error('Contacts permission denied');

        case PermissionStatus.permanentlyDenied:
          print('❌ ContactService: Contacts permission permanently denied');
          return ContactResult.error('Contacts permission permanently denied. Please enable in settings.');

        case PermissionStatus.restricted:
          print('❌ ContactService: Contacts permission restricted');
          return ContactResult.error('Contacts access is restricted');

        default:
          print('❌ ContactService: Unknown permission status');
          return ContactResult.error('Unable to access contacts');
      }
    } catch (e) {
      print('❌ ContactService: Error requesting permission - $e');
      return ContactResult.error('Failed to request contacts permission');
    }
  }

  /// Open app settings for permission management
  Future<void> openAppSettings() async {
    try {
      await openAppSettings();
    } catch (e) {
      print('❌ ContactService: Error opening app settings - $e');
    }
  }

  // ============================================================================
  // DEVICE CONTACTS
  // ============================================================================

  /// Fetch all device contacts
  Future<ContactResult> getDeviceContacts() async {
    try {
      print('📱 ContactService: Fetching device contacts');

      // Check permission first
      if (!await hasContactsPermission()) {
        final permissionResult = await requestContactsPermission();
        if (!permissionResult.isSuccess) {
          return permissionResult;
        }
      }

      // Fetch contacts with specific properties
      final deviceContacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );

      print('📱 ContactService: Found ${deviceContacts.length} device contacts');

      // Convert to ContactModel
      final contacts = deviceContacts
          .where((contact) =>
      contact.displayName.isNotEmpty &&
          (contact.phones.isNotEmpty || contact.emails.isNotEmpty))
          .map((contact) => ContactModel.fromDeviceContact(contact))
          .toList();

      // Sort alphabetically
      contacts.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

      print('✅ ContactService: Processed ${contacts.length} valid contacts');
      return ContactResult.success(contacts);

    } catch (e) {
      print('❌ ContactService: Error fetching device contacts - $e');
      return ContactResult.error('Failed to fetch contacts');
    }
  }

  /// Search device contacts
  Future<ContactResult> searchDeviceContacts(String query) async {
    try {
      if (query.isEmpty) {
        return getDeviceContacts();
      }

      print('🔍 ContactService: Searching device contacts for: $query');

      if (!await hasContactsPermission()) {
        return ContactResult.error('Contacts permission required');
      }

      final deviceContacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );

      final searchQuery = query.toLowerCase();
      final filteredContacts = deviceContacts
          .where((contact) {
        final name = contact.displayName.toLowerCase();
        final phoneMatch = contact.phones.any((phone) =>
            phone.number.replaceAll(RegExp(r'[^\d]'), '').contains(searchQuery));
        final emailMatch = contact.emails.any((email) =>
            email.address.toLowerCase().contains(searchQuery));

        return name.contains(searchQuery) || phoneMatch || emailMatch;
      })
          .map((contact) => ContactModel.fromDeviceContact(contact))
          .toList();

      filteredContacts.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

      print('✅ ContactService: Found ${filteredContacts.length} matching contacts');
      return ContactResult.success(filteredContacts);

    } catch (e) {
      print('❌ ContactService: Error searching contacts - $e');
      return ContactResult.error('Failed to search contacts');
    }
  }

  // ============================================================================
  // APP USERS
  // ============================================================================

  /// Find app users from device contacts
  Future<ContactResult> findAppUsers(List<ContactModel> deviceContacts) async {
    try {
      print('🔍 ContactService: Finding app users from ${deviceContacts.length} contacts');

      if (deviceContacts.isEmpty) {
        return ContactResult.success([]);
      }

      // Extract phone numbers and emails
      final phoneNumbers = <String>[];
      final emails = <String>[];

      for (final contact in deviceContacts) {
        phoneNumbers.addAll(contact.phoneNumbers);
        if (contact.email != null) emails.add(contact.email!);
      }

      // Remove duplicates and clean phone numbers
      final uniquePhones = phoneNumbers
          .map((phone) => phone.replaceAll(RegExp(r'[^\d+]'), ''))
          .where((phone) => phone.isNotEmpty)
          .toSet()
          .toList();

      final uniqueEmails = emails.toSet().toList();

      print('📱 ContactService: Searching for ${uniquePhones.length} phone numbers and ${uniqueEmails.length} emails');

      // Query Firebase for users with matching phone numbers or emails
      final List<ContactModel> appUsers = [];

      // Query by phone numbers (batch in groups of 10 due to Firestore limits)
      if (uniquePhones.isNotEmpty) {
        for (int i = 0; i < uniquePhones.length; i += 10) {
          final batch = uniquePhones.skip(i).take(10).toList();
          final query = await _firestore
              .collection(FirebaseConstants.usersCollection)
              .where('phoneNumber', whereIn: batch)
              .get();

          for (final doc in query.docs) {
            appUsers.add(ContactModel.fromFirebaseUser(doc.data()));
          }
        }
      }

      // Query by emails (batch in groups of 10)
      if (uniqueEmails.isNotEmpty) {
        for (int i = 0; i < uniqueEmails.length; i += 10) {
          final batch = uniqueEmails.skip(i).take(10).toList();
          final query = await _firestore
              .collection(FirebaseConstants.usersCollection)
              .where(FirebaseConstants.email, whereIn: batch)
              .get();

          for (final doc in query.docs) {
            final user = ContactModel.fromFirebaseUser(doc.data());
            // Avoid duplicates
            if (!appUsers.any((u) => u.userId == user.userId)) {
              appUsers.add(user);
            }
          }
        }
      }

      print('✅ ContactService: Found ${appUsers.length} app users');
      return ContactResult.success(appUsers);

    } catch (e) {
      print('❌ ContactService: Error finding app users - $e');
      return ContactResult.error('Failed to find app users');
    }
  }

  /// Get all app users (for general user discovery)
  Future<ContactResult> getAllAppUsers() async {
    try {
      print('👥 ContactService: Fetching all app users');

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        return ContactResult.error('User not authenticated');
      }

      final query = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .where(FirebaseConstants.userId, isNotEqualTo: currentUserId)
          .orderBy(FirebaseConstants.displayName)
          .get();

      final users = query.docs
          .map((doc) => ContactModel.fromFirebaseUser(doc.data()))
          .toList();

      print('✅ ContactService: Found ${users.length} app users');
      return ContactResult.success(users);

    } catch (e) {
      print('❌ ContactService: Error fetching app users - $e');
      return ContactResult.error('Failed to fetch app users');
    }
  }

  /// Search app users
  Future<ContactResult> searchAppUsers(String query) async {
    try {
      if (query.isEmpty) {
        return getAllAppUsers();
      }

      print('🔍 ContactService: Searching app users for: $query');

      final currentUserId = _auth.currentUser?.uid;
      if (currentUserId == null) {
        return ContactResult.error('User not authenticated');
      }

      // Search by display name (Firestore doesn't support case-insensitive search)
      final nameQuery = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .where(FirebaseConstants.userId, isNotEqualTo: currentUserId)
          .orderBy(FirebaseConstants.displayName)
          .get();

      // Search by email
      final emailQuery = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .where(FirebaseConstants.email, isGreaterThanOrEqualTo: query.toLowerCase())
          .where(FirebaseConstants.email, isLessThan: '${query.toLowerCase()}\uf8ff')
          .get();

      final users = <ContactModel>[];
      final seenUserIds = <String>{};

      // Filter name results
      for (final doc in nameQuery.docs) {
        final userData = doc.data();
        final displayName = userData[FirebaseConstants.displayName] ?? '';
        if (displayName.toLowerCase().contains(query.toLowerCase())) {
          final user = ContactModel.fromFirebaseUser(userData);
          if (!seenUserIds.contains(user.userId)) {
            users.add(user);
            seenUserIds.add(user.userId!);
          }
        }
      }

      // Add email results
      for (final doc in emailQuery.docs) {
        final user = ContactModel.fromFirebaseUser(doc.data());
        if (!seenUserIds.contains(user.userId)) {
          users.add(user);
          seenUserIds.add(user.userId!);
        }
      }

      users.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

      print('✅ ContactService: Found ${users.length} matching users');
      return ContactResult.success(users);

    } catch (e) {
      print('❌ ContactService: Error searching app users - $e');
      return ContactResult.error('Failed to search app users');
    }
  }

  // ============================================================================
  // COMBINED CONTACTS
  // ============================================================================

  /// Get combined contacts (device contacts + app users)
  Future<ContactResult> getCombinedContacts() async {
    try {
      print('🔄 ContactService: Getting combined contacts');

      // Get device contacts
      final deviceResult = await getDeviceContacts();
      if (!deviceResult.isSuccess) {
        return deviceResult;
      }

      final deviceContacts = deviceResult.data as List<ContactModel>;

      // Find app users from device contacts
      final appUsersResult = await findAppUsers(deviceContacts);
      if (!appUsersResult.isSuccess) {
        return appUsersResult;
      }

      final appUsers = appUsersResult.data as List<ContactModel>;

      // Combine contacts
      final combinedContacts = <ContactModel>[];
      final processedUserIds = <String>{};

      // First, add combined contacts (device contact + app user)
      for (final deviceContact in deviceContacts) {
        ContactModel? matchingUser;

        // Try to find matching app user by phone or email
        for (final appUser in appUsers) {
          if (processedUserIds.contains(appUser.userId)) continue;

          final phoneMatch = deviceContact.phoneNumbers.any((phone) =>
          appUser.phoneNumber != null &&
              phone.replaceAll(RegExp(r'[^\d+]'), '') == appUser.phoneNumber);

          final emailMatch = deviceContact.emails.any((email) =>
          appUser.email != null &&
              email.toLowerCase() == appUser.email!.toLowerCase());

          if (phoneMatch || emailMatch) {
            matchingUser = appUser;
            processedUserIds.add(appUser.userId!);
            break;
          }
        }

        if (matchingUser != null) {
          // Create combined contact
          combinedContacts.add(ContactModel.fromCombined(
            deviceContact: deviceContact,
            appUser: matchingUser,
          ));
        } else {
          // Add as device-only contact
          combinedContacts.add(deviceContact);
        }
      }

      // Add remaining app users that weren't matched
      for (final appUser in appUsers) {
        if (!processedUserIds.contains(appUser.userId)) {
          combinedContacts.add(appUser);
        }
      }

      // Sort alphabetically
      combinedContacts.sort((a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

      print('✅ ContactService: Combined ${combinedContacts.length} contacts');
      return ContactResult.success(combinedContacts);

    } catch (e) {
      print('❌ ContactService: Error getting combined contacts - $e');
      return ContactResult.error('Failed to get contacts');
    }
  }

  // ============================================================================
  // USER PROFILE MANAGEMENT
  // ============================================================================

  /// Update user profile with phone number
  Future<ContactResult> updateUserProfile({
    String? phoneNumber,
    String? displayName,
    String? status,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        return ContactResult.error('User not authenticated');
      }

      print('👤 ContactService: Updating user profile');

      final updates = <String, dynamic>{
        FirebaseConstants.updatedAt: FieldValue.serverTimestamp(),
      };

      if (phoneNumber != null) {
        updates['phoneNumber'] = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      }

      if (displayName != null) {
        updates[FirebaseConstants.displayName] = displayName;
      }

      if (status != null) {
        updates[FirebaseConstants.status] = status;
      }

      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(currentUser.uid)
          .update(updates);

      print('✅ ContactService: User profile updated');
      return ContactResult.success(null, message: 'Profile updated successfully');

    } catch (e) {
      print('❌ ContactService: Error updating user profile - $e');
      return ContactResult.error('Failed to update profile');
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Normalize phone number for comparison
  String normalizePhoneNumber(String phoneNumber) {
    return phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
  }

  /// Check if two phone numbers match
  bool phoneNumbersMatch(String phone1, String phone2) {
    final normalized1 = normalizePhoneNumber(phone1);
    final normalized2 = normalizePhoneNumber(phone2);

    // Direct match
    if (normalized1 == normalized2) return true;

    // Check if one has country code and other doesn't
    if (normalized1.length != normalized2.length) {
      final longer = normalized1.length > normalized2.length ? normalized1 : normalized2;
      final shorter = normalized1.length > normalized2.length ? normalized2 : normalized1;

      return longer.endsWith(shorter);
    }

    return false;
  }

  /// Get contact by user ID
  Future<ContactResult> getContactByUserId(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists) {
        return ContactResult.error('User not found');
      }

      final contact = ContactModel.fromFirebaseUser(doc.data()!);
      return ContactResult.success(contact);

    } catch (e) {
      print('❌ ContactService: Error getting contact by user ID - $e');
      return ContactResult.error('Failed to get contact');
    }
  }
}

// ============================================================================
// RESULT CLASS
// ============================================================================

/// Contact operation result wrapper
class ContactResult {
  final bool isSuccess;
  final dynamic data;
  final String? error;
  final String? message;

  ContactResult._(this.isSuccess, this.data, this.error, this.message);

  /// Create success result
  factory ContactResult.success(dynamic data, {String? message}) {
    return ContactResult._(true, data, null, message);
  }

  /// Create error result
  factory ContactResult.error(String error) {
    return ContactResult._(false, null, error, null);
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'ContactResult.success(data: $data, message: $message)';
    } else {
      return 'ContactResult.error(error: $error)';
    }
  }
}