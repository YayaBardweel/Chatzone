import 'package:flutter/material.dart';

import '../../widgets/PrimeColors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kprimecolor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 20,
            ),

            Center(
              child: Image.asset(
                'assets/images/ChatZone Logo Design.png',
                height: 250,width: 400,
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
style: TextStyle(color: Colors.white),

              decoration: InputDecoration(
                fillColor: Colors.black12,
                labelText: 'Email',
                prefixIcon: const Icon(Icons.email,color: Colors.blue,),
                labelStyle: TextStyle(color: Colors.blue),
                filled: true,
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue,),
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
style: TextStyle(color: Colors.white),
              obscureText: true,
              decoration: InputDecoration(
                fillColor: Colors.black12,
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock,color: Colors.blue,),
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
                onPressed:(){
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
                  // Navigator.push(
                  //
                  //   //  context,
                  // //   MaterialPageRoute(
                  // // );
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
                onPressed: ()  {
                },

                icon: const Icon(Icons.g_mobiledata_rounded, color: Colors.red),
                label: Text('Continue with Google', style: TextStyle(color: kTextColor)),
                style: OutlinedButton.styleFrom(
                  // textStyle: TextStyle(color: Colors.white), // Removed as label now handles text color
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.black12, // Added background color here
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Register redirect
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Don't have an account? ",style: TextStyle(color: Colors.blue),),
                GestureDetector(
                  onTap: () {
                    // // Navigator.push(
                    // //   context,
                    // //   MaterialPageRoute(
                    // //     builder: (context) => const RegisterPage(),
                    //   ),
                    // );
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
