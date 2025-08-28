// ============================================================================
// File: lib/core/presentation/widgets/common/page_wrapper.dart (IMPROVED)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_colors.dart';
import '../../../routes/app_router.dart';
import 'custom_app_bar.dart';

enum PageType {
  auth,     // Login, signup, etc.
  main,     // Home, profile, etc.
  secondary, // Settings, details, etc.
  root,     // No back button
}

class PageWrapper extends StatelessWidget {
  final String title;
  final Widget body;
  final PageType pageType;
  final bool showBackButton;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final bool extendBodyBehindAppBar;
  final PreferredSizeWidget? bottom;
  final VoidCallback? onBackPressed;
  final String? fallbackRoute;
  final bool resizeToAvoidBottomInset;
  final Widget? drawer;
  final Widget? endDrawer;

  const PageWrapper({
    super.key,
    required this.title,
    required this.body,
    this.pageType = PageType.main,
    this.showBackButton = true,
    this.actions,
    this.backgroundColor,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.extendBodyBehindAppBar = false,
    this.bottom,
    this.onBackPressed,
    this.fallbackRoute,
    this.resizeToAvoidBottomInset = true,
    this.drawer,
    this.endDrawer,
  });

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _handleWillPop(context),
      child: Scaffold(
        backgroundColor: backgroundColor ?? _getDefaultBackgroundColor(),
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        appBar: _buildAppBar(),
        body: SafeArea(
          child: body,
        ),
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
        bottomNavigationBar: bottomNavigationBar,
        drawer: drawer,
        endDrawer: endDrawer,
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    switch (pageType) {
      case PageType.auth:
        return AuthAppBar(
          title: title,
          showBackButton: showBackButton,
          actions: actions,
          onBackPressed: onBackPressed,
        );

      case PageType.main:
        return MainAppBar(
          title: title,
          showBackButton: showBackButton,
          actions: actions,
          bottom: bottom,
          onBackPressed: onBackPressed,
        );

      case PageType.secondary:
        return SecondaryAppBar(
          title: title,
          actions: actions,
          onBackPressed: onBackPressed,
        );

      case PageType.root:
        return RootAppBar(
          title: title,
          actions: actions,
          bottom: bottom,
        );
    }
  }

  Color _getDefaultBackgroundColor() {
    switch (pageType) {
      case PageType.auth:
        return Colors.white;
      case PageType.main:
      case PageType.secondary:
      case PageType.root:
        return Colors.grey.shade50;
    }
  }

  Future<bool> _handleWillPop(BuildContext context) async {
    // If custom back handler is provided, use it
    if (onBackPressed != null) {
      onBackPressed!();
      return false; // Prevent default back behavior
    }

    // For auth pages, handle carefully
    if (pageType == PageType.auth) {
      return await _handleAuthPageWillPop(context);
    }

    // For main app pages, allow normal back behavior
    if (context.canPop()) {
      return true; // Allow default back behavior
    } else {
      // Navigate to fallback route
      final fallback = fallbackRoute ?? AppRouter.home;
      context.go(fallback);
      return false; // Prevent default back behavior
    }
  }

  Future<bool> _handleAuthPageWillPop(BuildContext context) async {
    final currentRoute = GoRouterState.of(context).uri.path;

    // Special handling for specific auth pages
    switch (currentRoute) {
      case AppRouter.emailVerification:
      // Don't allow back from email verification
        return false;

      case AppRouter.forgotPassword:
      // Allow back to login
        AppRouter.goToLogin(context);
        return false;

      case AppRouter.signUp:
      // Allow back to login
        AppRouter.goToLogin(context);
        return false;

      case AppRouter.login:
      // Show exit confirmation
        return await _showExitConfirmation(context);

      default:
        return true;
    }
  }

  Future<bool> _showExitConfirmation(BuildContext context) async {
    return await AppRouter.showNavigationConfirmation(
      context,
      title: 'Exit App',
      message: 'Are you sure you want to exit the app?',
      confirmText: 'Exit',
      cancelText: 'Stay',
    );
  }
}

// ============================================================================
// SPECIALIZED PAGE WRAPPER VARIANTS
// ============================================================================

/// Wrapper for authentication pages
class AuthPageWrapper extends PageWrapper {
  const AuthPageWrapper({
    super.key,
    required super.title,
    required super.body,
    super.showBackButton = true,
    super.actions,
    super.onBackPressed,
    super.resizeToAvoidBottomInset = true,
  }) : super(
    pageType: PageType.auth,
    backgroundColor: Colors.white,
  );
}

/// Wrapper for main app pages
class MainPageWrapper extends PageWrapper {
  const MainPageWrapper({
    super.key,
    required super.title,
    required super.body,
    super.showBackButton = true,
    super.actions,
    super.bottom,
    super.floatingActionButton,
    super.floatingActionButtonLocation,
    super.onBackPressed,
    super.drawer,
    super.endDrawer,
  }) : super(
    pageType: PageType.main,
    fallbackRoute: AppRouter.home,
  );
}

/// Wrapper for secondary pages (settings, details, etc.)
class SecondaryPageWrapper extends PageWrapper {
  const SecondaryPageWrapper({
    super.key,
    required super.title,
    required super.body,
    super.actions,
    super.floatingActionButton,
    super.floatingActionButtonLocation,
    super.onBackPressed,
  }) : super(
    pageType: PageType.secondary,
    showBackButton: true,
    fallbackRoute: AppRouter.home,
  );
}

/// Wrapper for root pages (no back button)
class RootPageWrapper extends PageWrapper {
  const RootPageWrapper({
    super.key,
    required super.title,
    required super.body,
    super.actions,
    super.bottom,
    super.floatingActionButton,
    super.floatingActionButtonLocation,
    super.bottomNavigationBar,
    super.drawer,
    super.endDrawer,
  }) : super(
    pageType: PageType.root,
    showBackButton: false,
  );
}