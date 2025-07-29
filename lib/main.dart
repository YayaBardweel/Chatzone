import 'package:chatzone2/screens/auth/login_screen.dart';
import 'package:chatzone2/screens/home/home_screen.dart';
import 'package:chatzone2/screens/onboarding/OnboardingPage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chatzone2/screens/auth/AuthGate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Retrieve onboarding status from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seenOnboarding') ?? false;

  // Run the app with AuthGate widget to determine which screen to show
  runApp(MainApp(seenOnboarding: seenOnboarding));
}

class MainApp extends StatelessWidget {
  final bool seenOnboarding;

  const MainApp({super.key, required this.seenOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: AuthGate(seenOnboarding: seenOnboarding),  // Use AuthGate to decide the initial screen
      routes: {
        '/onboarding': (context) => const OnboardingPage(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}
