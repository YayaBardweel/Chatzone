import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:chatzone2/services/auth_service.dart';
import 'package:fluttertoast/fluttertoast.dart'; // Added fluttertoast
import 'forgot_password_screen.dart';
import 'register_screen.dart';
import '../../widgets/PrimeColors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true; // For password visibility toggle
  bool _isGoogleLoading = false;
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Login function with loading indicator
  Future<void> login() async {
    setState(() {
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(msg: 'Please enter email and password');
      return;
    }

    // Basic email format check
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(msg: 'Please enter a valid email address');
      return;
    }

    if (password.length < 6) {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(msg: 'Password must be at least 6 characters');
      return;
    }

    try {
      final user = await AuthService().signIn(email, password);
      setState(() {
        _isLoading = false;
      });

      if (user != null) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Fluttertoast.showToast(
          msg: 'Login failed. Please check your credentials.',
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Fluttertoast.showToast(msg: 'An error occurred. Please try again.');
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

            // Password field with visibility toggle
            TextField(
              controller: _passwordController,
              style: TextStyle(color: Colors.white),
              obscureText: _obscurePassword,
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
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    color: Colors.blue,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Login button with loading indicator
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : login, // Disable button when loading
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? CircularProgressIndicator(color: kTextColor)
                    : Text(
                        'Login',
                        style: TextStyle(fontSize: 16, color: kTextColor),
                      ),
              ),
            ),

            const SizedBox(height: 12),

            // Forgot password link
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

            // Google login button (optional)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isGoogleLoading
                    ? null
                    : () async {
                        setState(() {
                          _isGoogleLoading = true;
                        });
                        final user = await AuthService().signInWithGoogle();
                        setState(() {
                          _isGoogleLoading = false;
                        });
                        if (user != null) {
                          Navigator.pushReplacementNamed(context, '/home');
                        } else {
                          Fluttertoast.showToast(msg: 'Google sign-in failed.');
                        }
                      },
                icon: _isGoogleLoading
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red,
                        ),
                      )
                    : const Icon(Icons.g_mobiledata_rounded, color: Colors.red),
                label: Text(
                  'Continue with Google',
                  style: TextStyle(color: kTextColor),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.black12,
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
                        builder: (context) => const RegisterScreen(),
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
