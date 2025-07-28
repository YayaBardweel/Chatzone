import 'package:chatzone2/screens/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatzone2/services/auth_service.dart';


import '../../widgets/PrimeColors.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

Future<void> login() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  if (email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter email and password')),
    );
    return;
  }
  if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please enter a valid email address')),
    );
    return;
  }

  if (password.length < 6) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password must be at least 6 characters')),
    );
    return;
  }

  final user = await AuthService().signIn(email, password);
  if (user != null) {
    Navigator.pushReplacementNamed(context, '/home');
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Login failed. Please check your credentials.')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kprimecolor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20),

            Center(
              child: Image.asset(
                'assets/images/ChatZone Logo Design.png',
                height: 250,
                width: 400,
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                'Welcome Back!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kTextColor,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Login to Continue',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: kTextColor,
              ),
            ),
            const SizedBox(height: 24),

            // Email field
            TextField(
              controller: _emailController,
              style: TextStyle(color: Colors.white),

              decoration: InputDecoration(
                fillColor: Colors.black12,
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email, color: Colors.blue),
                labelStyle: TextStyle(color: Colors.blue),
                filled: true,
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                  borderRadius: BorderRadius.circular(40),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Password field
            TextField(
              controller: _passwordController,
              style: TextStyle(color: Colors.white),
              obscureText: true,
              decoration: InputDecoration(
                fillColor: Colors.black12,
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock, color: Colors.blue),
                labelStyle: TextStyle(color: Colors.blue),
                filled: true,
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue),
                  borderRadius: BorderRadius.circular(40),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(40),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Login button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  login(); // Call the login function when the button is pressed
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Login',
                  style: TextStyle(fontSize: 16, color: kTextColor),
                ),
              ),
            ),

            const SizedBox(height: 12),
            Center(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen(),
                    ),
                  );
                },
                child: Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    decorationColor: kTextColor,
                    decorationThickness: 1.3,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // OR divider
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('OR', style: TextStyle(color: kTextColor)),
                ),
                const Expanded(child: Divider()),
              ],
            ),

            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                onPressed: () {},

                icon: const Icon(Icons.g_mobiledata_rounded, color: Colors.red),
                label: Text(
                  'Continue with Google',
                  style: TextStyle(color: kTextColor),
                ),
                style: OutlinedButton.styleFrom(
                  // textStyle: TextStyle(color: Colors.white), // Removed as label now handles text color
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor:
                      Colors.black12, // Added background color here
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Register redirect
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(color: Colors.blue),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RegasterScreen(),
                      ),
                    );
                  },
                  child: Text(
                    'Register Now',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
