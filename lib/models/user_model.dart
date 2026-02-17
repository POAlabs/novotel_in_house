//this file is about the user profile 

import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/departments.dart';

// we store the users in user model 
class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String department;
  final bool isActive;
  final DateTime createdAt;
  final String? createdBy; // UID of admin who created this user

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    required this.department,
    this.isActive = true,
    required this.createdAt,
    this.createdBy,
  });

  /// Create from Firestore document
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      role: UserRole.fromString(data['role'] ?? 'staff'),
      department: data['department'] ?? Departments.it,
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'role': role.toFirestore(),
      'department': department,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
    };
  }

  /// Create a copy with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    String? department,
    bool? isActive,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      department: department ?? this.department,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  /// Check if user is a system admin
  bool get isSystemAdmin => role == UserRole.systemAdmin;

  /// Check if user is a manager
  bool get isManager => role == UserRole.manager;

  /// Check if user is regular staff
  bool get isStaff => role == UserRole.staff;

  @override
  String toString() {
    return 'UserModel(uid: $uid, email: $email, displayName: $displayName, role: ${role.displayName}, department: $department, isActive: $isActive)';
  }
}
