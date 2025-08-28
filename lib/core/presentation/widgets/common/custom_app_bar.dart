// ============================================================================
// File: lib/core/presentation/widgets/common/custom_app_bar.dart (IMPROVED)
// ============================================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_colors.dart';
import '../../../routes/app_router.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final List<Widget>? actions;
  final Widget? leading;
  final double? elevation;
  final VoidCallback? onBackPressed;
  final PreferredSizeWidget? bottom;
  final String? fallbackRoute;
  final bool automaticallyImplyLeading;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.centerTitle = true,
    this.backgroundColor,
    this.foregroundColor,
    this.actions,
    this.leading,
    this.elevation,
    this.onBackPressed,
    this.bottom,
    this.fallbackRoute,
    this.automaticallyImplyLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: foregroundColor ?? Colors.white,
        ),
      ),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? AppColors.primary,
      foregroundColor: foregroundColor ?? Colors.white,
      elevation: elevation ?? 0,
      leading: _buildLeading(context),
      actions: actions,
      bottom: bottom,
      automaticallyImplyLeading: false, // We handle this manually
    );
  }

  Widget? _buildLeading(BuildContext context) {
    // If custom leading is provided, use it
    if (leading != null) {
      return leading;
    }

    // If showBackButton is false, return null
    if (!showBackButton) {
      return null;
    }

    // If automaticallyImplyLeading is false, return null
    if (!automaticallyImplyLeading) {
      return null;
    }

    // Create back button with smart navigation
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios_rounded),
      onPressed: () => _handleBackNavigation(context),
      tooltip: 'Back',
    );
  }

  void _handleBackNavigation(BuildContext context) {
    // If custom back handler is provided, use it
    if (onBackPressed != null) {
      onBackPressed!();
      return;
    }

    // Smart back navigation
    if (context.canPop()) {
      // Can go back in navigation stack
      context.pop();
    } else {
      // Cannot go back, use fallback route or home
      final fallback = fallbackRoute ?? AppRouter.home;
      print('🚀 CustomAppBar: Cannot go back, navigating to $fallback');
      context.go(fallback);
    }
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
  );
}

// ============================================================================
// SPECIALIZED APP BAR VARIANTS
// ============================================================================

/// App bar for authentication pages (login, signup, etc.)
class AuthAppBar extends CustomAppBar {
  const AuthAppBar({
    super.key,
    required super.title,
    super.showBackButton = true,
    super.actions,
    super.onBackPressed,
  }) : super(
    backgroundColor: Colors.transparent,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
    fallbackRoute: AppRouter.login,
  );
}

/// App bar for main app pages (home, profile, etc.)
class MainAppBar extends CustomAppBar {
  const MainAppBar({
    super.key,
    required super.title,
    super.showBackButton = true,
    super.actions,
    super.bottom,
    super.onBackPressed,
  }) : super(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    fallbackRoute: AppRouter.home,
  );
}

/// App bar for settings and secondary pages
class SecondaryAppBar extends CustomAppBar {
  const SecondaryAppBar({
    super.key,
    required super.title,
    super.actions,
    super.onBackPressed,
  }) : super(
    showBackButton: true,
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    fallbackRoute: AppRouter.home,
  );
}

/// App bar without back button (for root pages)
class RootAppBar extends CustomAppBar {
  const RootAppBar({
    super.key,
    required super.title,
    super.actions,
    super.bottom,
  }) : super(
    showBackButton: false,
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
  );
}