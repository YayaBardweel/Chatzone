import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../presentation/pages/auth/email_verification_page.dart';
import '../presentation/pages/auth/forgot_password_page.dart';
import '../presentation/pages/auth/login_page.dart';
import '../presentation/pages/auth/signup_page.dart';
import '../presentation/pages/onboarding/onboarding_page.dart';
import '../presentation/pages/splash/splash_page.dart';

class AppRouter {
  // Route paths
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String emailVerification = '/email-verification';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home'; // For future home page
  static const String profileSetup = '/profile-setup'; // For future profile setup

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    debugLogDiagnostics: true, // Enable debug logging

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

      // Login - Email/password sign in
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) {
          print('🚀 DEBUG: Navigating to Login');
          return const LoginPage();
        },
      ),

      // Sign Up - Email/password registration
      GoRoute(
        path: signUp,
        name: 'signUp',
        builder: (context, state) {
          print('🚀 DEBUG: Navigating to Sign Up');
          return const SignUpPage();
        },
      ),

      // Email Verification - Verify email after signup/signin
      GoRoute(
        path: emailVerification,
        name: 'emailVerification',
        builder: (context, state) {
          print('🚀 DEBUG: Navigating to Email Verification');
          return const EmailVerificationPage();
        },
      ),

      // Forgot Password - Reset password via email
      GoRoute(
        path: forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) {
          final initialEmail = state.extra as String?;
          print('🚀 DEBUG: Navigating to Forgot Password for: $initialEmail');
          return ForgotPasswordPage(initialEmail: initialEmail);
        },
      ),

      // Home page placeholder (for future implementation)
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) {
          print('🚀 DEBUG: Navigating to Home (placeholder)');
          return const _HomePlaceholder();
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

  // Helper methods for navigation
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

  static void goToProfileSetup(BuildContext context) {
    print('🚀 DEBUG: Going to Profile Setup');
    context.go(profileSetup);
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
              'Profile setup page coming soon...',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => AppRouter.goToHome(context),
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Skip for now'),
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
class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.home_rounded,
              size: 100,
              color: Color(0xFF075E54),
            ),
            const SizedBox(height: 24),
            Text(
              'Home Page',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Home page coming soon...',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}