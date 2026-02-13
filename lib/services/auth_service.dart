import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../config/departments.dart';

/// Authentication service for Firebase
/// Handles user sign-in, sign-out, and auth state
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton instance
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Currently logged in user (cached)
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  // Flag to check if Firebase is initialized
  static bool _firebaseInitialized = false;
  static bool get firebaseInitialized => _firebaseInitialized;
  static set firebaseInitialized(bool value) => _firebaseInitialized = value;

  // TEMPORARY: Bypass flag for initial admin setup
  // Set to false once you've added users through the admin panel
  static const bool _temporaryBypass = true;

  /// TEMPORARY: Bypass login for initial admin setup
  /// This creates a temporary admin user without authentication
  /// Remove this method once Firebase users are properly set up
  UserModel bypassLoginAsAdmin() {
    final user = UserModel(
      uid: 'temp-admin-bypass',
      email: 'admin@novotel.com',
      displayName: 'Temporary Admin',
      role: UserRole.systemAdmin,
      department: 'IT',
      isActive: true,
      createdAt: DateTime.now(),
    );
    _currentUser = user;
    return user;
  }

  /// Sign in with email and password
  /// Returns UserModel on success, throws exception on failure
  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    // Try Firebase auth if initialized
    if (_firebaseInitialized) {
      try {
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );

        if (userCredential.user == null) {
          throw Exception('Sign in failed: No user returned');
        }

        // Fetch user profile from Firestore
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          // User exists in Auth but not in Firestore
          await _auth.signOut();
          throw Exception(
            'Access denied. Please contact IT Office, Novotel Westlands Nairobi.',
          );
        }

        final user = UserModel.fromFirestore(userDoc);

        // Check if user is active
        if (!user.isActive) {
          await _auth.signOut();
          throw Exception(
            'Your account has been deactivated. Please contact IT Office.',
          );
        }

        _currentUser = user;
        return user;
      } on FirebaseAuthException catch (e) {
        throw Exception(_getFirebaseAuthErrorMessage(e.code));
      }
    }

    // If Firebase not initialized, reject login
    throw Exception(
      'Firebase not configured. Please contact IT Office.',
    );
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      if (_firebaseInitialized) {
        await _auth.signOut();
      }
      _currentUser = null;
    } catch (e) {
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  /// Get current Firebase user
  User? get firebaseUser => _firebaseInitialized ? _auth.currentUser : null;

  /// Listen to authentication state changes
  Stream<User?> authStateChanges() {
    if (_firebaseInitialized) {
      return _auth.authStateChanges();
    }
    // Return empty stream if Firebase not initialized
    return Stream.value(null);
  }

  /// Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  /// Get user-friendly error message for Firebase Auth errors
  String _getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email. Please contact IT Office.';
      case 'wrong-password':
        return 'Invalid password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact IT Office.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Sign in failed. Please try again.';
    }
  }

  /// Refresh current user data from Firestore
  Future<void> refreshCurrentUser() async {
    if (!_firebaseInitialized || _auth.currentUser == null) return;

    final userDoc = await _firestore
        .collection('users')
        .doc(_auth.currentUser!.uid)
        .get();

    if (userDoc.exists) {
      _currentUser = UserModel.fromFirestore(userDoc);
    }
  }
}
