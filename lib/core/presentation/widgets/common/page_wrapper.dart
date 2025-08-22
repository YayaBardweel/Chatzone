
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_sizes.dart';
import 'custom_app_bar.dart';

class PageWrapper extends StatelessWidget {
  final String title;
  final Widget body;
  final bool showBackButton;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomNavigationBar;
  final bool extendBodyBehindAppBar;
  final PreferredSizeWidget? bottom;
  final VoidCallback? onBackPressed;

  const PageWrapper({
    super.key,
    required this.title,
    required this.body,
    this.showBackButton = true,
    this.actions,
    this.backgroundColor,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomNavigationBar,
    this.extendBodyBehindAppBar = false,
    this.bottom,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? Colors.grey.shade50,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: CustomAppBar(
        title: title,
        showBackButton: showBackButton,
        actions: actions,
        bottom: bottom,
        onBackPressed: onBackPressed,
      ),
      body: body,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}