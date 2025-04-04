import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to listen to auth state changes
  Stream<User?> get user {
    return _auth.authStateChanges();
  }

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print("Sign-in error: $e");
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Clear local data
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear(); // Clear all data in shared_preferences
      print("Local data cleared successfully");

      // Sign out from Firebase
      await _auth.signOut();
      print("User signed out successfully");
    } catch (e) {
      print("Sign-out error: $e");
      rethrow;
    }
  }
}
