
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../constants/firebase_constants.dart';
import '../models/user_model.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Current user getter
  User? get currentUser => _auth.currentUser;
  String? get currentUserId => _auth.currentUser?.uid;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ============================================================================
  // EMAIL AUTHENTICATION
  // ============================================================================

  /// Sign up with email and password
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('🔥 DEBUG: Creating account for email: $email');

      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Send email verification immediately
      if (userCredential.user != null && !userCredential.user!.emailVerified) {
        await userCredential.user!.sendEmailVerification();
        print('✅ DEBUG: Email verification sent to: $email');
      }

      // Create user document in Firestore
      await _createUserDocument(userCredential.user!);

      print('✅ DEBUG: User account created successfully');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('❌ DEBUG: Sign up failed with code: ${e.code}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ DEBUG: Sign up failed with error: $e');
      throw Exception('Failed to create account: ${e.toString()}');
    }
  }

  /// Sign in with email and password
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      print('🔥 DEBUG: Signing in with email: $email');

      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      print('✅ DEBUG: Sign in successful');
      return userCredential;
    } on FirebaseAuthException catch (e) {
      print('❌ DEBUG: Sign in failed with code: ${e.code}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ DEBUG: Sign in failed with error: $e');
      throw Exception('Failed to sign in: ${e.toString()}');
    }
  }

  /// Send email verification
  Future<void> sendEmailVerification() async {
    try {
      User? user = currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      if (user.emailVerified) {
        print('✅ DEBUG: Email already verified');
        return;
      }

      await user.sendEmailVerification();
      print('✅ DEBUG: Email verification sent to: ${user.email}');
    } on FirebaseAuthException catch (e) {
      print('❌ DEBUG: Send email verification failed: ${e.code}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ DEBUG: Send email verification failed: $e');
      throw Exception('Failed to send email verification: ${e.toString()}');
    }
  }

  /// Check if email is verified
  Future<bool> isEmailVerified() async {
    try {
      User? user = currentUser;
      if (user == null) return false;

      // Reload user to get latest verification status
      await user.reload();
      user = _auth.currentUser; // Get refreshed user

      bool isVerified = user?.emailVerified ?? false;
      print('🔍 DEBUG: Email verification status: $isVerified');
      return isVerified;
    } catch (e) {
      print('❌ DEBUG: Check email verification failed: $e');
      return false;
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      print('🔥 DEBUG: Sending password reset to: $email');

      await _auth.sendPasswordResetEmail(email: email.trim());
      print('✅ DEBUG: Password reset email sent');
    } on FirebaseAuthException catch (e) {
      print('❌ DEBUG: Password reset failed: ${e.code}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ DEBUG: Password reset failed: $e');
      throw Exception('Failed to send password reset: ${e.toString()}');
    }
  }

  /// Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      User? user = currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      await user.updatePassword(newPassword);
      print('✅ DEBUG: Password updated successfully');
    } on FirebaseAuthException catch (e) {
      print('❌ DEBUG: Password update failed: ${e.code}');
      throw _handleAuthException(e);
    } catch (e) {
      print('❌ DEBUG: Password update failed: $e');
      throw Exception('Failed to update password: ${e.toString()}');
    }
  }

  // ============================================================================
  // USER MANAGEMENT
  // ============================================================================

  /// Create user document in Firestore
  Future<void> _createUserDocument(User user) async {
    try {
      final userDoc = _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(user.uid);

      final userData = {
        FirebaseConstants.userId: user.uid,
        FirebaseConstants.email: user.email,
        FirebaseConstants.emailVerified: user.emailVerified,
        FirebaseConstants.displayName: user.displayName ?? _extractNameFromEmail(user.email),
        FirebaseConstants.photoUrl: user.photoURL ?? FirebaseConstants.defaultProfileImage,
        FirebaseConstants.status: FirebaseConstants.defaultStatus,
        FirebaseConstants.isOnline: true,
        FirebaseConstants.lastSeen: FieldValue.serverTimestamp(),
        FirebaseConstants.createdAt: FieldValue.serverTimestamp(),
        FirebaseConstants.updatedAt: FieldValue.serverTimestamp(),
      };

      await userDoc.set(userData);
      print('✅ DEBUG: User document created in Firestore');
    } catch (e) {
      print('❌ DEBUG: Failed to create user document: $e');
      throw Exception('Failed to create user document: ${e.toString()}');
    }
  }

  /// Update user profile
  Future<void> updateUserProfile({
    String? displayName,
    String? photoUrl,
    String? status,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('No user signed in');
      }

      final updates = <String, dynamic>{
        FirebaseConstants.updatedAt: FieldValue.serverTimestamp(),
      };

      if (displayName != null) {
        updates[FirebaseConstants.displayName] = displayName;
        await currentUser!.updateDisplayName(displayName);
        print('✅ DEBUG: Display name updated to: $displayName');
      }

      if (photoUrl != null) {
        updates[FirebaseConstants.photoUrl] = photoUrl;
        await currentUser!.updatePhotoURL(photoUrl);
        print('✅ DEBUG: Photo URL updated');
      }

      if (status != null) {
        updates[FirebaseConstants.status] = status;
        print('✅ DEBUG: Status updated to: $status');
      }

      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(currentUserId)
          .update(updates);

      print('✅ DEBUG: User profile updated in Firestore');
    } catch (e) {
      print('❌ DEBUG: Failed to update profile: $e');
      throw Exception('Failed to update profile: ${e.toString()}');
    }
  }

  /// Update email verification status in Firestore
  Future<void> updateEmailVerificationStatus() async {
    try {
      if (currentUserId == null) return;

      bool isVerified = await isEmailVerified();

      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(currentUserId)
          .update({
        FirebaseConstants.emailVerified: isVerified,
        FirebaseConstants.updatedAt: FieldValue.serverTimestamp(),
      });

      print('✅ DEBUG: Email verification status updated: $isVerified');
    } catch (e) {
      print('❌ DEBUG: Failed to update email verification status: $e');
    }
  }

  /// Get user data
  Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId)
          .get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('❌ DEBUG: Failed to get user data: $e');
      throw Exception('Failed to get user data: ${e.toString()}');
    }
  }

  /// Get current user data
  Future<UserModel?> getCurrentUserData() async {
    if (currentUserId == null) return null;
    return await getUserData(currentUserId!);
  }

  // ============================================================================
  // ONLINE STATUS
  // ============================================================================

  /// Update user online status
  Future<void> updateOnlineStatus(bool isOnline) async {
    try {
      if (currentUserId == null) return;

      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(currentUserId)
          .update({
        FirebaseConstants.isOnline: isOnline,
        FirebaseConstants.lastSeen: FieldValue.serverTimestamp(),
        FirebaseConstants.updatedAt: FieldValue.serverTimestamp(),
      });

      print('✅ DEBUG: Online status updated: $isOnline');
    } catch (e) {
      print('❌ DEBUG: Failed to update online status: $e');
    }
  }

  /// Setup presence system
  void setupPresenceSystem() {
    if (currentUserId == null) return;

    final userStatusRef = _firestore
        .collection(FirebaseConstants.usersCollection)
        .doc(currentUserId);

    userStatusRef.update({
      FirebaseConstants.isOnline: true,
      FirebaseConstants.lastSeen: FieldValue.serverTimestamp(),
    });
  }

  // ============================================================================
  // AUTHENTICATION HELPERS
  // ============================================================================

  /// Sign out user
  Future<void> signOut() async {
    try {
      await updateOnlineStatus(false);
      await _auth.signOut();
      print('✅ DEBUG: User signed out');
    } catch (e) {
      print('❌ DEBUG: Sign out failed: $e');
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }

  /// Delete user account
  Future<void> deleteAccount() async {
    try {
      if (currentUserId == null) {
        throw Exception('No user signed in');
      }

      String userIdToDelete = currentUserId!;

      // Delete user document from Firestore
      await _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userIdToDelete)
          .delete();

      // Delete Firebase Auth account
      await currentUser!.delete();
      print('✅ DEBUG: User account deleted');
    } catch (e) {
      print('❌ DEBUG: Failed to delete account: $e');
      throw Exception('Failed to delete account: ${e.toString()}');
    }
  }

  /// Check if email is already registered
  Future<bool> isEmailRegistered(String email) async {
    try {
      List<String> methods = await _auth.fetchSignInMethodsForEmail(email.trim());
      return methods.isNotEmpty;
    } catch (e) {
      print('❌ DEBUG: Check email registration failed: $e');
      return false;
    }
  }

  /// Validate current user session
  Future<bool> validateSession() async {
    try {
      if (currentUser == null) return false;

      await currentUser!.getIdToken(true);
      return true;
    } catch (e) {
      print('❌ DEBUG: Session validation failed: $e');
      return false;
    }
  }

  /// Check if user profile is complete
  Future<bool> isProfileComplete() async {
    try {
      final userData = await getCurrentUserData();
      if (userData == null) return false;

      return userData.displayName.isNotEmpty &&
          userData.displayName != _extractNameFromEmail(userData.email) &&
          userData.emailVerified;
    } catch (e) {
      return false;
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Extract name from email (fallback)
  String _extractNameFromEmail(String? email) {
    if (email == null || email.isEmpty) return 'ChatZone User';

    // Extract username part from email
    String username = email.split('@')[0];

    // Capitalize first letter
    if (username.isNotEmpty) {
      return username[0].toUpperCase() + username.substring(1);
    }

    return 'ChatZone User';
  }

  /// Handle Firebase Auth exceptions
  Exception _handleAuthException(FirebaseAuthException e) {
    String message;

    switch (e.code) {
      case 'weak-password':
        message = 'The password provided is too weak.';
        break;
      case 'email-already-in-use':
        message = 'An account already exists for that email.';
        break;
      case 'invalid-email':
        message = 'The email address is not valid.';
        break;
      case 'user-disabled':
        message = 'This account has been disabled.';
        break;
      case 'user-not-found':
        message = 'No account found for that email.';
        break;
      case 'wrong-password':
        message = 'Wrong password provided.';
        break;
      case 'too-many-requests':
        message = 'Too many unsuccessful attempts. Please try again later.';
        break;
      case 'operation-not-allowed':
        message = 'Email/password accounts are not enabled.';
        break;
      case 'network-request-failed':
        message = 'Network error. Please check your connection.';
        break;
      case 'requires-recent-login':
        message = 'This operation requires recent authentication. Please sign in again.';
        break;
      default:
        message = e.message ?? 'An authentication error occurred.';
    }

    return Exception(message);
  }

  /// Get current user email
  String? getCurrentUserEmail() {
    return currentUser?.email;
  }

  /// Get current user display name
  String getCurrentUserDisplayName() {
    return currentUser?.displayName ??
        _extractNameFromEmail(currentUser?.email) ??
        'ChatZone User';
  }
}