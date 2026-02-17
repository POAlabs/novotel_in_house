//everything concerning authentication is here 

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../config/departments.dart';
import 'debug_log_service.dart';

// Authentication service for Firebase
// Handles user sign-in, sign-out, and auth state
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DebugLogService _debugLog = DebugLogService();

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

// TODO: remove this temporary bypass of to the application once in production or after adding the 
//the admin users
  // added this because i do not want to keep on logging in to the application set false if you want 
  // to authenticate
  static const bool _temporaryBypass = true;

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

  //actual sign in with email and password

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    
    debugPrint('🔐 [AUTH_SERVICE] signInWithEmail called for: $normalizedEmail');
    _debugLog.addLog(
      'AUTH_SERVICE',
      'Sign in attempt',
      data: {'email': normalizedEmail, 'firebaseInitialized': _firebaseInitialized},
    );

    // Try Firebase auth if initialized
    if (_firebaseInitialized) {
      try {
        debugPrint('🔐 [AUTH_SERVICE] Attempting Firebase authentication...');
        final userCredential = await _auth.signInWithEmailAndPassword(
          email: normalizedEmail,
          password: password,
        );

        if (userCredential.user == null) {
          debugPrint('❌ [AUTH_SERVICE] Sign in failed: No user returned');
          _debugLog.addLog(
            'AUTH_SERVICE',
            'Sign in failed: No user returned',
            data: {'email': normalizedEmail},
            isError: true,
          );
          throw Exception('Sign in failed: No user returned. Please contact Harrison 07 910 190 89. He Never Disappoints');
        }

        debugPrint('✅ [AUTH_SERVICE] Firebase auth successful, UID: ${userCredential.user!.uid}');
        _debugLog.addLog(
          'AUTH_SERVICE',
          'Firebase auth successful',
          data: {'uid': userCredential.user!.uid},
        );

        // Fetch user profile from Firestore
        debugPrint('🔐 [AUTH_SERVICE] Fetching user profile from Firestore...');
        final userDoc = await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();

        if (!userDoc.exists) {
          // User exists in Auth but not in Firestore
          debugPrint('❌ [AUTH_SERVICE] User not found in Firestore');
          _debugLog.addLog(
            'AUTH_SERVICE',
            'User not found in Firestore',
            data: {'uid': userCredential.user!.uid},
            isError: true,
          );
          await _auth.signOut();
          throw Exception(
            'Access denied. Please contact Harrison 07 910 190 89. He Never Disappoints',
          );
        }

        final user = UserModel.fromFirestore(userDoc);
        debugPrint('✅ [AUTH_SERVICE] User profile loaded: ${user.displayName} (${user.role.displayName})');
        _debugLog.addLog(
          'AUTH_SERVICE',
          'User profile loaded from Firestore',
          data: {
            'uid': user.uid,
            'displayName': user.displayName,
            'role': user.role.displayName,
            'department': user.department,
            'isActive': user.isActive,
          },
        );

        // Check if user is active
        if (!user.isActive) {
          debugPrint('❌ [AUTH_SERVICE] User account is deactivated');
          _debugLog.addLog(
            'AUTH_SERVICE',
            'User account deactivated',
            data: {'uid': user.uid, 'email': user.email},
            isError: true,
          );
          await _auth.signOut();
          throw Exception(
            'Your account has been deactivated. Please contact Harrison 07 910 190 89. He Never Disappoints',
          );
        }

        _currentUser = user;
        debugPrint('✅ [AUTH_SERVICE] Sign in complete for ${user.displayName}');
        _debugLog.addLog(
          'AUTH_SERVICE',
          'Sign in successful',
          data: {'uid': user.uid, 'displayName': user.displayName},
        );
        return user;
      } on FirebaseAuthException catch (e) {
        debugPrint('❌ [AUTH_SERVICE] FirebaseAuthException: ${e.code} - ${e.message}');
        _debugLog.addLog(
          'AUTH_SERVICE',
          'Firebase auth error: ${e.code}',
          data: {'code': e.code, 'message': e.message, 'email': normalizedEmail},
          isError: true,
        );
        throw Exception(_getFirebaseAuthErrorMessage(e.code));
      } catch (e, stackTrace) {
        debugPrint('❌ [AUTH_SERVICE] Unexpected error: $e');
        _debugLog.addLog(
          'AUTH_SERVICE',
          'Unexpected sign in error: $e',
          data: {'email': normalizedEmail, 'stackTrace': stackTrace.toString()},
          isError: true,
        );
        rethrow;
      }
    }

    // If Firebase not initialized, reject login
    debugPrint('❌ [AUTH_SERVICE] Firebase not initialized');
    _debugLog.addLog(
      'AUTH_SERVICE',
      'Sign in failed: Firebase not initialized',
      isError: true,
    );
    throw Exception(
      'Firebase not configured. Please contact Harrison 07 910 190 89. He Never Disappoints',
    );
  }

  /// Sign out current user
  Future<void> signOut() async {
    debugPrint('🔐 [AUTH_SERVICE] signOut called');
    _debugLog.addLog(
      'AUTH_SERVICE',
      'Sign out requested',
      data: {'currentUser': _currentUser?.email},
    );
    
    try {
      if (_firebaseInitialized) {
        await _auth.signOut();
      }
      _currentUser = null;
      debugPrint('✅ [AUTH_SERVICE] Sign out successful');
      _debugLog.addLog('AUTH_SERVICE', 'Sign out successful');
    } catch (e, stackTrace) {
      debugPrint('❌ [AUTH_SERVICE] Sign out failed: $e');
      _debugLog.addLog(
        'AUTH_SERVICE',
        'Sign out failed: $e',
        data: {'stackTrace': stackTrace.toString()},
        isError: true,
      );
      throw Exception('Sign out failed: ${e.toString()}');
    }
  }

  // Get current Firebase user
  User? get firebaseUser => _firebaseInitialized ? _auth.currentUser : null;

  // Listen to authentication state changes
  Stream<User?> authStateChanges() {
    if (_firebaseInitialized) {
      return _auth.authStateChanges();
    }
    // Return empty stream if Firebase not initialized
    return Stream.value(null);
  }

  // Check if user is logged in
  bool get isLoggedIn => _currentUser != null;

  // Get user-friendly error message for Firebase Auth errors
  String _getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email. Please contact Harrison 07 910 190 89. He Never Disappoints';
      case 'wrong-password':
        return 'Invalid password. Please try again.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact Harrison 07 910 190 89. He Never Disappoints';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      default:
        return 'Sign in failed. Please try again.';
    }
  }

  // Refresh current user data from Firestore
  Future<void> refreshCurrentUser() async {
    debugPrint('🔐 [AUTH_SERVICE] refreshCurrentUser called');
    
    if (!_firebaseInitialized || _auth.currentUser == null) {
      debugPrint('⚠️ [AUTH_SERVICE] Cannot refresh: Firebase not initialized or no current user');
      _debugLog.addLog(
        'AUTH_SERVICE',
        'Cannot refresh user',
        data: {'firebaseInitialized': _firebaseInitialized, 'hasCurrentUser': _auth.currentUser != null},
      );
      return;
    }

    _debugLog.addLog(
      'AUTH_SERVICE',
      'Refreshing current user data',
      data: {'uid': _auth.currentUser!.uid},
    );

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .get();

      if (userDoc.exists) {
        _currentUser = UserModel.fromFirestore(userDoc);
        debugPrint('✅ [AUTH_SERVICE] User data refreshed: ${_currentUser?.displayName}');
        _debugLog.addLog(
          'AUTH_SERVICE',
          'User data refreshed',
          data: {'displayName': _currentUser?.displayName, 'role': _currentUser?.role.displayName},
        );
      } else {
        debugPrint('⚠️ [AUTH_SERVICE] User document not found during refresh');
        _debugLog.addLog(
          'AUTH_SERVICE',
          'User document not found during refresh',
          data: {'uid': _auth.currentUser!.uid},
        );
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [AUTH_SERVICE] Error refreshing user: $e');
      _debugLog.addLog(
        'AUTH_SERVICE',
        'Error refreshing user: $e',
        data: {'stackTrace': stackTrace.toString()},
        isError: true,
      );
    }
  }
}
