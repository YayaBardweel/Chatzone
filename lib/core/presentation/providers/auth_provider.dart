import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../../constants/firebase_constants.dart';
import '../../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Private state variables
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isFirstTime = true;
  bool _isInitialized = false;
  Timer? _emailVerificationTimer;

  // Getters
  UserModel? get currentUser => _currentUser;
  User? get firebaseUser => _auth.currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _currentUser != null && _auth.currentUser != null;
  bool get isFirstTime => _isFirstTime;
  bool get isInitialized => _isInitialized;
  String? get currentUserId => _auth.currentUser?.uid;

  // Email specific getters
  bool get isEmailVerified =>
      _currentUser?.emailVerified ?? _auth.currentUser?.emailVerified ?? false;
  String? get currentUserEmail =>
      _currentUser?.email ?? _auth.currentUser?.email;

  AuthProvider() {
    _initializeAuth();
  }

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  /// Initialize authentication state and listen to changes
  Future<void> _initializeAuth() async {
    try {
      _setLoading(true);
      print('🔥 DEBUG: AuthProvider - Initializing...');

      // Check if user has seen onboarding
      await _checkFirstTime();

      // Listen to Firebase auth state changes
      _auth.authStateChanges().listen(_onAuthStateChanged);

      // Load current user if authenticated
      if (_auth.currentUser != null) {
        print(
            '✅ DEBUG: AuthProvider - Found existing user: ${_auth.currentUser!.email}');
        await _loadCurrentUser();
      }

      _isInitialized = true;
      _setLoading(false);
      print('✅ DEBUG: AuthProvider - Initialization completed');
    } catch (e) {
      print('❌ DEBUG: AuthProvider - Initialization failed: $e');
      _setError('Failed to initialize authentication');
      _isInitialized = true;
      _setLoading(false);
    }
  }

  /// Handle Firebase auth state changes
  void _onAuthStateChanged(User? user) async {
    try {
      print(
          '🔥 DEBUG: AuthProvider - Auth state changed: ${user?.email ?? 'null'}');

      if (user != null) {
        // User signed in - load their data
        await _loadCurrentUser();

        // Start email verification checking if not verified
        if (!user.emailVerified) {
          _startEmailVerificationCheck();
        }
      } else {
        // User signed out - clear data
        print('✅ DEBUG: AuthProvider - User signed out, clearing data');
        _currentUser = null;
        _stopEmailVerificationCheck();
      }

      notifyListeners();
    } catch (e) {
      print('❌ DEBUG: AuthProvider - Auth state change error: $e');
    }
  }

  /// Load current user data from Firestore
  Future<void> _loadCurrentUser() async {
    try {
      if (_auth.currentUser != null) {
        final userData =
            await _getUserDataFromFirestore(_auth.currentUser!.uid);

        if (userData != null) {
          _currentUser = userData.copyWith(
            emailVerified: _auth.currentUser!
                .emailVerified, // Always use latest from Firebase Auth
          );
          print('✅ DEBUG: AuthProvider - User data loaded from Firestore');
        } else {
          // Create user model from Firebase user if Firestore data doesn't exist
          _currentUser = UserModel(
            userId: _auth.currentUser!.uid,
            email: _auth.currentUser!.email!,
            emailVerified: _auth.currentUser!.emailVerified,
            displayName: _auth.currentUser!.displayName ??
                _auth.currentUser!.email!.split('@')[0],
            photoUrl: _auth.currentUser!.photoURL ?? '',
            status: FirebaseConstants.defaultStatus,
            isOnline: true,
            lastSeen: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          print('✅ DEBUG: AuthProvider - User data created from Firebase user');
        }

        notifyListeners();
      }
    } catch (e) {
      print('❌ DEBUG: AuthProvider - Failed to load user data: $e');
    }
  }

  // ============================================================================
  // ONBOARDING
  // ============================================================================

  /// Check if this is the first time opening the app
  Future<void> _checkFirstTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isFirstTime = prefs.getBool('first_time') ?? true;
      print('🔍 DEBUG: AuthProvider - Is first time: $_isFirstTime');
      notifyListeners();
    } catch (e) {
      print('❌ DEBUG: AuthProvider - Failed to check first time: $e');
    }
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('first_time', false);
      _isFirstTime = false;
      print('✅ DEBUG: AuthProvider - Onboarding completed');
      notifyListeners();
    } catch (e) {
      _setError('Failed to complete onboarding');
    }
  }

  // ============================================================================
  // EMAIL AUTHENTICATION - FIXED METHODS
  // ============================================================================

  /// Sign up with email and password - FINAL FIXED VERSION
  Future<bool> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      print('🔥 DEBUG: AuthProvider - Starting signup for: $email');

      // Create account with Firebase Auth directly
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      print('✅ DEBUG: AuthProvider - Account created successfully');
      print('📧 DEBUG: AuthProvider - User: ${userCredential.user?.email}');
      print(
          '📧 DEBUG: AuthProvider - Email verified: ${userCredential.user?.emailVerified}');

      // Send verification email immediately
      if (userCredential.user != null) {
        await userCredential.user!.sendEmailVerification();
        print('✅ DEBUG: AuthProvider - Verification email sent');
      }

      // Create Firestore document
      await _createUserDocumentSimple(userCredential.user!);
      print('✅ DEBUG: AuthProvider - Firestore document created');

      // Update current user state - THIS IS CRITICAL!
      _currentUser = UserModel(
        userId: userCredential.user!.uid,
        email: userCredential.user!.email!,
        emailVerified: userCredential.user!.emailVerified,
        displayName: userCredential.user!.email!.split('@')[0],
        photoUrl: '',
        status: FirebaseConstants.defaultStatus,
        isOnline: true,
        lastSeen: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _setLoading(false);
      notifyListeners(); // THIS IS CRUCIAL FOR UI UPDATES!

      print('✅ DEBUG: AuthProvider - Signup completed successfully');
      print('✅ DEBUG: AuthProvider - Current user set: ${_currentUser?.email}');
      print('✅ DEBUG: AuthProvider - Is authenticated: $isAuthenticated');

      return true;
    } on FirebaseAuthException catch (e) {
      print(
          '❌ DEBUG: AuthProvider - FirebaseAuthException: ${e.code} - ${e.message}');
      _setError(_getFirebaseErrorMessage(e.code));
      return false;
    } catch (e) {
      print('❌ DEBUG: AuthProvider - Unexpected error: $e');
      _setError('Account creation failed. Please try again.');
      return false;
    }
  }

  /// Sign in with email and password - FINAL FIXED VERSION
  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();
      print('🔥 DEBUG: AuthProvider - Starting signin for: $email');

      // Sign in with Firebase Auth directly
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      print('✅ DEBUG: AuthProvider - Signin successful');
      print('📧 DEBUG: AuthProvider - User: ${userCredential.user?.email}');
      print(
          '📧 DEBUG: AuthProvider - Email verified: ${userCredential.user?.emailVerified}');

      // Get user data from Firestore
      final userData =
          await _getUserDataFromFirestore(userCredential.user!.uid);

      if (userData != null) {
        _currentUser = userData.copyWith(
          emailVerified: userCredential
              .user!.emailVerified, // Update with latest verification status
        );
        print('✅ DEBUG: AuthProvider - User data loaded from Firestore');
      } else {
        // Fallback: create user model from Firebase user
        _currentUser = UserModel(
          userId: userCredential.user!.uid,
          email: userCredential.user!.email!,
          emailVerified: userCredential.user!.emailVerified,
          displayName: userCredential.user!.displayName ??
              userCredential.user!.email!.split('@')[0],
          photoUrl: userCredential.user!.photoURL ?? '',
          status: FirebaseConstants.defaultStatus,
          isOnline: true,
          lastSeen: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        print('✅ DEBUG: AuthProvider - User data created from Firebase user');
      }

      _setLoading(false);
      notifyListeners(); // THIS IS CRUCIAL FOR UI UPDATES!

      print('✅ DEBUG: AuthProvider - Signin completed successfully');
      print('✅ DEBUG: AuthProvider - Current user: ${_currentUser?.email}');
      print('✅ DEBUG: AuthProvider - Is authenticated: $isAuthenticated');
      print('✅ DEBUG: AuthProvider - Is email verified: $isEmailVerified');

      return true;
    } on FirebaseAuthException catch (e) {
      print(
          '❌ DEBUG: AuthProvider - FirebaseAuthException: ${e.code} - ${e.message}');
      _setError(_getFirebaseErrorMessage(e.code));
      return false;
    } catch (e) {
      print('❌ DEBUG: AuthProvider - Unexpected error: $e');
      _setError('Login failed. Please try again.');
      return false;
    }
  }

  /// Send email verification - FINAL FIXED VERSION
  Future<bool> sendEmailVerification() async {
    try {
      _setLoading(true);
      _clearError();
      print('🔥 DEBUG: AuthProvider - Sending email verification (FIXED)');

      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No user signed in');
      }

      if (user.emailVerified) {
        print('✅ DEBUG: AuthProvider - Email already verified');
        _setLoading(false);
        return true;
      }

      await user.sendEmailVerification();

      _setLoading(false);
      print('✅ DEBUG: AuthProvider - Email verification sent successfully');
      return true;
    } catch (e) {
      print('❌ DEBUG: AuthProvider - Send email verification error: $e');
      _setError('Failed to send verification email');
      return false;
    }
  }

  /// Check email verification - FINAL FIXED VERSION (No more PigeonUserInfo error!)
  Future<bool> checkEmailVerification() async {
    try {
      print(
          '🔍 DEBUG: AuthProvider - Checking email verification status (FIXED)');

      User? user = _auth.currentUser;
      if (user == null) {
        print('❌ DEBUG: AuthProvider - No current user found');
        return false;
      }

      print(
          '📧 DEBUG: AuthProvider - Current verification status: ${user.emailVerified}');

      // Instead of reload(), we'll get a fresh ID token which forces Firebase to refresh user info
      try {
        await user.getIdToken(true); // Force refresh the token
        print('✅ DEBUG: AuthProvider - Token refreshed successfully');

        // Get the refreshed user
        user = _auth.currentUser;
        bool isVerified = user?.emailVerified ?? false;

        print(
            '📧 DEBUG: AuthProvider - Updated verification status: $isVerified');

        if (isVerified && _currentUser != null) {
          // Update current user with verification status
          _currentUser = _currentUser!.copyWith(emailVerified: true);

          // Update Firestore
          await _updateEmailVerificationInFirestore(true);

          notifyListeners();
          print(
              '✅ DEBUG: AuthProvider - Email verification status updated in app');
        }

        return isVerified;
      } catch (tokenError) {
        print('⚠️ DEBUG: AuthProvider - Token refresh failed: $tokenError');
        // Fallback: just use the current status without refresh
        bool isVerified = user?.emailVerified ?? false;  // ✅ Null safe!
        print(
            '📧 DEBUG: AuthProvider - Using cached verification status: $isVerified');
        return isVerified;
      }
    } catch (e) {
      print('❌ DEBUG: AuthProvider - Check email verification error: $e');
      // Return current cached status as fallback
      return _currentUser?.emailVerified ??
          _auth.currentUser?.emailVerified ??
          false;
    }
  }

  /// Manual email verification check (for "I've Verified" button) - NEW METHOD
  Future<bool> manualEmailVerificationCheck() async {
    try {
      print('🔍 DEBUG: AuthProvider - Manual email verification check');

      User? user = _auth.currentUser;
      if (user == null) return false;

      // Try to get a fresh token to force refresh
      try {
        await user.getIdToken(true);
        user = _auth.currentUser; // Get refreshed user
      } catch (e) {
        print(
            '⚠️ DEBUG: AuthProvider - Token refresh failed in manual check: $e');
      }

      bool isVerified = user?.emailVerified ?? false;
      print('📧 DEBUG: AuthProvider - Manual check result: $isVerified');

      if (isVerified && _currentUser != null) {
        _currentUser = _currentUser!.copyWith(emailVerified: true);
        await _updateEmailVerificationInFirestore(true);
        notifyListeners();
        print('✅ DEBUG: AuthProvider - Manual verification confirmed');
      }

      return isVerified;
    } catch (e) {
      print('❌ DEBUG: AuthProvider - Manual verification check failed: $e');
      return false;
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      _setLoading(true);
      _clearError();
      print('🔥 DEBUG: AuthProvider - Sending password reset to: $email');

      await _auth.sendPasswordResetEmail(email: email.trim());

      _setLoading(false);
      print('✅ DEBUG: AuthProvider - Password reset email sent');
      return true;
    } catch (e) {
      print('❌ DEBUG: AuthProvider - Password reset error: $e');
      _setError('Failed to send password reset email: $e');
      return false;
    }
  }

  // ============================================================================
  // EMAIL VERIFICATION MONITORING - FIXED VERSION
  // ============================================================================

  /// Start checking email verification status periodically - FIXED VERSION
  void _startEmailVerificationCheck() {
    _stopEmailVerificationCheck(); // Stop any existing timer

    print(
        '🔄 DEBUG: AuthProvider - Starting email verification check timer (FIXED)');
    _emailVerificationTimer = Timer.periodic(
      const Duration(seconds: 8), // Increased interval to reduce API calls
      (timer) async {
        try {
          bool isVerified = await checkEmailVerification();
          if (isVerified) {
            print(
                '✅ DEBUG: AuthProvider - Email verified! Stopping verification check');
            _stopEmailVerificationCheck();

            // Show success notification
            print(
                '🎉 DEBUG: AuthProvider - Email verification completed successfully');
          } else {
            print(
                '⏳ DEBUG: AuthProvider - Email still not verified, will check again in 8 seconds');
          }
        } catch (e) {
          print('❌ DEBUG: AuthProvider - Email verification check failed: $e');
          // Continue checking despite errors
        }
      },
    );
  }

  /// Stop email verification checking
  void _stopEmailVerificationCheck() {
    if (_emailVerificationTimer != null) {
      print('🛑 DEBUG: AuthProvider - Stopping email verification check timer');
      _emailVerificationTimer!.cancel();
      _emailVerificationTimer = null;
    }
  }

  // ============================================================================
  // SESSION MANAGEMENT
  // ============================================================================

  /// Sign out current user
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();
      print('🔥 DEBUG: AuthProvider - Signing out user');

      _stopEmailVerificationCheck();
      await _auth.signOut();

      // Clear local state
      _currentUser = null;

      _setLoading(false);
      print('✅ DEBUG: AuthProvider - Sign out successful');
      notifyListeners();
    } catch (e) {
      print('❌ DEBUG: AuthProvider - Sign out error: $e');
      _setError('Failed to sign out: $e');
    }
  }

  /// Delete user account permanently
  Future<bool> deleteAccount() async {
    try {
      _setLoading(true);
      _clearError();
      print('🔥 DEBUG: AuthProvider - Deleting user account');

      String userIdToDelete = currentUserId!;

      _stopEmailVerificationCheck();

      // Delete user document from Firestore
      await _firestore.collection('users').doc(userIdToDelete).delete();

      // Delete Firebase Auth account
      await _auth.currentUser!.delete();

      // Clear local state
      _currentUser = null;

      // Reset onboarding
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('first_time', true);
      _isFirstTime = true;

      _setLoading(false);
      print('✅ DEBUG: AuthProvider - Account deleted');
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ DEBUG: AuthProvider - Delete account error: $e');
      _setError('Failed to delete account: $e');
      return false;
    }
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Simple method to create Firestore document
  Future<void> _createUserDocumentSimple(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'userId': user.uid,
        'email': user.email,
        'emailVerified': user.emailVerified,
        'displayName': user.email?.split('@')[0] ?? 'User',
        'photoUrl': user.photoURL ?? '',
        'status': FirebaseConstants.defaultStatus,
        'isOnline': true,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ DEBUG: AuthProvider - Firestore document created successfully');
    } catch (e) {
      print('❌ DEBUG: AuthProvider - Failed to create Firestore document: $e');
      // Don't throw - account creation was successful
    }
  }

  /// Get user data from Firestore
  Future<UserModel?> _getUserDataFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print(
          '❌ DEBUG: AuthProvider - Failed to get user data from Firestore: $e');
      return null;
    }
  }

  /// Update email verification status in Firestore
  Future<void> _updateEmailVerificationInFirestore(bool isVerified) async {
    try {
      if (currentUserId == null) return;

      await _firestore.collection('users').doc(currentUserId).update({
        'emailVerified': isVerified,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print(
          '✅ DEBUG: AuthProvider - Email verification status updated in Firestore: $isVerified');
    } catch (e) {
      print(
          '❌ DEBUG: AuthProvider - Failed to update email verification status: $e');
    }
  }

  /// Get user-friendly Firebase error messages
  String _getFirebaseErrorMessage(String errorCode) {
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

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get current user display name
  String getCurrentUserDisplayName() {
    return _currentUser?.displayName ??
        _auth.currentUser?.displayName ??
        'ChatZone User';
  }

  /// Get current user photo URL
  String getCurrentUserPhotoUrl() {
    return _currentUser?.photoUrl ??
        _auth.currentUser?.photoURL ??
        FirebaseConstants.defaultProfileImage;
  }

  /// Check if current user needs email verification
  bool needsEmailVerification() {
    return isAuthenticated && !isEmailVerified;
  }

  /// Get authentication state summary
  Map<String, dynamic> getAuthState() {
    return {
      'isAuthenticated': isAuthenticated,
      'isEmailVerified': isEmailVerified,
      'isFirstTime': isFirstTime,
      'isInitialized': isInitialized,
      'isLoading': isLoading,
      'userEmail': currentUserEmail,
      'userId': currentUserId,
      'needsEmailVerification': needsEmailVerification(),
    };
  }

  // ============================================================================
  // PRIVATE HELPER METHODS
  // ============================================================================

  /// Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Set error message
  void _setError(String error) {
    _errorMessage = error;
    _isLoading = false;
    notifyListeners();
  }

  /// Clear error message
  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Clear error (public method)
  void clearError() {
    _clearError();
  }

  // ============================================================================
  // APP LIFECYCLE METHODS
  // ============================================================================

  /// Call when app resumes (becomes active)
  Future<void> onAppResumed() async {
    if (isAuthenticated) {
      print('📱 DEBUG: AuthProvider - App resumed');
      await checkEmailVerification();
    }
  }

  /// Call when app pauses (goes to background)
  Future<void> onAppPaused() async {
    if (isAuthenticated) {
      print('📱 DEBUG: AuthProvider - App paused');
    }
  }

  @override
  void dispose() {
    print('🗑️ DEBUG: AuthProvider - Disposing');
    _stopEmailVerificationCheck();
    super.dispose();
  }
}
