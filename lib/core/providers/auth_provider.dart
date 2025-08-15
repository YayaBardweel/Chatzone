// ============================================================================
// File: lib/core/providers/auth_provider.dart (CLEAN REBUILD)
// ============================================================================

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import '../data/services/auth_service.dart';


/// Clean authentication state provider
/// Manages authentication state and UI interactions
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
  // AUTHENTICATION METHODS
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

      print('🔥 AuthProvider: Starting signup for $email');

      final result = await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );

      if (result.isSuccess) {
        print('✅ AuthProvider: Signup successful');
        _setLoading(false);

        // Don't wait for auth state change - navigate immediately
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

  /// Sign in existing user
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      print('🔥 AuthProvider: Starting signin for $email');

      final result = await _authService.signIn(
        email: email,
        password: password,
      );

      if (result.isSuccess) {
        print('✅ AuthProvider: Signin successful');
        _setLoading(false);
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

  /// Send email verification
  Future<bool> sendEmailVerification() async {
    try {
      _setLoading(true);
      _clearError();

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

  /// Check email verification status
  Future<bool> checkEmailVerification() async {
    try {
      print('🔍 AuthProvider: Checking email verification...');

      final isVerified = await _authService.checkEmailVerified();

      if (isVerified) {
        // Update local user state
        _user = _authService.currentUser;
        _stopEmailVerificationCheck();
        notifyListeners();
        print('✅ AuthProvider: Email verification confirmed');
        return true;
      }

      return false;

    } catch (e) {
      print('❌ AuthProvider: Check verification failed - $e');

      // If it's the PigeonUserDetails error, try force update method
      if (e.toString().contains('PigeonUserDetails') ||
          e.toString().contains('List<Object?>')) {
        try {
          print('🔄 AuthProvider: Trying force verification update...');
          final forceResult = await _authService.forceUpdateEmailVerificationStatus();

          if (forceResult) {
            _user = _authService.currentUser;
            _stopEmailVerificationCheck();
            notifyListeners();
            return true;
          }
        } catch (fallbackError) {
          print('❌ AuthProvider: Force update also failed: $fallbackError');
        }
      }

      return false;
    }
  }

  /// Manual verification check with force update option
  Future<bool> manualEmailVerificationCheck() async {
    try {
      print('🔍 AuthProvider: Manual email verification check');

      // First try the normal check
      bool isVerified = await checkEmailVerification();

      if (isVerified) {
        return true;
      }

      // If normal check fails, try force update
      // This handles cases where email was verified but Firebase Auth has a bug
      print('🔧 AuthProvider: Normal check failed, trying force update...');

      isVerified = await _authService.forceUpdateEmailVerificationStatus();

      if (isVerified) {
        _user = _authService.currentUser;
        _stopEmailVerificationCheck();
        notifyListeners();
        print('✅ AuthProvider: Force verification successful');
        return true;
      }

      return false;

    } catch (e) {
      print('❌ AuthProvider: Manual verification check failed: $e');
      return false;
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordReset(String email) async {
    try {
      _setLoading(true);
      _clearError();

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
  // EMAIL VERIFICATION MONITORING
  // ============================================================================

  /// Start periodic email verification checking
  void _startEmailVerificationCheck() {
    if (_verificationTimer != null) return;

    print('🔄 AuthProvider: Starting email verification monitoring');

    // Add delay before starting to avoid the PigeonUserDetails bug
    Future.delayed(const Duration(seconds: 2), () {
      // ChangeNotifier doesn't have a 'mounted' property.
      // We can check if the timer is already active or if the user is already verified.
      if (_verificationTimer != null || (_user?.emailVerified ?? true)) return;

      _verificationTimer = Timer.periodic(
        const Duration(seconds: 10), // Check every 10 seconds
            (timer) async {
          try {
            final isVerified = await checkEmailVerification();
            if (isVerified) {
              timer.cancel();
              _verificationTimer = null;
            }
          } catch (e) {
            print('❌ AuthProvider: Email verification check error (non-critical): $e');
            // Continue checking despite errors
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
    };
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