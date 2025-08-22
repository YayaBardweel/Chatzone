
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';

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
  });

  @override
  Widget build(BuildContext context) {
    final canPop = GoRouter.of(context).canPop();

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
      leading: _buildLeading(context, canPop),
      actions: actions,
      bottom: bottom,
      automaticallyImplyLeading: false, // We handle this manually
    );
  }

  Widget? _buildLeading(BuildContext context, bool canPop) {
    if (leading != null) {
      return leading;
    }

    if (showBackButton && canPop) {
      return IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded),
        onPressed: onBackPressed ?? () => context.pop(),
        tooltip: 'Back',
      );
    }

    return null;
  }

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
  );
}