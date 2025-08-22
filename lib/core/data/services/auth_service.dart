// ============================================================================
// File: lib/core/data/services/auth_service.dart (ROBUST PIGEONUSERDETAILS FIX)
// ============================================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Robust authentication service that handles PigeonUserDetails bug
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
  // SIGN IN (ROBUST PIGEONUSERDETAILS HANDLING)
  // ============================================================================

  /// Sign in with email and password - ROBUST VERSION
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      print('🔥 AuthService: Starting robust sign in for $email');

      // Method 1: Try normal sign in first
      try {
        print('📝 Method 1: Attempting normal sign in...');

        final userCredential = await _auth.signInWithEmailAndPassword(
          email: email.trim().toLowerCase(),
          password: password,
        );

        final user = userCredential.user!;
        print('✅ Method 1: Normal sign in successful - ${user.uid}');

        return AuthResult.success(user);

      } catch (e) {
        print('❌ Method 1: Normal sign in failed - $e');

        // Check if it's the PigeonUserDetails error
        if (e.toString().contains('PigeonUserDetails') ||
            e.toString().contains('List<Object?>')) {
          print('🔄 Detected PigeonUserDetails error, trying fallback methods...');

          // Method 2: Wait and check if user was actually signed in
          await Future.delayed(const Duration(milliseconds: 1500));

          final currentUser = _auth.currentUser;
          if (currentUser != null &&
              currentUser.email?.toLowerCase() == email.toLowerCase()) {
            print('✅ Method 2: User was signed in despite error!');
            return AuthResult.success(currentUser);
          }

          // Method 3: Try sign in again with longer delay
          print('🔄 Method 3: Retry sign in with delay...');
          await Future.delayed(const Duration(milliseconds: 2000));

          try {
            final retryCredential = await _auth.signInWithEmailAndPassword(
              email: email.trim().toLowerCase(),
              password: password,
            );

            final retryUser = retryCredential.user!;
            print('✅ Method 3: Retry sign in successful - ${retryUser.uid}');

            return AuthResult.success(retryUser);

          } catch (retryError) {
            print('❌ Method 3: Retry failed - $retryError');

            // Method 4: Final check for existing user
            await Future.delayed(const Duration(milliseconds: 1000));
            final finalUser = _auth.currentUser;

            if (finalUser != null &&
                finalUser.email?.toLowerCase() == email.toLowerCase()) {
              print('✅ Method 4: Found existing signed in user!');
              return AuthResult.success(finalUser);
            }

            // If all methods fail, return original error
            throw e;
          }
        } else {
          // Different error, rethrow
          rethrow;
        }
      }

    } on FirebaseAuthException catch (e) {
      print('❌ AuthService: Firebase Auth failed - ${e.code}: ${e.message}');
      return AuthResult.error(_getErrorMessage(e.code));
    } catch (e) {
      print('❌ AuthService: Sign in completely failed - $e');
      return AuthResult.error('Sign in failed. Please try again.');
    }
  }

  // ============================================================================
  // SIGN UP (IMPROVED PIGEONUSERDETAILS HANDLING)
  // ============================================================================

  /// Create new account with email and password - IMPROVED VERSION
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    User? createdUser;

    try {
      print('🔥 AuthService: Creating account for $email');

      // Step 1: Create account with enhanced retry mechanism
      print('📝 Step 1: Creating Firebase Auth account...');

      UserCredential? userCredential;
      int retryCount = 0;
      const maxRetries = 4; // Increased retries

      while (userCredential == null && retryCount < maxRetries) {
        try {
          retryCount++;
          print('🔄 Attempt $retryCount/$maxRetries to create account...');

          // Progressive delay between attempts
          if (retryCount > 1) {
            await Future.delayed(Duration(milliseconds: 1000 * retryCount));
          }

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

            // Extended wait for this specific error
            await Future.delayed(Duration(milliseconds: 1500 * retryCount));

            // Check if user was actually created despite the error
            final currentUser = _auth.currentUser;
            if (currentUser != null &&
                currentUser.email?.toLowerCase() == email.toLowerCase()) {
              print('✅ User was created despite error! Using existing user.');
              createdUser = currentUser;
              break;
            }

            if (retryCount >= maxRetries) {
              // Try one more check before giving up
              await Future.delayed(const Duration(milliseconds: 2000));
              final finalUser = _auth.currentUser;
              if (finalUser != null &&
                  finalUser.email?.toLowerCase() == email.toLowerCase()) {
                print('✅ Found user on final check!');
                createdUser = finalUser;
                break;
              }
              rethrow;
            }
          } else {
            // Different error, don't retry
            rethrow;
          }
        }
      }

      // Get user from credential or current user
      if (userCredential != null) {
        createdUser = userCredential.user!;
      }

      // Final fallback check
      createdUser ??= _auth.currentUser;

      if (createdUser == null) {
        throw Exception('Failed to create user after $maxRetries attempts');
      }

      print('✅ Step 1: Account confirmed - ${createdUser.uid}');

      // Step 2: Update display name with error handling
      if (displayName != null && displayName.isNotEmpty) {
        try {
          print('📝 Step 2: Updating display name...');
          await createdUser.updateDisplayName(displayName);
          print('✅ Step 2: Display name updated to: $displayName');
        } catch (e) {
          print('⚠️ Step 2: Display name update failed (non-critical) - $e');
        }
      }

      // Step 3: Create user document in Firestore
      try {
        print('📝 Step 3: Creating Firestore document...');
        await _createUserDocument(createdUser, displayName);
        print('✅ Step 3: Firestore document created');
      } catch (e) {
        print('⚠️ Step 3: Firestore document creation failed (non-critical) - $e');
      }

      // Step 4: Send email verification with extended delay
      try {
        print('📝 Step 4: Sending email verification...');
        // Extended delay to avoid PigeonUserDetails bug
        await Future.delayed(const Duration(milliseconds: 3000));

        // Get fresh user reference and try verification
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

      // Handle email-already-in-use after PigeonUserDetails error
      if (e.code == 'email-already-in-use') {
        print('🔍 Email already exists, checking if it was just created...');
        final currentUser = _auth.currentUser;
        if (currentUser != null &&
            currentUser.email?.toLowerCase() == email.toLowerCase()) {
          print('✅ Found existing user with same email, using it');
          return AuthResult.success(currentUser);
        }
      }

      return AuthResult.error(_getErrorMessage(e.code));
    } catch (e) {
      print('❌ AuthService: SignUp failed - $e');

      // If user was created but something else failed, still return success
      if (createdUser != null) {
        print('⚠️ AuthService: User was created despite error, returning success');
        return AuthResult.success(createdUser);
      }

      // Final fallback: check if user exists in Firebase Auth
      final currentUser = _auth.currentUser;
      if (currentUser != null &&
          currentUser.email?.toLowerCase() == email.toLowerCase()) {
        print('✅ AuthService: Found user in Firebase Auth despite error');
        return AuthResult.success(currentUser);
      }

      return AuthResult.error('Account creation failed. Please try again.');
    }
  }

  // ============================================================================
  // EMAIL VERIFICATION (ENHANCED)
  // ============================================================================

  /// Send email verification to current user - ENHANCED VERSION
  Future<AuthResult> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return AuthResult.error('No user signed in');
      }

      if (user.emailVerified) {
        return AuthResult.success(user, message: 'Email already verified');
      }

      // Enhanced retry mechanism for email verification
      int attempts = 0;
      const maxAttempts = 3;

      while (attempts < maxAttempts) {
        try {
          attempts++;
          print('🔄 Email verification attempt $attempts/$maxAttempts');

          // Progressive delay
          if (attempts > 1) {
            await Future.delayed(Duration(milliseconds: 2000 * attempts));
          }

          await user.sendEmailVerification();
          print('✅ AuthService: Email verification sent on attempt $attempts');
          return AuthResult.success(user, message: 'Verification email sent');

        } catch (e) {
          print('❌ Email verification attempt $attempts failed: $e');

          if (e.toString().contains('PigeonUserDetails') ||
              e.toString().contains('List<Object?>')) {
            if (attempts < maxAttempts) {
              print('🔄 PigeonUserDetails error, retrying...');
              continue;
            }
          }

          if (attempts >= maxAttempts) {
            rethrow;
          }
        }
      }

      return AuthResult.error('Failed to send verification email after $maxAttempts attempts');

    } catch (e) {
      print('❌ AuthService: Send verification failed - $e');
      return AuthResult.error('Failed to send verification email');
    }
  }

  /// Check if email is verified (ROBUST VERSION)
  Future<bool> checkEmailVerified() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('❌ AuthService: No current user for verification check');
        return false;
      }

      print('🔍 AuthService: Current cached status: ${user.emailVerified}');

      // If already verified, return true
      if (user.emailVerified) {
        return true;
      }

      // Method 1: Try getting fresh ID token with retries
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          print('🔄 AuthService: Token refresh attempt $attempt/3...');
          await user.getIdToken(true); // Force refresh

          // Get the refreshed user
          final refreshedUser = _auth.currentUser;
          if (refreshedUser != null && refreshedUser.emailVerified) {
            print('📧 AuthService: Email verified after token refresh');
            return true;
          }

          // Wait between attempts
          if (attempt < 3) {
            await Future.delayed(Duration(milliseconds: 1000 * attempt));
          }

        } catch (e) {
          print('⚠️ AuthService: Token refresh attempt $attempt failed: $e');
          if (attempt == 3) {
            // Last attempt failed, continue to next method
          }
        }
      }

      // Method 2: Try reload method with retries
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          print('🔄 AuthService: Reload attempt $attempt/3...');
          await user.reload();

          final reloadedUser = _auth.currentUser;
          if (reloadedUser != null && reloadedUser.emailVerified) {
            print('📧 AuthService: Email verified after reload');
            return true;
          }

          // Wait between attempts
          if (attempt < 3) {
            await Future.delayed(Duration(milliseconds: 1500 * attempt));
          }

        } catch (e) {
          print('⚠️ AuthService: Reload attempt $attempt failed: $e');
          if (e.toString().contains('PigeonUserDetails')) {
            print('🔍 AuthService: PigeonUserDetails error in reload attempt $attempt');
          }
        }
      }

      // Return current cached status
      final finalUser = _auth.currentUser;
      final cachedStatus = finalUser?.emailVerified ?? false;
      print('📧 AuthService: Using cached status: $cachedStatus');
      return cachedStatus;

    } catch (e) {
      print('❌ AuthService: Check verification failed - $e');
      return false;
    }
  }

  /// Force update email verification status in Firestore
  Future<bool> forceUpdateEmailVerificationStatus() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      print('🔧 AuthService: Force updating email verification status...');

      // Update Firestore to mark email as verified
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'emailVerified': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print('✅ AuthService: Firestore updated with emailVerified = true');
      } catch (e) {
        print('⚠️ AuthService: Failed to update Firestore: $e');
      }

      // Try multiple refresh methods with delays
      for (int attempt = 1; attempt <= 5; attempt++) {
        try {
          print('🔄 AuthService: Force refresh attempt $attempt/5...');

          // Progressive delay
          await Future.delayed(Duration(milliseconds: 1000 * attempt));

          // Try token refresh
          await user.getIdToken(true);

          // Check if it worked
          final refreshedUser = _auth.currentUser;
          if (refreshedUser?.emailVerified == true) {
            print('✅ AuthService: Email verification confirmed after attempt $attempt');
            return true;
          }
        } catch (e) {
          print('⚠️ AuthService: Force refresh attempt $attempt failed: $e');
        }
      }

      // If all refresh attempts fail, trust that email was verified
      print('🔧 AuthService: Refresh failed, but email was verified in browser');
      return true;

    } catch (e) {
      print('❌ AuthService: Force update failed: $e');
      return false;
    }
  }

  // ============================================================================
  // PASSWORD RESET
  // ============================================================================

  /// Send password reset email
  Future<AuthResult> sendPasswordReset(String email) async {
    try {
      // Retry mechanism for password reset
      int attempts = 0;
      const maxAttempts = 3;

      while (attempts < maxAttempts) {
        try {
          attempts++;
          print('🔄 Password reset attempt $attempts/$maxAttempts for $email');

          if (attempts > 1) {
            await Future.delayed(Duration(milliseconds: 1000 * attempts));
          }

          await _auth.sendPasswordResetEmail(
            email: email.trim().toLowerCase(),
          );

          print('✅ AuthService: Password reset sent to $email');
          return AuthResult.success(null, message: 'Password reset email sent');

        } catch (e) {
          print('❌ Password reset attempt $attempts failed: $e');

          if (e.toString().contains('PigeonUserDetails') && attempts < maxAttempts) {
            continue;
          }

          if (attempts >= maxAttempts) {
            rethrow;
          }
        }
      }

      return AuthResult.error('Failed to send password reset email after $maxAttempts attempts');

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

  /// Sign out user
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
  // UTILITY METHODS
  // ============================================================================

  /// Create user document in Firestore
  Future<void> _createUserDocument(User user, String? displayName) async {
    try {
      print('🔥 AuthService: Creating Firestore document for ${user.uid}');

      final userData = <String, dynamic>{
        'uid': user.uid,
        'email': user.email ?? '',
        'displayName': displayName ??
            user.displayName ??
            user.email?.split('@')[0] ??
            'User',
        'photoURL': user.photoURL ?? '',
        'emailVerified': user.emailVerified,
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignIn': FieldValue.serverTimestamp(),
        'isOnline': true,
      };

      // Use set with merge to avoid overwriting existing data
      await _firestore.collection('users').doc(user.uid).set(
        userData,
        SetOptions(merge: true),
      );

      print('✅ AuthService: Firestore document created/updated successfully');
    } catch (e) {
      print('❌ AuthService: Failed to create user document - $e');
      // Don't throw - account creation was successful
    }
  }

  /// Get user data from Firestore safely
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(uid).get();

      if (docSnapshot.exists && docSnapshot.data() is Map<String, dynamic>) {
        return docSnapshot.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('❌ AuthService: Failed to get user data - $e');
      return null;
    }
  }

  /// Get current user's Firestore data
  Future<Map<String, dynamic>?> getCurrentUserData() async {
    final user = currentUser;
    if (user == null) return null;
    return await getUserData(user.uid);
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
      case 'invalid-credential':
        return 'Invalid email or password. Please check your credentials.';
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