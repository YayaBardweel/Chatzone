// ============================================================================
// File: lib/core/services/auth_service.dart (CLEAN REBUILD)
// ============================================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Simple, clean authentication service
/// Handles only Firebase Auth operations - no state management
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================================
  // GETTERS
  // ============================================================================

  /// Current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  /// Stream of authentication state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Check if email is verified
  bool get isEmailVerified => _auth.currentUser?.emailVerified ?? false;

  // ============================================================================
  // SIGN UP
  // ============================================================================

  /// Create new account with email and password
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    User? createdUser;

    try {
      print('🔥 AuthService: Creating account for $email');

      // Step 1: Create account with retry mechanism for PigeonUserDetails bug
      print('📝 Step 1: Creating Firebase Auth account...');

      UserCredential? userCredential;
      int retryCount = 0;
      const maxRetries = 3;

      while (userCredential == null && retryCount < maxRetries) {
        try {
          retryCount++;
          print('🔄 Attempt $retryCount/$maxRetries to create account...');

          userCredential = await _auth.createUserWithEmailAndPassword(
            email: email.trim().toLowerCase(),
            password: password,
          );

          print('✅ Account creation successful on attempt $retryCount');
          break;

        } catch (e) {
          print('❌ Attempt $retryCount failed: $e');

          if (e.toString().contains('PigeonUserDetails') ||
              e.toString().contains('List<Object?>')) {

            print('🔄 PigeonUserDetails error detected, retrying...');

            // Wait before retry
            await Future.delayed(Duration(milliseconds: 500 * retryCount));

            // Check if user was actually created despite the error
            await Future.delayed(const Duration(milliseconds: 500));
            final currentUser = _auth.currentUser;

            if (currentUser != null && currentUser.email?.toLowerCase() == email.toLowerCase()) {
              print('✅ User was created despite error! Using existing user.');
              // Create a mock UserCredential since the real one failed
              createdUser = currentUser;
              break;
            }

            if (retryCount >= maxRetries) {
              throw e;
            }
          } else {
            // Different error, don't retry
            throw e;
          }
        }
      }

      // If we have a UserCredential, get the user from it
      if (userCredential != null) {
        createdUser = userCredential.user!;
      }

      // If we still don't have a user, check current user one more time
      if (createdUser == null) {
        createdUser = _auth.currentUser;
      }

      if (createdUser == null) {
        throw Exception('Failed to create user after $maxRetries attempts');
      }

      print('✅ Step 1: Account confirmed - ${createdUser.uid}');

      // Step 2: Update display name if provided
      if (displayName != null && displayName.isNotEmpty) {
        try {
          print('📝 Step 2: Updating display name...');
          await createdUser.updateDisplayName(displayName);
          print('✅ Step 2: Display name updated to: $displayName');
        } catch (e) {
          print('⚠️ Step 2: Display name update failed (non-critical) - $e');
        }
      } else {
        print('⏭️ Step 2: Skipping display name update (not provided)');
      }

      // Step 3: Create user document in Firestore
      try {
        print('📝 Step 3: Creating Firestore document...');
        await _createUserDocument(createdUser, displayName);
        print('✅ Step 3: Firestore document created');
      } catch (e) {
        print('⚠️ Step 3: Firestore document creation failed (non-critical) - $e');
      }

      // Step 4: Send email verification with delay
      try {
        print('📝 Step 4: Sending email verification...');
        // Longer delay to avoid the PigeonUserDetails bug
        await Future.delayed(const Duration(milliseconds: 2000));

        // Get fresh user reference
        final freshUser = _auth.currentUser;
        if (freshUser != null) {
          await freshUser.sendEmailVerification();
          print('✅ Step 4: Verification email sent');
        } else {
          print('⚠️ Step 4: No current user found for email verification');
        }
      } catch (e) {
        print('⚠️ Step 4: Email verification failed - $e');
        // Don't fail the entire signup process for this
      }

      print('✅ AuthService: SignUp process completed successfully');
      return AuthResult.success(createdUser);

    } on FirebaseAuthException catch (e) {
      print('❌ AuthService: Firebase Auth failed - ${e.code}: ${e.message}');

      // Special handling for email-already-in-use after PigeonUserDetails error
      if (e.code == 'email-already-in-use') {
        print('🔍 Email already exists, checking if it was just created...');
        final currentUser = _auth.currentUser;
        if (currentUser != null && currentUser.email?.toLowerCase() == email.toLowerCase()) {
          print('✅ Found existing user with same email, using it');
          return AuthResult.success(currentUser);
        }
      }

      return AuthResult.error(_getErrorMessage(e.code));
    } catch (e) {
      print('❌ AuthService: SignUp failed - $e');
      print('❌ AuthService: Error type: ${e.runtimeType}');

      // If user was created but something else failed, still return success
      if (createdUser != null) {
        print('⚠️ AuthService: User was created despite error, returning success');
        return AuthResult.success(createdUser);
      }

      // Final fallback: check if user exists in Firebase Auth
      final currentUser = _auth.currentUser;
      if (currentUser != null && currentUser.email?.toLowerCase() == email.toLowerCase()) {
        print('✅ AuthService: Found user in Firebase Auth despite error');
        return AuthResult.success(currentUser);
      }

      return AuthResult.error('Account creation failed. Please try again.');
    }
  }

  // ============================================================================
  // SIGN IN
  // ============================================================================

  /// Sign in with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔥 AuthService: Signing in $email');

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );

      final user = userCredential.user!;
      print('✅ AuthService: Signed in - ${user.uid}');

      return AuthResult.success(user);
    } on FirebaseAuthException catch (e) {
      print('❌ AuthService: SignIn failed - ${e.code}');
      return AuthResult.error(_getErrorMessage(e.code));
    } catch (e) {
      print('❌ AuthService: SignIn failed - $e');
      return AuthResult.error('Sign in failed. Please try again.');
    }
  }

  // ============================================================================
  // EMAIL VERIFICATION
  // ============================================================================

  /// Send email verification to current user
  Future<AuthResult> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.error('No user signed in');
      }

      if (user.emailVerified) {
        return AuthResult.success(user, message: 'Email already verified');
      }

      await user.sendEmailVerification();
      print('✅ AuthService: Email verification sent');

      return AuthResult.success(user, message: 'Verification email sent');
    } catch (e) {
      print('❌ AuthService: Send verification failed - $e');
      return AuthResult.error('Failed to send verification email');
    }
  }

  /// Check if email is verified (refreshes from server)
  Future<bool> checkEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ AuthService: No current user for verification check');
        return false;
      }

      print('🔍 AuthService: Current user before reload: ${user.email}, verified: ${user.emailVerified}');

      // Debug: Check what type of data we're dealing with
      print('🔍 AuthService: User object type: ${user.runtimeType}');

      // Instead of reload(), get fresh ID token which forces refresh
      try {
        await user.getIdToken(true); // Force refresh
        print('✅ AuthService: ID token refreshed successfully');
      } catch (tokenError) {
        print('⚠️ AuthService: Token refresh failed, trying reload: $tokenError');
        // Fallback to reload if token refresh fails
        await user.reload();
      }

      // Get the refreshed user
      final updatedUser = _auth.currentUser;
      if (updatedUser == null) {
        print('❌ AuthService: User became null after refresh');
        return false;
      }

      final isVerified = updatedUser.emailVerified;
      print('📧 AuthService: Email verified = $isVerified');
      return isVerified;
    } catch (e) {
      print('❌ AuthService: Check verification failed - $e');
      print('❌ AuthService: Error type: ${e.runtimeType}');

      // Fallback: just return current cached status without refresh
      final user = _auth.currentUser;
      final cachedStatus = user?.emailVerified ?? false;
      print('📧 AuthService: Using cached verification status: $cachedStatus');
      return cachedStatus;
    }
  }

  // ============================================================================
  // PASSWORD RESET
  // ============================================================================

  /// Send password reset email
  Future<AuthResult> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(
        email: email.trim().toLowerCase(),
      );

      print('✅ AuthService: Password reset sent to $email');
      return AuthResult.success(null, message: 'Password reset email sent');
    } on FirebaseAuthException catch (e) {
      print('❌ AuthService: Password reset failed - ${e.code}');
      return AuthResult.error(_getErrorMessage(e.code));
    } catch (e) {
      print('❌ AuthService: Password reset failed - $e');
      return AuthResult.error('Failed to send password reset email');
    }
  }

  // ============================================================================
  // SIGN OUT
  // ============================================================================

  /// Sign out current user
  Future<AuthResult> signOut() async {
    try {
      await _auth.signOut();
      print('✅ AuthService: Signed out');
      return AuthResult.success(null, message: 'Signed out successfully');
    } catch (e) {
      print('❌ AuthService: Sign out failed - $e');
      return AuthResult.error('Failed to sign out');
    }
  }

  // ============================================================================
  // USER DATA METHODS
  // ============================================================================

  /// Get user data from Firestore safely
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      print('🔍 AuthService: Fetching user data for $uid');

      final docSnapshot = await _firestore.collection('users').doc(uid).get();

      print('🔍 AuthService: Document exists: ${docSnapshot.exists}');

      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        print('🔍 AuthService: Document data type: ${data.runtimeType}');
        print('🔍 AuthService: Document data: $data');

        // Ensure we're returning a Map, not a List
        if (data is Map<String, dynamic>) {
          return data;
        } else {
          print('❌ AuthService: Unexpected data type: ${data.runtimeType}');
          return null;
        }
      } else {
        print('❌ AuthService: User document does not exist');
        return null;
      }
    } catch (e) {
      print('❌ AuthService: Failed to get user data - $e');
      print('❌ AuthService: Error type: ${e.runtimeType}');
      return null;
    }
  }

  /// Get current user's Firestore data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = currentUser;
    if (user == null) {
      print('❌ AuthService: No current user for data fetch');
      return null;
    }

    return await getUserData(user.uid);
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Create user document in Firestore
  Future<void> _createUserDocument(User user, String? displayName) async {
    try {
      print('🔥 AuthService: Creating Firestore document for ${user.uid}');

      // Debug: Check user object properties
      print('🔍 AuthService: User email: ${user.email}');
      print('🔍 AuthService: User displayName: ${user.displayName}');
      print('🔍 AuthService: User emailVerified: ${user.emailVerified}');

      final userData = <String, dynamic>{
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': displayName ?? user.displayName ?? user.email?.split('@')[0] ?? 'User',
        'photoURL': user.photoURL ?? '',
        'emailVerified': user.emailVerified,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignIn': FieldValue.serverTimestamp(),
        'isOnline': true,
      };

      print('🔍 AuthService: User data to save: $userData');

      // Use set with merge to avoid overwriting existing data
      await _firestore.collection('users').doc(user.uid).set(
        userData,
        SetOptions(merge: true),
      );

      print('✅ AuthService: Firestore document created/updated successfully');
    } catch (e) {
      print('❌ AuthService: Failed to create user document - $e');
      print('❌ AuthService: Error type: ${e.runtimeType}');
      print('❌ AuthService: Error details: ${e.toString()}');
      // Don't throw - account creation was successful
    }
  }

  /// Get user-friendly error messages
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'Password is too weak. Please choose a stronger password.';
      case 'email-already-in-use':
        return 'An account already exists with this email address.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'network-request-failed':
        return 'Network error. Please check your internet connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

// ============================================================================
// RESULT CLASS
// ============================================================================

/// Authentication result wrapper
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? error;
  final String? message;

  AuthResult._(this.isSuccess, this.user, this.error, this.message);

  /// Create success result
  factory AuthResult.success(User? user, {String? message}) {
    return AuthResult._(true, user, null, message);
  }

  /// Create error result
  factory AuthResult.error(String error) {
    return AuthResult._(false, null, error, null);
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'AuthResult.success(user: ${user?.email}, message: $message)';
    } else {
      return 'AuthResult.error(error: $error)';
    }
  }
}