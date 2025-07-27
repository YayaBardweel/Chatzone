import 'package:chatzone2/screens/onboarding/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/login_screen.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  bool _seeOnboarding = false;

  @override
  void initState() {
    super.initState();
    _checkIfSeenOnboarding();
  }

  Future<void> _checkIfSeenOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _seeOnboarding = prefs.getBool('seenOnboarding') ?? false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_seeOnboarding) {
        Navigator.pushReplacementNamed(context, '/login');
      } else {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    });
  }

  Future<void> _finishOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('seenOnboarding', true);
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView(
            children: [
              WelcomeScreen(onComplete: _finishOnboarding),
            ],
          ),
        ],
      ),
    );
  }
}