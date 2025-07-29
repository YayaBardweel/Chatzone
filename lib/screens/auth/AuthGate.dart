import 'package:flutter/material.dart';
import 'package:chatzone2/services/auth_service.dart';
import 'package:chatzone2/screens/home/home_screen.dart';
import 'package:chatzone2/screens/auth/login_screen.dart';
import 'package:chatzone2/screens/onboarding/OnboardingPage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthGate extends StatefulWidget {
  final bool seenOnboarding;
  const AuthGate({super.key, required this.seenOnboarding});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool? _isLoggedIn;

  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  // Check if the user is logged in
  Future<void> _checkLogin() async {
    final isLoggedIn = await AuthService().isUserLoggedInAsync();
    setState(() {
      _isLoggedIn = isLoggedIn;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Display a loading indicator until login status is determined
    if (_isLoggedIn == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Navigate based on login status and onboarding state
    if (_isLoggedIn!) {
      return const HomeScreen();
    } else if (!widget.seenOnboarding) {
      return const OnboardingPage();
    } else {
      return const LoginScreen();
    }
  }
}
