// ============================================================================
// File: lib/core/providers/user_provider.dart
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'dart:io';
import '../data/models/user_model.dart';
import '../data/repositories/user_repository.dart';

/// Provider for managing user state and operations
class UserProvider extends ChangeNotifier {
  final UserRepository _userRepository = UserRepository();

  // ============================================================================
  // PRIVATE STATE
  // ============================================================================

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;
  StreamSubscription<UserModel?>? _userSubscription;

  // ============================================================================
  // PUBLIC GETTERS
  // ============================================================================

  /// Current user data
  UserModel? get currentUser => _currentUser;

  /// Loading state
  bool get isLoading => _isLoading;

  /// Error message
  String? get error => _error;

  /// Is provider initialized
  bool get isInitialized => _isInitialized;

  /// User ID
  String? get userId => _currentUser?.userId;

  /// User email
  String? get userEmail => _currentUser?.email;

  /// User display name
  String get displayName => _currentUser?.displayName ?? 'User';

  /// User status
  String get userStatus => _currentUser?.status ?? 'Hey there! I am using ChatZone.';

  /// User photo URL
  String? get photoUrl => _currentUser?.photoUrl;

  /// Is user online
  bool get isOnline => _currentUser?.isOnline ?? false;

  /// Last seen
  DateTime? get lastSeen => _currentUser?.lastSeen;

  /// Is email verified
  bool get isEmailVerified => _currentUser?.emailVerified ?? false;

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  UserProvider() {
    _initialize();
  }

  /// Initialize user provider
  Future<void> _initialize() async {
    try {
      print('🔥 UserProvider: Initializing...');

      // Get current user if exists
      await refreshCurrentUser();

      // Start listening to user data changes
      _startUserSubscription();

      _isInitialized = true;
      print('✅ UserProvider: Initialized successfully');
      notifyListeners();

    } catch (e) {
      print('❌ UserProvider: Initialization failed - $e');
      _setError('Failed to initialize user data');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Start subscription to current user data
  void _startUserSubscription() {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    _userSubscription = _userRepository.getCurrentUserStream().listen(
          (user) {
        print('🔄 UserProvider: User data updated');
        _currentUser = user;
        notifyListeners();
      },
      onError: (error) {
        print('❌ UserProvider: User stream error - $error');
        _setError('Failed to sync user data');
      },
    );
  }

  /// Stop user subscription
  void _stopUserSubscription() {
    _userSubscription?.cancel();
    _userSubscription = null;
  }

  // ============================================================================
  // USER DATA OPERATIONS
  // ============================================================================

  /// Refresh current user data
  Future<void> refreshCurrentUser() async {
    try {
      print('🔄 UserProvider: Refreshing current user');

      _setLoading(true);
      _clearError();

      final user = await _userRepository.getCurrentUser();

      if (user != null) {
        _currentUser = user;
        print('✅ UserProvider: Current user refreshed - ${user.email}');
      } else {
        print('⚠️ UserProvider: No current user found');
        _currentUser = null;
      }

      _setLoading(false);

    } catch (e) {
      print('❌ UserProvider: Refresh current user failed - $e');
      _setError('Failed to refresh user data');
    }
  }

  /// Create user from Firebase Auth user
  Future<void> createUserFromFirebaseUser(User firebaseUser, {String? displayName}) async {
    try {
      print('🔥 UserProvider: Creating user from Firebase user');

      _setLoading(true);
      _clearError();

      final user = await _userRepository.createUserFromFirebaseUser(
        firebaseUser,
        displayName: displayName,
      );

      _currentUser = user;
      _setLoading(false);

      print('✅ UserProvider: User created successfully');

    } catch (e) {
      print('❌ UserProvider: Create user failed - $e');
      _setError('Failed to create user profile');
    }
  }

  /// Update current user data
  Future<bool> updateUser(Map<String, dynamic> updates) async {
    try {
      print('🔥 UserProvider: Updating user data');

      _setLoading(true);
      _clearError();

      await _userRepository.updateCurrentUser(updates);

      // Update local state
      if (_currentUser != null) {
        final updatedUser = _currentUser!.copyWith(
          displayName: updates['displayName'] ?? _currentUser!.displayName,
          status: updates['status'] ?? _currentUser!.status,
          photoUrl: updates['photoUrl'] ?? _currentUser!.photoUrl,
          updatedAt: DateTime.now(),
        );
        _currentUser = updatedUser;
      }

      _setLoading(false);
      print('✅ UserProvider: User updated successfully');
      return true;

    } catch (e) {
      print('❌ UserProvider: Update user failed - $e');
      _setError('Failed to update profile');
      return false;
    }
  }

  /// Update display name
  Future<bool> updateDisplayName(String displayName) async {
    return await updateUser({'displayName': displayName});
  }

  /// Update user status
  Future<bool> updateStatus(String status) async {
    return await updateUser({'status': status});
  }

  // ============================================================================
  // PROFILE PHOTO OPERATIONS
  // ============================================================================

  /// Upload profile photo
  Future<bool> uploadProfilePhoto(File imageFile) async {
    try {
      print('🔥 UserProvider: Uploading profile photo');

      if (_currentUser == null) {
        _setError('No user logged in');
        return false;
      }

      _setLoading(true);
      _clearError();

      final downloadUrl = await _userRepository.uploadProfilePhoto(
        _currentUser!.userId,
        imageFile,
      );

      // Update local state
      _currentUser = _currentUser!.copyWith(
        photoUrl: downloadUrl,
        updatedAt: DateTime.now(),
      );

      _setLoading(false);
      print('✅ UserProvider: Profile photo uploaded successfully');
      return true;

    } catch (e) {
      print('❌ UserProvider: Upload profile photo failed - $e');
      _setError('Failed to upload profile photo');
      return false;
    }
  }

  /// Delete profile photo
  Future<bool> deleteProfilePhoto() async {
    try {
      print('🔥 UserProvider: Deleting profile photo');

      if (_currentUser == null) {
        _setError('No user logged in');
        return false;
      }

      _setLoading(true);
      _clearError();

      await _userRepository.deleteProfilePhoto(_currentUser!.userId);

      // Update local state
      _currentUser = _currentUser!.copyWith(
        photoUrl: 'https://via.placeholder.com/150/075E54/FFFFFF?text=User',
        updatedAt: DateTime.now(),
      );

      _setLoading(false);
      print('✅ UserProvider: Profile photo deleted successfully');
      return true;

    } catch (e) {
      print('❌ UserProvider: Delete profile photo failed - $e');
      _setError('Failed to delete profile photo');
      return false;
    }
  }

  // ============================================================================
  // ONLINE STATUS MANAGEMENT
  // ============================================================================

  /// Set user online
  Future<void> setUserOnline() async {
    try {
      if (_currentUser == null) return;

      await _userRepository.setCurrentUserOnline();

      // Update local state
      _currentUser = _currentUser!.copyWith(
        isOnline: true,
        lastSeen: DateTime.now(),
      );

      notifyListeners();
      print('🟢 UserProvider: User set online');

    } catch (e) {
      print('❌ UserProvider: Set user online failed - $e');
      // Don't show error to user - this is background operation
    }
  }

  /// Set user offline
  Future<void> setUserOffline() async {
    try {
      if (_currentUser == null) return;

      await _userRepository.setCurrentUserOffline();

      // Update local state
      _currentUser = _currentUser!.copyWith(
        isOnline: false,
        lastSeen: DateTime.now(),
      );

      notifyListeners();
      print('🔴 UserProvider: User set offline');

    } catch (e) {
      print('❌ UserProvider: Set user offline failed - $e');
      // Don't show error to user - this is background operation
    }
  }

  // ============================================================================
  // USER SEARCH & DISCOVERY
  // ============================================================================

  /// Search users by email
  Future<List<UserModel>> searchUsersByEmail(String email) async {
    try {
      print('🔍 UserProvider: Searching users by email');

      _setLoading(true);
      _clearError();

      final users = await _userRepository.searchUsersByEmail(email);

      _setLoading(false);
      print('✅ UserProvider: Found ${users.length} users');
      return users;

    } catch (e) {
      print('❌ UserProvider: Search users failed - $e');
      _setError('Failed to search users');
      return [];
    }
  }

  /// Get users by IDs
  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    try {
      if (userIds.isEmpty) return [];

      print('🔍 UserProvider: Getting users by IDs');

      _setLoading(true);
      _clearError();

      final users = await _userRepository.getUsersByIds(userIds);

      _setLoading(false);
      print('✅ UserProvider: Retrieved ${users.length} users');
      return users;

    } catch (e) {
      print('❌ UserProvider: Get users by IDs failed - $e');
      _setError('Failed to get users');
      return [];
    }
  }

  /// Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      print('🔍 UserProvider: Getting user by ID');

      _setLoading(true);
      _clearError();

      final user = await _userRepository.getUserById(userId);

      _setLoading(false);

      if (user != null) {
        print('✅ UserProvider: User found - ${user.email}');
      } else {
        print('⚠️ UserProvider: User not found');
      }

      return user;

    } catch (e) {
      print('❌ UserProvider: Get user by ID failed - $e');
      _setError('Failed to get user');
      return null;
    }
  }

  // ============================================================================
  // REAL-TIME USER STREAMS
  // ============================================================================

  /// Get user stream by ID
  Stream<UserModel?> getUserStream(String userId) {
    return _userRepository.getUserStream(userId);
  }

  /// Get multiple users stream
  Stream<List<UserModel>> getUsersStream(List<String> userIds) {
    return _userRepository.getUsersStream(userIds);
  }

  // ============================================================================
  // STATE MANAGEMENT
  // ============================================================================

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear error (public method)
  void clearError() {
    _clearError();
  }

  /// Clear user data (on logout)
  void clearUserData() {
    print('🗑️ UserProvider: Clearing user data');

    _stopUserSubscription();
    _currentUser = null;
    _isLoading = false;
    _error = null;

    notifyListeners();
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Check if user exists
  Future<bool> userExists(String userId) async {
    try {
      return await _userRepository.userExists(userId);
    } catch (e) {
      print('❌ UserProvider: Check user exists failed - $e');
      return false;
    }
  }

  /// Get user data summary for debugging
  Map<String, dynamic> getUserSummary() {
    return {
      'userId': userId,
      'email': userEmail,
      'displayName': displayName,
      'isOnline': isOnline,
      'isEmailVerified': isEmailVerified,
      'hasPhoto': photoUrl != null,
      'isInitialized': isInitialized,
      'isLoading': isLoading,
      'error': error,
    };
  }

  /// Format last seen time
  String formatLastSeen() {
    if (_currentUser?.isOnline == true) {
      return 'Online';
    }

    final lastSeen = _currentUser?.lastSeen;
    if (lastSeen == null) {
      return 'Last seen recently';
    }

    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Last seen just now';
    } else if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Last seen yesterday';
    } else if (difference.inDays < 7) {
      return 'Last seen ${difference.inDays}d ago';
    } else {
      return 'Last seen ${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }

  // ============================================================================
  // CLEANUP
  // ============================================================================

  @override
  void dispose() {
    print('🗑️ UserProvider: Disposing...');
    _stopUserSubscription();
    super.dispose();
  }
}