// ============================================================================
// File: lib/core/data/repositories/user_repository.dart
// ============================================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import '../../constants/firebase_constants.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class UserRepository {
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================================
  // USER CRUD OPERATIONS
  // ============================================================================

  /// Create user document in Firestore
  Future<void> createUser(UserModel user) async {
    try {
      print('🔥 UserRepository: Creating user ${user.userId}');
      await _firestoreService.setDocument(
        collection: FirebaseConstants.usersCollection,
        documentId: user.userId,
        data: user.toMap(),
      );
      print('✅ UserRepository: User created successfully');
    } catch (e) {
      print('❌ UserRepository: Create user failed - $e');
      throw Exception('Failed to create user profile');
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      print('🔍 UserRepository: Getting user $userId');
      final data = await _firestoreService.getDocument(
        collection: FirebaseConstants.usersCollection,
        documentId: userId,
      );

      if (data != null) {
        final user = UserModel.fromMap(data);
        print('✅ UserRepository: User found - ${user.email}');
        return user;
      }

      print('⚠️ UserRepository: User not found');
      return null;
    } catch (e) {
      print('❌ UserRepository: Get user failed - $e');
      throw Exception('Failed to get user data');
    }
  }

  /// Get current user data
  Future<UserModel?> getCurrentUser() async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    return await getUserById(currentUser.uid);
  }

  /// Update user data
  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      print('🔥 UserRepository: Updating user $userId');

      // Add updated timestamp
      updates[FirebaseConstants.updatedAt] = FieldValue.serverTimestamp();

      await _firestoreService.updateDocument(
        collection: FirebaseConstants.usersCollection,
        documentId: userId,
        data: updates,
      );

      print('✅ UserRepository: User updated successfully');
    } catch (e) {
      print('❌ UserRepository: Update user failed - $e');
      throw Exception('Failed to update user profile');
    }
  }

  /// Update current user
  Future<void> updateCurrentUser(Map<String, dynamic> updates) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user');
    }

    await updateUser(currentUser.uid, updates);
  }

  /// Delete user (soft delete - mark as deleted)
  Future<void> deleteUser(String userId) async {
    try {
      print('🔥 UserRepository: Deleting user $userId');
      await updateUser(userId, {
        'isDeleted': true,
        'deletedAt': FieldValue.serverTimestamp(),
      });
      print('✅ UserRepository: User deleted successfully');
    } catch (e) {
      print('❌ UserRepository: Delete user failed - $e');
      throw Exception('Failed to delete user');
    }
  }

  // ============================================================================
  // USER SEARCH & DISCOVERY
  // ============================================================================

  /// Search users by email
  Future<List<UserModel>> searchUsersByEmail(String email) async {
    try {
      print('🔍 UserRepository: Searching users by email: $email');

      final querySnapshot = await _firestoreService.queryDocuments(
        collection: FirebaseConstants.usersCollection,
        field: FirebaseConstants.email,
        isEqualTo: email.toLowerCase(),
      );

      final users = querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
          .where((user) => user.userId != _auth.currentUser?.uid) // Exclude current user
          .toList();

      print('✅ UserRepository: Found ${users.length} users');
      return users;
    } catch (e) {
      print('❌ UserRepository: Search users failed - $e');
      throw Exception('Failed to search users');
    }
  }

  /// Get users by IDs
  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    try {
      print('🔍 UserRepository: Getting users by IDs');

      if (userIds.isEmpty) return [];

      // Firestore 'in' queries are limited to 10 items
      final List<UserModel> allUsers = [];

      for (int i = 0; i < userIds.length; i += 10) {
        final chunk = userIds.skip(i).take(10).toList();

        final querySnapshot = await FirebaseFirestore.instance
            .collection(FirebaseConstants.usersCollection)
            .where(FirebaseConstants.userId, whereIn: chunk)
            .get();

        final users = querySnapshot.docs
            .map((doc) => UserModel.fromMap(doc.data()))
            .toList();

        allUsers.addAll(users);
      }

      print('✅ UserRepository: Found ${allUsers.length} users');
      return allUsers;
    } catch (e) {
      print('❌ UserRepository: Get users by IDs failed - $e');
      throw Exception('Failed to get users');
    }
  }

  // ============================================================================
  // PROFILE PHOTO MANAGEMENT
  // ============================================================================

  /// Upload profile photo
  Future<String> uploadProfilePhoto(String userId, File imageFile) async {
    try {
      print('🔥 UserRepository: Uploading profile photo for $userId');

      final downloadUrl = await _storageService.uploadFile(
        file: imageFile,
        path: '${FirebaseConstants.userProfileImages}/$userId.jpg',
      );

      // Update user document with new photo URL
      await updateUser(userId, {
        FirebaseConstants.photoUrl: downloadUrl,
      });

      print('✅ UserRepository: Profile photo uploaded successfully');
      return downloadUrl;
    } catch (e) {
      print('❌ UserRepository: Upload profile photo failed - $e');
      throw Exception('Failed to upload profile photo');
    }
  }

  /// Delete profile photo
  Future<void> deleteProfilePhoto(String userId) async {
    try {
      print('🔥 UserRepository: Deleting profile photo for $userId');

      // Delete from storage
      await _storageService.deleteFile(
        path: '${FirebaseConstants.userProfileImages}/$userId.jpg',
      );

      // Update user document
      await updateUser(userId, {
        FirebaseConstants.photoUrl: FirebaseConstants.defaultProfileImage,
      });

      print('✅ UserRepository: Profile photo deleted successfully');
    } catch (e) {
      print('❌ UserRepository: Delete profile photo failed - $e');
      throw Exception('Failed to delete profile photo');
    }
  }

  // ============================================================================
  // ONLINE STATUS MANAGEMENT
  // ============================================================================

  /// Update user online status
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      final updates = {
        FirebaseConstants.isOnline: isOnline,
        FirebaseConstants.lastSeen: FieldValue.serverTimestamp(),
      };

      await updateUser(userId, updates);
      print('✅ UserRepository: Online status updated - $isOnline');
    } catch (e) {
      print('❌ UserRepository: Update online status failed - $e');
      // Don't throw - this is non-critical
    }
  }

  /// Set current user online
  Future<void> setCurrentUserOnline() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await updateOnlineStatus(currentUser.uid, true);
    }
  }

  /// Set current user offline
  Future<void> setCurrentUserOffline() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      await updateOnlineStatus(currentUser.uid, false);
    }
  }

  // ============================================================================
  // USER STATUS/ABOUT MANAGEMENT
  // ============================================================================

  /// Update user status/about
  Future<void> updateUserStatus(String userId, String status) async {
    try {
      await updateUser(userId, {
        FirebaseConstants.status: status,
      });
      print('✅ UserRepository: User status updated');
    } catch (e) {
      print('❌ UserRepository: Update status failed - $e');
      throw Exception('Failed to update status');
    }
  }

  /// Update current user status
  Future<void> updateCurrentUserStatus(String status) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user');
    }

    await updateUserStatus(currentUser.uid, status);
  }

  // ============================================================================
  // REAL-TIME STREAMS
  // ============================================================================

  /// Stream current user data
  Stream<UserModel?> getCurrentUserStream() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return Stream.value(null);
    }

    return _firestoreService.streamDocument(
      collection: FirebaseConstants.usersCollection,
      documentId: currentUser.uid,
    ).map((data) {
      if (data != null) {
        return UserModel.fromMap(data);
      }
      return null;
    });
  }

  /// Stream user data by ID
  Stream<UserModel?> getUserStream(String userId) {
    return _firestoreService.streamDocument(
      collection: FirebaseConstants.usersCollection,
      documentId: userId,
    ).map((data) {
      if (data != null) {
        return UserModel.fromMap(data);
      }
      return null;
    });
  }

  /// Stream multiple users by IDs
  Stream<List<UserModel>> getUsersStream(List<String> userIds) {
    if (userIds.isEmpty) {
      return Stream.value([]);
    }

    return FirebaseFirestore.instance
        .collection(FirebaseConstants.usersCollection)
        .where(FirebaseConstants.userId, whereIn: userIds.take(10).toList())
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromMap(doc.data()))
          .toList();
    });
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Check if user exists
  Future<bool> userExists(String userId) async {
    try {
      final data = await _firestoreService.getDocument(
        collection: FirebaseConstants.usersCollection,
        documentId: userId,
      );
      return data != null;
    } catch (e) {
      print('❌ UserRepository: Check user exists failed - $e');
      return false;
    }
  }

  /// Get user count (for admin purposes)
  Future<int> getUserCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(FirebaseConstants.usersCollection)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('❌ UserRepository: Get user count failed - $e');
      return 0;
    }
  }

  /// Create user from Firebase Auth user
  Future<UserModel> createUserFromFirebaseUser(User firebaseUser, {String? displayName}) async {
    final user = UserModel(
      userId: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      emailVerified: firebaseUser.emailVerified,
      displayName: displayName ?? firebaseUser.displayName ?? firebaseUser.email?.split('@')[0] ?? 'User',
      photoUrl: firebaseUser.photoURL ,
      status: FirebaseConstants.defaultStatus,
      isOnline: true,
      lastSeen: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await createUser(user);
    return user;
  }
}