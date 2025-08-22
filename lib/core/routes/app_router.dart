// ============================================================================
// File: lib/core/routes/app_router.dart (UPDATED FOR PHASE 2 IMPLEMENTATIONS)
// ============================================================================

import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../presentation/contacts/contacts_page.dart';
import '../presentation/pages/auth/email_verification_page.dart';
import '../presentation/pages/auth/forgot_password_page.dart';
import '../presentation/pages/auth/login_page.dart';
import '../presentation/pages/auth/signup_page.dart';
import '../presentation/pages/onboarding/onboarding_page.dart';
import '../presentation/pages/splash/splash_page.dart';
import '../presentation/pages/home/home_page.dart';
import '../presentation/profile/profile_page.dart';
import '../presentation/contacts/add_contact_page.dart';

class AppRouter {
  // Route paths
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String emailVerification = '/email-verification';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String profileSetup = '/profile-setup';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String contacts = '/contacts';
  static const String addContact = '/add-contact';
  static const String settings = '/settings';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    debugLogDiagnostics: true,

    // Error handling
    errorBuilder: (context, state) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Navigation Error',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Path: ${state.uri.toString()}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go(splash),
                child: const Text('Go to Home'),
              ),
            ],
          ),
        ),
      );
    },

    routes: [
      // Splash Screen - Entry point
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) {
          print('🚀 DEBUG: Navigating to Splash');
          return const SplashPage();
        },
      ),

      // Onboarding - First time users
      GoRoute(
        path: onboarding,
        name: 'onboarding',
        builder: (context, state) {
          print('🚀 DEBUG: Navigating to Onboarding');
          return const OnboardingPage();
        },
      ),

      // Authentication Routes
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) {
          print('🚀 DEBUG: Navigating to Login');
          return const LoginPage();
        },
      ),

      GoRoute(
        path: signUp,
        name: 'signUp',
        builder: (context, state) {
          print('🚀 DEBUG: Navigating to Sign Up');
          return const SignUpPage();
        },
      ),

      GoRoute(
        path: emailVerification,
        name: 'emailVerification',
        builder: (context, state) {
          print('🚀 DEBUG: Navigating to Email Verification');
          return const EmailVerificationPage();
        },
      ),

      GoRoute(
        path: forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) {
          final initialEmail = state.extra as String?;
          print('🚀 DEBUG: Navigating to Forgot Password for: $initialEmail');
          return ForgotPasswordPage(initialEmail: initialEmail);
        },
      ),

      // Main App Routes
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) {
          print('🚀 DEBUG: Navigating to Home');
          return const HomePage();
        },
      ),

      // Profile Routes - NOW WITH REAL IMPLEMENTATIONS
      GoRoute(
        path: profile,
        name: 'profile',
        builder: (context, state) {
          print('🚀 DEBUG: Navigating to Profile');
          return const ProfilePage();
        },
      ),

      GoRoute(
        path: editProfile,
        name: 'editProfile',
        builder: (context, state) {
          print('🚀 DEBUG: Navigating to Edit Profile (redirect to profile edit mode)');
          // For now, redirect to profile page - it has edit functionality built in
          return const ProfilePage();
        },
      ),

      // Contact Routes - NOW WITH REAL IMPLEMENTATIONS
      GoRoute(
        path: contacts,
        name: 'contacts',
        builder: (context, state) {
          print('🚀 DEBUG: Navigating to Contacts');
          return const ContactsPage();
        },
      ),

      GoRoute(
        path: addContact,
        name: 'addContact',
        builder: (context, state) {
          print('🚀 DEBUG: Navigating to Add Contact (placeholder)');
          return const AddContactPage();
        },
      ),

      // Settings Routes (placeholder for now)
      GoRoute(
        path: settings,
        name: 'settings',
        builder: (context, state) {
          print('🚀 DEBUG: Navigating to Settings (placeholder)');
          return const _SettingsPlaceholder();
        },
      ),

      // Profile setup placeholder (for future implementation)
      GoRoute(
        path: profileSetup,
        name: 'profileSetup',
        builder: (context, state) {
          print('🚀 DEBUG: Navigating to Profile Setup (placeholder)');
          return const _ProfileSetupPlaceholder();
        },
      ),
    ],
  );

  // ============================================================================
  // NAVIGATION HELPER METHODS
  // ============================================================================

  static void goToSplash(BuildContext context) {
    print('🚀 DEBUG: Going to Splash');
    context.go(splash);
  }

  static void goToOnboarding(BuildContext context) {
    print('🚀 DEBUG: Going to Onboarding');
    context.go(onboarding);
  }

  static void goToLogin(BuildContext context) {
    print('🚀 DEBUG: Going to Login');
    context.go(login);
  }

  static void goToSignUp(BuildContext context) {
    print('🚀 DEBUG: Going to Sign Up');
    context.go(signUp);
  }

  static void goToEmailVerification(BuildContext context) {
    print('🚀 DEBUG: Going to Email Verification');
    context.go(emailVerification);
  }

  static void goToForgotPassword(BuildContext context, [String? email]) {
    print('🚀 DEBUG: Going to Forgot Password with email: $email');
    context.go(forgotPassword, extra: email);
  }

  static void goToHome(BuildContext context) {
    print('🚀 DEBUG: Going to Home');
    context.go(home);
  }

  static void goToProfile(BuildContext context) {
    print('🚀 DEBUG: Going to Profile');
    context.go(profile);
  }

  static void goToEditProfile(BuildContext context) {
    print('🚀 DEBUG: Going to Edit Profile');
    context.go(editProfile);
  }

  static void goToContacts(BuildContext context) {
    print('🚀 DEBUG: Going to Contacts');
    context.go(contacts);
  }

  static void goToAddContact(BuildContext context) {
    print('🚀 DEBUG: Going to Add Contact');
    context.go(addContact);
  }

  static void goToSettings(BuildContext context) {
    print('🚀 DEBUG: Going to Settings');
    context.go(settings);
  }

  static void goToProfileSetup(BuildContext context) {
    print('🚀 DEBUG: Going to Profile Setup');
    context.go(profileSetup);
  }
}

// ============================================================================
// REMAINING PLACEHOLDER PAGES (TEMPORARY)
// ============================================================================



class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.settings_rounded,
              size: 100,
              color: Color(0xFF075E54),
            ),
            const SizedBox(height: 24),
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'App settings and preferences\n(Coming in Phase 8)',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSetupPlaceholder extends StatelessWidget {
  const _ProfileSetupPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Setup'),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_add_rounded,
              size: 100,
              color: Color(0xFF075E54),
            ),
            const SizedBox(height: 24),
            Text(
              'Profile Setup',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Complete your profile setup\n(Integrated into main profile page)',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => AppRouter.goToHome(context),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Go to Profile'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF075E54),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}