// ============================================================================
// File: lib/core/providers/auth_provider.dart (UPDATED FOR ROBUST AUTH)
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../data/services/auth_service.dart';

/// Enhanced authentication state provider with PigeonUserDetails bug handling
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  // ============================================================================
  // PRIVATE STATE
  // ============================================================================

  User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isFirstTime = true;
  bool _isInitialized = false;
  StreamSubscription<User?>? _authSubscription;
  Timer? _verificationTimer;

  // ============================================================================
  // PUBLIC GETTERS
  // ============================================================================

  /// Current Firebase user
  User? get user => _user;

  /// Loading state
  bool get isLoading => _isLoading;

  /// Error message
  String? get error => _error;

  /// Is user authenticated
  bool get isAuthenticated => _user != null;

  /// Is first time opening app
  bool get isFirstTime => _isFirstTime;

  /// Is provider initialized
  bool get isInitialized => _isInitialized;

  /// Is email verified
  bool get isEmailVerified => _user?.emailVerified ?? false;

  /// Current user email
  String? get userEmail => _user?.email;

  /// Current user display name
  String get displayName => _user?.displayName ?? 'User';

  // ============================================================================
  // INITIALIZATION
  // ============================================================================

  AuthProvider() {
    _initialize();
  }

  /// Initialize auth provider
  Future<void> _initialize() async {
    try {
      print('🔥 AuthProvider: Initializing...');

      // Check first time status
      await _checkFirstTime();

      // Set current user if signed in
      _user = _authService.currentUser;

      // Listen to auth state changes
      _authSubscription = _authService.authStateChanges.listen(_onAuthStateChanged);

      // Start email verification check if needed
      if (_user != null && !_user!.emailVerified) {
        _startEmailVerificationCheck();
      }

      _isInitialized = true;
      print('✅ AuthProvider: Initialized successfully');
      notifyListeners();

    } catch (e) {
      print('❌ AuthProvider: Initialization failed - $e');
      _setError('Failed to initialize authentication');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Handle auth state changes from Firebase
  void _onAuthStateChanged(User? user) {
    print('🔥 AuthProvider: Auth state changed - ${user?.email ?? 'null'}');

    _user = user;

    if (user != null && !user.emailVerified) {
      _startEmailVerificationCheck();
    } else {
      _stopEmailVerificationCheck();
    }

    notifyListeners();
  }

  // ============================================================================
  // AUTHENTICATION METHODS (USING ROBUST SERVICE)
  // ============================================================================

  /// Sign up new user
  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      print('🔥 AuthProvider: Starting robust signup for $email');

      final result = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (result.isSuccess) {
        print('✅ AuthProvider: Robust signup successful');
        _setLoading(false);
        return true;
      } else {
        _setError(result.error!);
        return false;
      }

    } catch (e) {
      print('❌ AuthProvider: Signup failed - $e');
      _setError('Account creation failed. Please try again.');
      return false;
    }
  }

  /// Sign in existing user - ROBUST VERSION
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      print('🔥 AuthProvider: Starting robust signin for $email');

      final result = await _authService.signIn(
        email: email,
        password: password,
      );

      if (result.isSuccess) {
        print('✅ AuthProvider: Robust signin successful');
        _setLoading(false);

        // Show success message for user feedback
        if (result.message != null) {
          print('📝 AuthProvider: ${result.message}');
        }

        return true;
      } else {
        _setError(result.error!);
        return false;
      }

    } catch (e) {
      print('❌ AuthProvider: Signin failed - $e');
      _setError('Sign in failed. Please try again.');
      return false;
    }
  }

  /// Send email verification - ENHANCED VERSION
  Future<bool> sendEmailVerification() async {
    try {
      _setLoading(true);
      _clearError();

      print('🔥 AuthProvider: Sending email verification (enhanced)');

      final result = await _authService.sendEmailVerification();

      if (result.isSuccess) {
        _setLoading(false);
        return true;
      } else {
        _setError(result.error!);
        return false;
      }

    } catch (e) {
      print('❌ AuthProvider: Send verification failed - $e');
      _setError('Failed to send verification email');
      return false;
    }
  }

  /// Check email verification status - ROBUST VERSION
  Future<bool> checkEmailVerification() async {
    try {
      print('🔍 AuthProvider: Checking email verification (robust)...');

      final isVerified = await _authService.checkEmailVerified();

      if (isVerified) {
        // Update local user state
        _user = _authService.currentUser;
        _stopEmailVerificationCheck();
        notifyListeners();
        print('✅ AuthProvider: Email verification confirmed (robust)');
        return true;
      }

      return false;

    } catch (e) {
      print('❌ AuthProvider: Check verification failed - $e');
      return false;
    }
  }

  /// Manual verification check with force update option
  Future<bool> manualEmailVerificationCheck() async {
    try {
      print('🔍 AuthProvider: Manual email verification check (robust)');

      // Show loading state
      _setLoading(true);

      // First try the robust check
      bool isVerified = await checkEmailVerification();

      if (isVerified) {
        _setLoading(false);
        return true;
      }

      // If normal check fails, try force update
      print('🔧 AuthProvider: Normal check failed, trying force update...');

      isVerified = await _authService.forceUpdateEmailVerificationStatus();

      if (isVerified) {
        _user = _authService.currentUser;
        _stopEmailVerificationCheck();
        notifyListeners();
        print('✅ AuthProvider: Force verification successful');
      }

      _setLoading(false);
      return isVerified;

    } catch (e) {
      print('❌ AuthProvider: Manual verification check failed: $e');
      _setLoading(false);
      return false;
    }
  }

  /// Send password reset email - ENHANCED VERSION
  Future<bool> sendPasswordReset(String email) async {
    try {
      _setLoading(true);
      _clearError();

      print('🔥 AuthProvider: Sending password reset (enhanced)');

      final result = await _authService.sendPasswordReset(email);

      if (result.isSuccess) {
        _setLoading(false);
        return true;
      } else {
        _setError(result.error!);
        return false;
      }

    } catch (e) {
      print('❌ AuthProvider: Password reset failed - $e');
      _setError('Failed to send password reset email');
      return false;
    }
  }

  /// Sign out user
  Future<void> signOut() async {
    try {
      _setLoading(true);
      _clearError();

      _stopEmailVerificationCheck();

      final result = await _authService.signOut();

      if (result.isSuccess) {
        _user = null;
        print('✅ AuthProvider: Signed out successfully');
      } else {
        _setError(result.error!);
      }

      _setLoading(false);

    } catch (e) {
      print('❌ AuthProvider: Sign out failed - $e');
      _setError('Failed to sign out');
    }
  }

  // ============================================================================
  // EMAIL VERIFICATION MONITORING (ENHANCED)
  // ============================================================================

  /// Start periodic email verification checking - ENHANCED VERSION
  void _startEmailVerificationCheck() {
    if (_verificationTimer != null) return;

    print('🔄 AuthProvider: Starting enhanced email verification monitoring');

    // Extended delay before starting to avoid PigeonUserDetails bug
    Future.delayed(const Duration(seconds: 3), () {
      if (_verificationTimer != null || (_user?.emailVerified ?? true)) return;

      _verificationTimer = Timer.periodic(
        const Duration(seconds: 15), // Increased interval to 15 seconds
            (timer) async {
          try {
            print('🔍 AuthProvider: Periodic verification check...');
            final isVerified = await checkEmailVerification();
            if (isVerified) {
              print('✅ AuthProvider: Email verified via periodic check!');
              timer.cancel();
              _verificationTimer = null;
            }
          } catch (e) {
            print('❌ AuthProvider: Periodic verification check error: $e');
            // Continue checking despite errors, but with exponential backoff
            if (timer.tick > 10) { // After 10 attempts (2.5 minutes)
              print('🛑 AuthProvider: Stopping periodic checks after 10 attempts');
              timer.cancel();
              _verificationTimer = null;
            }
          }
        },
      );
    });
  }

  /// Stop email verification checking
  void _stopEmailVerificationCheck() {
    if (_verificationTimer != null) {
      print('🛑 AuthProvider: Stopping email verification monitoring');
      _verificationTimer!.cancel();
      _verificationTimer = null;
    }
  }

  // ============================================================================
  // ONBOARDING
  // ============================================================================

  /// Check if first time opening app
  Future<void> _checkFirstTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isFirstTime = prefs.getBool('first_time') ?? true;
      print('🔍 AuthProvider: First time = $_isFirstTime');
    } catch (e) {
      print('❌ AuthProvider: Check first time failed - $e');
    }
  }

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('first_time', false);
      _isFirstTime = false;
      notifyListeners();
      print('✅ AuthProvider: Onboarding completed');
    } catch (e) {
      print('❌ AuthProvider: Complete onboarding failed - $e');
    }
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

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get authentication state summary for debugging
  Map<String, dynamic> getAuthState() {
    return {
      'isAuthenticated': isAuthenticated,
      'isEmailVerified': isEmailVerified,
      'isFirstTime': isFirstTime,
      'isInitialized': isInitialized,
      'isLoading': isLoading,
      'userEmail': userEmail,
      'error': error,
      'hasVerificationTimer': _verificationTimer != null,
    };
  }

  /// Debug method to show current auth state
  void debugAuthState() {
    final state = getAuthState();
    print('🔍 AuthProvider Debug State:');
    state.forEach((key, value) {
      print('   $key: $value');
    });
  }

  // ============================================================================
  // CLEANUP
  // ============================================================================

  @override
  void dispose() {
    print('🗑️ AuthProvider: Disposing...');
    _authSubscription?.cancel();
    _stopEmailVerificationCheck();
    super.dispose();
  }
}