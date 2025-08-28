// ============================================================================
// File: lib/core/services/navigation_service.dart
// ============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../routes/app_router.dart';


/// Service to handle complex navigation logic and maintain navigation state
class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  // Navigation history stack
  final List<String> _navigationHistory = [];

  // Current route
  String? _currentRoute;

  // ============================================================================
  // NAVIGATION STATE MANAGEMENT
  // ============================================================================

  /// Get current route
  String? get currentRoute => _currentRoute;

  /// Get navigation history
  List<String> get navigationHistory => List.unmodifiable(_navigationHistory);

  /// Update current route
  void updateCurrentRoute(String route) {
    if (_currentRoute != route) {
      if (_currentRoute != null) {
        _navigationHistory.add(_currentRoute!);
      }
      _currentRoute = route;

      // Limit history size
      if (_navigationHistory.length > 10) {
        _navigationHistory.removeAt(0);
      }

      print('🧭 NavigationService: Route updated to $route');
      print('🧭 NavigationService: History: $_navigationHistory');
    }
  }

  /// Get previous route
  String? getPreviousRoute() {
    return _navigationHistory.isNotEmpty ? _navigationHistory.last : null;
  }

  /// Clear navigation history
  void clearHistory() {
    _navigationHistory.clear();
    print('🧭 NavigationService: History cleared');
  }

  // ============================================================================
  // SMART NAVIGATION METHODS
  // ============================================================================

  /// Smart back navigation with fallbacks
  static void smartGoBack(BuildContext context, {String? fallbackRoute}) {
    final service = NavigationService();

    if (context.canPop()) {
      print('🧭 NavigationService: Going back (can pop)');
      context.pop();
    } else {
      // Use previous route from history or fallback
      final previousRoute = service.getPreviousRoute();
      final targetRoute = fallbackRoute ?? previousRoute ?? AppRouter.home;

      print('🧭 NavigationService: Cannot pop, going to $targetRoute');
      context.go(targetRoute);
    }
  }

  /// Navigate with history tracking
  static void navigateWithHistory(BuildContext context, String route) {
    final service = NavigationService();
    final currentRoute = GoRouterState.of(context).uri.path;

    service.updateCurrentRoute(currentRoute);
    print('🧭 NavigationService: Navigating to $route');
    context.go(route);
  }

  /// Push with history tracking
  static Future<T?> pushWithHistory<T>(BuildContext context, String route) {
    final service = NavigationService();
    final currentRoute = GoRouterState.of(context).uri.path;

    service.updateCurrentRoute(currentRoute);
    print('🧭 NavigationService: Pushing $route');
    return context.push<T>(route);
  }

  /// Replace current route
  static void replaceRoute(BuildContext context, String route) {
    print('🧭 NavigationService: Replacing current route with $route');
    context.pushReplacement(route);
  }

  /// Clear stack and navigate
  static void clearAndNavigate(BuildContext context, String route) {
    final service = NavigationService();
    service.clearHistory();
    print('🧭 NavigationService: Clearing stack and navigating to $route');
    context.go(route);
  }

  // ============================================================================
  // AUTHENTICATION FLOW NAVIGATION
  // ============================================================================

  /// Handle authentication flow navigation
  static void handleAuthFlow(BuildContext context, AuthState authState) {
    final service = NavigationService();
    service.clearHistory(); // Clear history on auth state changes

    switch (authState) {
      case AuthState.firstTime:
        print('🧭 NavigationService: First time user - going to onboarding');
        context.go(AppRouter.onboarding);
        break;

      case AuthState.unauthenticated:
        print('🧭 NavigationService: Unauthenticated - going to login');
        context.go(AppRouter.login);
        break;

      case AuthState.emailNotVerified:
        print('🧭 NavigationService: Email not verified - going to verification');
        context.go(AppRouter.emailVerification);
        break;

      case AuthState.authenticated:
        print('🧭 NavigationService: Authenticated - going to home');
        context.go(AppRouter.home);
        break;
    }
  }

  /// Navigate after successful authentication
  static void navigateAfterAuth(BuildContext context, bool isEmailVerified) {
    final service = NavigationService();
    service.clearHistory();

    if (isEmailVerified) {
      clearAndNavigate(context, AppRouter.home);
    } else {
      clearAndNavigate(context, AppRouter.emailVerification);
    }
  }

  /// Navigate after logout
  static void navigateAfterLogout(BuildContext context) {
    final service = NavigationService();
    service.clearHistory();
    clearAndNavigate(context, AppRouter.login);
  }

  // ============================================================================
  // ROUTE VALIDATION & SECURITY
  // ============================================================================

  /// Check if route is accessible in current auth state
  static bool isRouteAccessible(String route, AuthState authState) {
    const authRequiredRoutes = [
      AppRouter.home,
      AppRouter.profile,
      AppRouter.contacts,
      AppRouter.addContact,
      AppRouter.settings,
    ];

    const authNotRequiredRoutes = [
      AppRouter.login,
      AppRouter.signUp,
      AppRouter.forgotPassword,
      AppRouter.onboarding,
      AppRouter.splash,
    ];

    const emailVerificationRequiredRoutes = [
      AppRouter.home,
      AppRouter.profile,
      AppRouter.contacts,
      AppRouter.addContact,
      AppRouter.settings,
    ];

    switch (authState) {
      case AuthState.unauthenticated:
      case AuthState.firstTime:
        return authNotRequiredRoutes.contains(route);

      case AuthState.emailNotVerified:
        return route == AppRouter.emailVerification || authNotRequiredRoutes.contains(route);

      case AuthState.authenticated:
        return true; // Authenticated users can access all routes
    }
  }

  /// Validate and redirect if necessary
  static String? validateAndRedirect(String requestedRoute, AuthState authState) {
    if (!isRouteAccessible(requestedRoute, authState)) {
      switch (authState) {
        case AuthState.firstTime:
          return AppRouter.onboarding;
        case AuthState.unauthenticated:
          return AppRouter.login;
        case AuthState.emailNotVerified:
          return AppRouter.emailVerification;
        case AuthState.authenticated:
          return null; // Should not happen
      }
    }
    return null; // No redirect needed
  }

  // ============================================================================
  // DEEP LINK HANDLING
  // ============================================================================

  /// Handle deep links with authentication check
  static void handleDeepLink(BuildContext context, String deepLink, AuthState authState) {
    print('🧭 NavigationService: Handling deep link: $deepLink');

    final redirectRoute = validateAndRedirect(deepLink, authState);

    if (redirectRoute != null) {
      print('🧭 NavigationService: Deep link requires auth, redirecting to $redirectRoute');
      // Store deep link for later navigation after auth
      _instance._pendingDeepLink = deepLink;
      context.go(redirectRoute);
    } else {
      print('🧭 NavigationService: Deep link accessible, navigating to $deepLink');
      context.go(deepLink);
    }
  }

  /// Pending deep link storage
  String? _pendingDeepLink;

  /// Navigate to pending deep link after authentication
  static void navigateToPendingDeepLink(BuildContext context) {
    final service = NavigationService();
    if (service._pendingDeepLink != null) {
      final pendingRoute = service._pendingDeepLink!;
      service._pendingDeepLink = null;

      print('🧭 NavigationService: Navigating to pending deep link: $pendingRoute');
      context.go(pendingRoute);
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Check if we're on an authentication page
  static bool isOnAuthPage(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;
    const authPages = [
      AppRouter.login,
      AppRouter.signUp,
      AppRouter.forgotPassword,
      AppRouter.emailVerification,
      AppRouter.onboarding,
    ];
    return authPages.contains(currentRoute);
  }

  /// Check if we're on the home page
  static bool isOnHomePage(BuildContext context) {
    final currentRoute = GoRouterState.of(context).uri.path;
    return currentRoute == AppRouter.home;
  }

  /// Get route display name
  static String getRouteDisplayName(String route) {
    const routeNames = {
      AppRouter.splash: 'Splash',
      AppRouter.onboarding: 'Onboarding',
      AppRouter.login: 'Login',
      AppRouter.signUp: 'Sign Up',
      AppRouter.emailVerification: 'Email Verification',
      AppRouter.forgotPassword: 'Forgot Password',
      AppRouter.home: 'Home',
      AppRouter.profile: 'Profile',
      AppRouter.contacts: 'Contacts',
      AppRouter.addContact: 'Add Contact',
      AppRouter.settings: 'Settings',
    };

    return routeNames[route] ?? route;
  }

  /// Debug print navigation state
  static void debugNavigationState(BuildContext context) {
    final service = NavigationService();
    final currentRoute = GoRouterState.of(context).uri.path;

    print('🧭 NavigationService Debug:');
    print('  Current Route: $currentRoute');
    print('  Service Current: ${service.currentRoute}');
    print('  Can Pop: ${context.canPop()}');
    print('  History: ${service.navigationHistory}');
    print('  Pending Deep Link: ${service._pendingDeepLink}');
  }
}

// ============================================================================
// ENUMS & TYPES
// ============================================================================

enum AuthState {
  firstTime,
  unauthenticated,
  emailNotVerified,
  authenticated,
}

// ============================================================================
// NAVIGATION HELPER WIDGET
// ============================================================================

/// Widget that tracks navigation changes
class NavigationTracker extends StatefulWidget {
  final Widget child;

  const NavigationTracker({
    super.key,
    required this.child,
  });

  @override
  State<NavigationTracker> createState() => _NavigationTrackerState();
}

class _NavigationTrackerState extends State<NavigationTracker> with RouteAware {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Update current route when dependencies change
    final route = GoRouterState.of(context).uri.path;
    NavigationService().updateCurrentRoute(route);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}