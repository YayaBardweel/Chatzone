import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign in with email and password
  Future<User?> signIn(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } on FirebaseAuthException catch (e) {
      // Handle FirebaseAuth specific exceptions
      print('Sign in error: ${e.message}');
      return null; // You can show specific error messages in the UI
    } catch (e) {
      // Catch other errors that might not be FirebaseAuth specific
      print('Error: $e');
      return null;
    }
  }

  // Register with email and password and username
  Future<User?> signUp(String email, String password, String username) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user != null) {
        await result.user!.updateDisplayName(username);
        await result.user!.reload();

        // Save user data to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(result.user!.uid)
            .set({
          'uid': result.user!.uid,
          'name': username,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('Sign up error: ${e.message}');
      return null;
    } catch (e) {
      print('Error: $e');
      return null;
    }
  }


  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Optional: Get current user's ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Optional: Check if a user is signed in
  bool get isUserLoggedIn => _auth.currentUser != null;

  // Optional: Send email verification (for newly registered users)
  Future<void> sendEmailVerification() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Optional: Check email verification status
  bool isEmailVerified() {
    final user = _auth.currentUser;
    return user != null && user.emailVerified;
  }

  // Optional: Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      print('Reset password error: ${e.message}');
      throw e; // You can handle this in the UI
    } catch (e) {
      print('Error: $e');
      throw e; // You can handle this in the UI
    }
  }
  // Sign in with Google
Future<User?> signInWithGoogle() async {
  try {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return null; // User canceled

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);

    // Save user data to Firestore if new user
    if (result.additionalUserInfo?.isNewUser ?? false) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(result.user!.uid)
          .set({
        'uid': result.user!.uid,
        'name': result.user!.displayName,
        'email': result.user!.email,
        'createdAt': FieldValue.serverTimestamp(),
        'photoUrl': result.user!.photoURL,
      });
    }

    return result.user;
  } on FirebaseAuthException catch (e) {
    print('Google sign-in error: ${e.message}');
    return null;
  } catch (e) {
    print('Error: $e');
    return null;
  }
}
// Check if user is logged in
  Future<bool> isUserLoggedInAsync() async {
    final user = _auth.currentUser;
    return user != null; // Return true if a user is logged in
  }
}