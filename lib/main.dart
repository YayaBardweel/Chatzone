
import 'package:chatzone2/screens/auth/login_screen.dart';
import 'package:chatzone2/screens/onboarding/OnboardingPage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


void main () async{
  runApp(MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/onboarding',
      routes: {
        '/onboarding': (context) => const OnboardingPage(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
