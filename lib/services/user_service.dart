import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../config/departments.dart';
import 'debug_log_service.dart';

/// Service for managing users in Firestore
/// Only System Admins should have access to these methods
class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Singleton instance
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  /// Collection reference
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Add a new user to the system
  /// Creates Firebase Auth account and Firestore document
  Future<UserModel> addUser({
    required String email,
    required String displayName,
    required UserRole role,
    required String department,
    required String temporaryPassword,
    required String createdByUid,
  }) async {
    final timestamp = DateTime.now();
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🔷 [USER_SERVICE] Starting addUser operation');
    debugPrint('   Time: $timestamp');
    debugPrint('   Email: $email');
    debugPrint('   Display Name: $displayName');
    debugPrint('   Role: ${role.displayName}');
    debugPrint('   Department: $department');
    debugPrint('   Password Length: ${temporaryPassword.length} chars');
    debugPrint('   Created By UID: $createdByUid');
    
    DebugLogService().addLog(
      'USER_SERVICE',
      'Starting user creation for $email',
      data: {
        'email': email,
        'displayName': displayName,
        'role': role.displayName,
        'department': department,
      },
    );

    try {
      debugPrint('🔷 [USER_SERVICE] Step 1: Checking Firebase Auth instance');
      debugPrint('   Auth instance: ${_auth.app.name}');
      
      final trimmedEmail = email.trim().toLowerCase();
      debugPrint('🔷 [USER_SERVICE] Step 2: Creating Firebase Auth user');
      debugPrint('   Normalized email: $trimmedEmail');
      
      DebugLogService().addLog(
        'USER_SERVICE',
        'Calling Firebase Auth createUserWithEmailAndPassword',
        data: {'email': trimmedEmail},
      );
      
      // Create Firebase Auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: trimmedEmail,
        password: temporaryPassword,
      );

      debugPrint('✅ [USER_SERVICE] Firebase Auth user created successfully');
      debugPrint('   User Credential: ${userCredential.user != null ? "Valid" : "NULL"}');

      if (userCredential.user == null) {
        const errorMsg = 'Failed to create user account - user credential is null';
        debugPrint('❌ [USER_SERVICE] ERROR: $errorMsg');
        DebugLogService().addLog('USER_SERVICE', errorMsg, isError: true);
        throw Exception(errorMsg);
      }

      final uid = userCredential.user!.uid;
      debugPrint('✅ [USER_SERVICE] User UID generated: $uid');

      // Create user model
      debugPrint('🔷 [USER_SERVICE] Step 3: Creating UserModel object');
      final user = UserModel(
        uid: uid,
        email: trimmedEmail,
        displayName: displayName.trim(),
        role: role,
        department: department,
        isActive: true,
        createdAt: DateTime.now(),
        createdBy: createdByUid,
      );
      
      debugPrint('✅ [USER_SERVICE] UserModel created');
      debugPrint('   Model UID: ${user.uid}');
      debugPrint('   Model Email: ${user.email}');

      // Save to Firestore
      debugPrint('🔷 [USER_SERVICE] Step 4: Saving to Firestore');
      debugPrint('   Collection: users');
      debugPrint('   Document ID: $uid');
      
      final firestoreData = user.toFirestore();
      debugPrint('   Firestore data: $firestoreData');
      
      DebugLogService().addLog(
        'USER_SERVICE',
        'Saving user to Firestore',
        data: {'uid': uid, 'email': trimmedEmail},
      );
      
      await _usersCollection.doc(uid).set(firestoreData);
      
      debugPrint('✅ [USER_SERVICE] User saved to Firestore successfully');
      debugPrint('🎉 [USER_SERVICE] USER CREATION COMPLETED SUCCESSFULLY');
      debugPrint('═══════════════════════════════════════════════════════');
      
      DebugLogService().addLog(
        'USER_SERVICE',
        'User created successfully: $trimmedEmail',
        data: {'uid': uid},
      );
      
      return user;
    } on FirebaseAuthException catch (e) {
      final errorMsg = _getAuthErrorMessage(e.code);
      debugPrint('❌ [USER_SERVICE] FirebaseAuthException caught');
      debugPrint('   Error Code: ${e.code}');
      debugPrint('   Error Message: ${e.message}');
      debugPrint('   Friendly Message: $errorMsg');
      debugPrint('═══════════════════════════════════════════════════════');
      
      DebugLogService().addLog(
        'USER_SERVICE',
        'Firebase Auth Error: ${e.code}',
        data: {
          'code': e.code,
          'message': e.message,
          'email': email,
        },
        isError: true,
      );
      
      throw Exception(errorMsg);
    } catch (e, stackTrace) {
      debugPrint('❌ [USER_SERVICE] Unexpected error caught');
      debugPrint('   Error Type: ${e.runtimeType}');
      debugPrint('   Error Message: $e');
      debugPrint('   Stack Trace: $stackTrace');
      debugPrint('═══════════════════════════════════════════════════════');
      
      DebugLogService().addLog(
        'USER_SERVICE',
        'Unexpected error: $e',
        data: {
          'errorType': e.runtimeType.toString(),
          'stackTrace': stackTrace.toString(),
        },
        isError: true,
      );
      
      throw Exception('Failed to add user: ${e.toString()}');
    }
  }

  /// Update an existing user
  Future<void> updateUser({
    required String uid,
    String? displayName,
    UserRole? role,
    String? department,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (displayName != null) updates['displayName'] = displayName.trim();
      if (role != null) updates['role'] = role.toFirestore();
      if (department != null) updates['department'] = department;
      if (isActive != null) updates['isActive'] = isActive;

      if (updates.isNotEmpty) {
        await _usersCollection.doc(uid).update(updates);
      }
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  /// Deactivate a user (soft delete)
  Future<void> deactivateUser(String uid) async {
    await updateUser(uid: uid, isActive: false);
  }

  /// Reactivate a user
  Future<void> reactivateUser(String uid) async {
    await updateUser(uid: uid, isActive: true);
  }

  /// Delete a user permanently (use with caution)
  Future<void> deleteUserPermanently(String uid) async {
    try {
      // Delete from Firestore
      await _usersCollection.doc(uid).delete();

      // Note: To delete from Firebase Auth, you need Firebase Admin SDK
      // or the user must be signed in. For now, just deactivate.
    } catch (e) {
      throw Exception('Failed to delete user: ${e.toString()}');
    }
  }

  /// Get a single user by UID
  Future<UserModel?> getUser(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to get user: ${e.toString()}');
    }
  }

  /// Get all users as a stream
  Stream<List<UserModel>> getAllUsers() {
    return _usersCollection
        .orderBy('displayName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }

  /// Get all active users
  Stream<List<UserModel>> getActiveUsers() {
    return _usersCollection
        .where('isActive', isEqualTo: true)
        .orderBy('displayName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }

  /// Get users by department
  Stream<List<UserModel>> getUsersByDepartment(String department) {
    return _usersCollection
        .where('department', isEqualTo: department)
        .where('isActive', isEqualTo: true)
        .orderBy('displayName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }

  /// Get users by role
  Stream<List<UserModel>> getUsersByRole(UserRole role) {
    return _usersCollection
        .where('role', isEqualTo: role.toFirestore())
        .where('isActive', isEqualTo: true)
        .orderBy('displayName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromFirestore(doc))
            .toList());
  }

  /// Get user count by department (for dashboard)
  Future<Map<String, int>> getUserCountByDepartment() async {
    final snapshot = await _usersCollection
        .where('isActive', isEqualTo: true)
        .get();

    final counts = <String, int>{};
    for (final dept in Departments.all) {
      counts[dept] = 0;
    }

    for (final doc in snapshot.docs) {
      final dept = doc.data()['department'] as String?;
      if (dept != null && counts.containsKey(dept)) {
        counts[dept] = counts[dept]! + 1;
      }
    }

    return counts;
  }

  /// Get total user count
  Future<int> getTotalUserCount() async {
    final snapshot = await _usersCollection
        .where('isActive', isEqualTo: true)
        .count()
        .get();
    return snapshot.count ?? 0;
  }

  /// Check if email is already in use
  Future<bool> isEmailInUse(String email) async {
    final snapshot = await _usersCollection
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  /// Get error message for Firebase Auth errors
  String _getAuthErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Invalid email address format.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      default:
        return 'Failed to create account. Please try again.';
    }
  }
}
