// import 'package:firebase_auth/firebase_auth.dart';

/// Authentication service for Firebase
/// Handles user sign-in, sign-out, and auth state
class AuthService {
  // final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Sign in with email and password
  /// Returns user role: 'admin', 'manager', or 'employee'
  Future<String?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      // TODO: Implement Firebase authentication
      // UserCredential userCredential = await _auth.signInWithEmailAndPassword(
      //   email: email,
      //   password: password,
      // );

      // TODO: Fetch user role from Firestore based on userCredential.user.uid
      // For now, return role based on email pattern for testing
      final role = _getUserRoleFromEmail(email);
      return role;
    } catch (e) {
      // Handle authentication errors
      throw Exception('Sign in failed: ${e.toString()}');
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      // await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  /// Get current user
  // User? getCurrentUser() {
  //   return _auth.currentUser;
  // }

  /// Listen to authentication state changes
  // Stream<User?> authStateChanges() {
  //   return _auth.authStateChanges();
  // }

  /// Temporary helper to determine role from email (for development)
  /// TODO: Replace with Firestore lookup in production
  String _getUserRoleFromEmail(String email) {
    if (email.contains('admin')) {
      return 'admin';
    } else if (email.contains('manager')) {
      return 'manager';
    } else {
      return 'employee';
    }
  }
}
