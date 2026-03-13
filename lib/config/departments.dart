
// In this file we define the various departments in novotel westlands

class Departments {
  // Prevent instantiation
  Departments._();

  // Department names
  static const String engineering = 'Engineering';
  static const String it = 'IT';
  static const String housekeeping = 'Housekeeping';
  static const String frontOffice = 'Front Office';
  static const String security = 'Security';
  static const String fnb = 'F&B';

  /// All departments list
  static const List<String> all = [
    engineering,
    it,
    housekeeping,
    frontOffice,
    security,
    fnb,
  ];

  /// Get department display name (same as value for now)
  static String getDisplayName(String department) {
    return department;
  }
}

/// User roles in the system
enum UserRole {
  staff,
  supervisor,  // New role: can approve rooms, between staff and manager
  manager,
  systemAdmin;

  /// Get display name for the role
  String get displayName {
    switch (this) {
      case UserRole.staff:
        return 'Staff';
      case UserRole.supervisor:
        return 'Supervisor';
      case UserRole.manager:
        return 'Manager';
      case UserRole.systemAdmin:
        return 'System Admin';
    }
  }

  /// Convert from string (for Firestore)
  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'supervisor':
        return UserRole.supervisor;
      case 'manager':
        return UserRole.manager;
      case 'systemadmin':
      case 'system_admin':
      case 'admin':
        return UserRole.systemAdmin;
      default:
        return UserRole.staff;
    }
  }

  /// Convert to string (for Firestore)
  String toFirestore() {
    switch (this) {
      case UserRole.staff:
        return 'staff';
      case UserRole.supervisor:
        return 'supervisor';
      case UserRole.manager:
        return 'manager';
      case UserRole.systemAdmin:
        return 'systemAdmin';
    }
  }
}
