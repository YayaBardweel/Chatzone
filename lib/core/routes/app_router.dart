import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
import '../providers/auth_provider.dart';

class AppRouter {
  // Route paths
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String emailVerification = '/email-verification';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String contacts = '/contacts';
  static const String addContact = '/add-contact';
  static const String settings = '/settings';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    debugLogDiagnostics: true,

    // FIXED: Add redirect logic for proper user flow
    redirect: (context, state) {
      final authProvider = context.read<AuthProvider>();
      final isAuthenticated = authProvider.isAuthenticated;
      final isEmailVerified = authProvider.isEmailVerified;
      final isFirstTime = authProvider.isFirstTime;
      final isInitialized = authProvider.isInitialized;

      print('🔄 Navigation redirect check:');
      print('  - Location: ${state.uri.path}');
      print('  - Authenticated: $isAuthenticated');
      print('  - Email Verified: $isEmailVerified');
      print('  - First Time: $isFirstTime');
      print('  - Initialized: $isInitialized');

      // Don't redirect if not initialized yet
      if (!isInitialized) {
        return state.uri.path == splash ? null : splash;
      }

      final currentPath = state.uri.path;

      // If user is on splash, redirect based on auth state
      if (currentPath == splash) {
        if (isAuthenticated) {
          if (isEmailVerified) {
            return home;
          } else {
            return emailVerification;
          }
        } else {
          return isFirstTime ? onboarding : login;
        }
      }

      // If user is authenticated but email not verified
      if (isAuthenticated && !isEmailVerified) {
        if (currentPath != emailVerification) {
          return emailVerification;
        }
      }

      // If user is authenticated and verified, don't allow auth pages
      if (isAuthenticated && isEmailVerified) {
        final authPages = [
          login,
          signUp,
          onboarding,
          forgotPassword,
          emailVerification
        ];
        if (authPages.contains(currentPath)) {
          return home;
        }
      }

      // If user is not authenticated, only allow auth pages and onboarding
      if (!isAuthenticated) {
        final allowedPages = [
          login,
          signUp,
          onboarding,
          forgotPassword,
          splash
        ];
        if (!allowedPages.contains(currentPath)) {
          return login;
        }
      }

      return null; // No redirect needed
    },

    // FIXED: Better error handling
    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Navigation Error'),
          backgroundColor: const Color(0xFF075E54),
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Colors.red,
                ),
                const SizedBox(height: 24),
                Text(
                  'Page Not Found',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'The page "${state.uri.path}" could not be found.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () => context.go(home),
                  icon: const Icon(Icons.home),
                  label: const Text('Go to Home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF075E54),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go(login),
                  child: const Text('Go to Login'),
                ),
              ],
            ),
          ),
        ),
      );
    },

    routes: [
      // FIXED: Splash Screen with proper navigation
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) {
          print('🚀 DEBUG: Building Splash page');
          return const SplashPage();
        },
      ),

      // FIXED: Onboarding with proper back navigation
      GoRoute(
        path: onboarding,
        name: 'onboarding',
        builder: (context, state) {
          print('🚀 DEBUG: Building Onboarding page');
          return const OnboardingPage();
        },
      ),

      // FIXED: Authentication routes with proper flow
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) {
          print('🚀 DEBUG: Building Login page');
          return const LoginPage();
        },
      ),

      GoRoute(
        path: signUp,
        name: 'signUp',
        builder: (context, state) {
          print('🚀 DEBUG: Building SignUp page');
          return const SignUpPage();
        },
      ),

      GoRoute(
        path: emailVerification,
        name: 'emailVerification',
        builder: (context, state) {
          print('🚀 DEBUG: Building Email Verification page');
          return const EmailVerificationPage();
        },
      ),

      GoRoute(
        path: forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) {
          final initialEmail = state.extra as String?;
          print('🚀 DEBUG: Building Forgot Password page for: $initialEmail');
          return ForgotPasswordPage(initialEmail: initialEmail);
        },
      ),

      // FIXED: Main app routes with shell navigation
      ShellRoute(
        builder: (context, state, child) {
          // This creates a shell that wraps the main app pages
          return child;
        },
        routes: [
          GoRoute(
            path: home,
            name: 'home',
            builder: (context, state) {
              print('🚀 DEBUG: Building Home page');
              return const HomePage();
            },
          ),
          GoRoute(
            path: profile,
            name: 'profile',
            builder: (context, state) {
              print('🚀 DEBUG: Building Profile page');
              return const ProfilePage();
            },
          ),
          GoRoute(
            path: contacts,
            name: 'contacts',
            builder: (context, state) {
              print('🚀 DEBUG: Building Contacts page');
              return const ContactsPage();
            },
          ),
          GoRoute(
            path: addContact,
            name: 'addContact',
            builder: (context, state) {
              print('🚀 DEBUG: Building Add Contact page');
              return const AddContactPage();
            },
          ),
          GoRoute(
            path: settings,
            name: 'settings',
            builder: (context, state) {
              print('🚀 DEBUG: Building Settings page');
              return const _SettingsPage();
            },
          ),
        ],
      ),
    ],
  );

  // ============================================================================
  // ENHANCED NAVIGATION HELPER METHODS
  // ============================================================================

  /// Navigate to splash (app start)
  static void goToSplash(BuildContext context) {
    print('🚀 Navigation: Going to Splash');
    context.go(splash);
  }

  /// Navigate to onboarding
  static void goToOnboarding(BuildContext context) {
    print('🚀 Navigation: Going to Onboarding');
    context.go(onboarding);
  }

  /// Navigate to login
  static void goToLogin(BuildContext context) {
    print('🚀 Navigation: Going to Login');
    context.go(login);
  }

  /// Navigate to sign up
  static void goToSignUp(BuildContext context) {
    print('🚀 Navigation: Going to Sign Up');
    context.go(signUp);
  }

  /// Navigate to email verification
  static void goToEmailVerification(BuildContext context) {
    print('🚀 Navigation: Going to Email Verification');
    context.go(emailVerification);
  }

  /// Navigate to forgot password
  static void goToForgotPassword(BuildContext context, [String? email]) {
    print('🚀 Navigation: Going to Forgot Password with email: $email');
    context.go(forgotPassword, extra: email);
  }

  /// Navigate to home (main app)
  static void goToHome(BuildContext context) {
    print('🚀 Navigation: Going to Home');
    context.go(home);
  }

  /// Navigate to profile
  static void goToProfile(BuildContext context) {
    print('🚀 Navigation: Going to Profile');
    context.go(profile);
  }

  /// Navigate to contacts
  static void goToContacts(BuildContext context) {
    print('🚀 Navigation: Going to Contacts');
    context.go(contacts);
  }

  /// Navigate to add contact
  static void goToAddContact(BuildContext context) {
    print('🚀 Navigation: Going to Add Contact');
    context.go(addContact);
  }

  /// Navigate to settings
  static void goToSettings(BuildContext context) {
    print('🚀 Navigation: Going to Settings');
    context.go(settings);
  }

  // ============================================================================
  // ENHANCED NAVIGATION UTILITIES
  // ============================================================================

  /// Go back or to a fallback route
  static void goBackOrTo(BuildContext context, String fallbackRoute) {
    if (context.canPop()) {
      print('🚀 Navigation: Going back');
      context.pop();
    } else {
      print('🚀 Navigation: Cannot go back, going to $fallbackRoute');
      context.go(fallbackRoute);
    }
  }

  /// Go back or to home
  static void goBackOrHome(BuildContext context) {
    goBackOrTo(context, home);
  }

  /// Replace current route
  static void replaceTo(BuildContext context, String route) {
    print('🚀 Navigation: Replacing current route with $route');
    context.pushReplacement(route);
  }

  /// Clear stack and go to route
  static void clearAndGoTo(BuildContext context, String route) {
    print('🚀 Navigation: Clearing stack and going to $route');
    context.go(route);
  }

  /// Push a route and return result
  static Future<T?> pushAndWaitForResult<T>(
      BuildContext context, String route) async {
    print('🚀 Navigation: Pushing $route and waiting for result');
    return await context.push<T>(route);
  }

  /// Check if we can navigate back
  static bool canGoBack(BuildContext context) {
    return context.canPop();
  }

  /// Get current route name
  static String getCurrentRoute(BuildContext context) {
    final route = GoRouterState.of(context).uri.path;
    print('🚀 Navigation: Current route is $route');
    return route;
  }

  /// Check if current route matches
  static bool isCurrentRoute(BuildContext context, String route) {
    return getCurrentRoute(context) == route;
  }

  /// Navigate based on auth state
  static void navigateBasedOnAuthState(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.isAuthenticated) {
      if (authProvider.isEmailVerified) {
        goToHome(context);
      } else {
        goToEmailVerification(context);
      }
    } else {
      if (authProvider.isFirstTime) {
        goToOnboarding(context);
      } else {
        goToLogin(context);
      }
    }
  }

  /// Handle authentication success navigation
  static void handleAuthSuccess(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    if (authProvider.isEmailVerified) {
      clearAndGoTo(context, home);
    } else {
      clearAndGoTo(context, emailVerification);
    }
  }

  /// Handle logout navigation
  static void handleLogout(BuildContext context) {
    clearAndGoTo(context, login);
  }

  /// Show confirmation dialog before navigation
  static Future<bool> showNavigationConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Yes',
    String cancelText = 'No',
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmText),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}

// ============================================================================
// IMPROVED SETTINGS PAGE
// ============================================================================

class _SettingsPage extends StatelessWidget {
  const _SettingsPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF075E54),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => AppRouter.goBackOrHome(context),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),

          // Profile Section
          _buildSettingsSection(
            context,
            'Profile',
            [
              _buildSettingsTile(
                context,
                'Edit Profile',
                'Update your personal information',
                Icons.person_outline,
                () => AppRouter.goToProfile(context),
              ),
              _buildSettingsTile(
                context,
                'Privacy',
                'Control who can see your information',
                Icons.privacy_tip_outlined,
                () => _showComingSoon(context, 'Privacy settings'),
              ),
            ],
          ),

          // Chat Section
          _buildSettingsSection(
            context,
            'Chats',
            [
              _buildSettingsTile(
                context,
                'Chat Backup',
                'Back up your chat history',
                Icons.backup_outlined,
                () => _showComingSoon(context, 'Chat backup'),
              ),
              _buildSettingsTile(
                context,
                'Chat Wallpaper',
                'Customize chat background',
                Icons.wallpaper_outlined,
                () => _showComingSoon(context, 'Chat wallpaper'),
              ),
            ],
          ),

          // Notifications Section
          _buildSettingsSection(
            context,
            'Notifications',
            [
              _buildSettingsTile(
                context,
                'Message Notifications',
                'Control notification settings',
                Icons.notifications_outlined,
                () => _showComingSoon(context, 'Notification settings'),
              ),
              _buildSettingsTile(
                context,
                'Group Notifications',
                'Manage group chat notifications',
                Icons.group_outlined,
                () => _showComingSoon(context, 'Group notifications'),
              ),
            ],
          ),

          // Account Section
          _buildSettingsSection(
            context,
            'Account',
            [
              _buildSettingsTile(
                context,
                'Account Info',
                'View account details',
                Icons.info_outline,
                () => AppRouter.goToProfile(context),
              ),
              _buildSettingsTile(
                context,
                'Delete Account',
                'Permanently delete your account',
                Icons.delete_outline,
                () => _showDeleteAccountDialog(context),
                isDestructive: true,
              ),
            ],
          ),

          // Support Section
          _buildSettingsSection(
            context,
            'Support',
            [
              _buildSettingsTile(
                context,
                'Help Center',
                'Get help and support',
                Icons.help_outline,
                () => _showComingSoon(context, 'Help center'),
              ),
              _buildSettingsTile(
                context,
                'About',
                'App version and information',
                Icons.info_outline,
                () => _showAboutDialog(context),
              ),
            ],
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(
    BuildContext context,
    String title,
    List<Widget> tiles,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF075E54),
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: tiles),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDestructive
              ? Colors.red.withOpacity(0.1)
              : const Color(0xFF075E54).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : const Color(0xFF075E54),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDestructive ? Colors.red : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: const Color(0xFF075E54),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This action cannot be undone. All your data will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoon(context, 'Account deletion');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'ChatZone',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: const Color(0xFF075E54),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.chat_bubble_rounded,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        const Text(
            'A WhatsApp-like chat application built with Flutter and Firebase.'),
      ],
    );
  }
}
