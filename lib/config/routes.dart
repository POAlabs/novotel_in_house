import 'package:flutter/material.dart';
import '../screens/auth/sign_in_page.dart';
import '../screens/dashboards/employee_dashboard.dart';
import '../screens/dashboards/manager_dashboard.dart';
import '../screens/dashboards/admin_dashboard.dart';
import '../screens/housekeeping/housekeeping_dashboard.dart';
import '../splash_screen.dart';
import '../services/auth_service.dart';
import '../config/departments.dart';

/// Application routes configuration
/// Defines all navigation paths in the app
class AppRoutes {
  // Route names as constants
  static const String splash = '/';
  static const String signIn = '/sign-in';
  static const String employeeDashboard = '/employee-dashboard';
  static const String managerDashboard = '/manager-dashboard';
  static const String adminDashboard = '/admin-dashboard';
  static const String housekeepingDashboard = '/housekeeping-dashboard';

  /// Route map for MaterialApp
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => SplashScreen(nextScreen: const _AuthGateScreen()),
      signIn: (context) => const SignInPage(),
      employeeDashboard: (context) => const EmployeeDashboard(),
      managerDashboard: (context) => const ManagerDashboard(),
      adminDashboard: (context) => const AdminDashboard(),
      housekeepingDashboard: (context) => const HousekeepingDashboard(),
    };
  }

  /// Get the appropriate dashboard route for a user based on department and role
  static String getDashboardRoute({
    required String department,
    required UserRole role,
  }) {
    // IT department gets admin access regardless of role
    if (department == Departments.it) {
      return adminDashboard;
    }

    // System admins always go to admin dashboard
    if (role == UserRole.systemAdmin) {
      return adminDashboard;
    }

    // Managers (all departments) go to manager dashboard
    if (role == UserRole.manager) {
      return managerDashboard;
    }

    // Everyone else (staff, supervisors, all departments including HK and Front Office)
    // uses the same employee dashboard
    return employeeDashboard;
  }
}

/// Checks if a Firebase session already exists.
/// If yes → restores the user profile and goes straight to their dashboard.
/// If no  → shows the Sign-In page.
class _AuthGateScreen extends StatefulWidget {
  const _AuthGateScreen();

  @override
  State<_AuthGateScreen> createState() => _AuthGateScreenState();
}

class _AuthGateScreenState extends State<_AuthGateScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authService = AuthService();

    // Try to restore an existing Firebase session
    final user = await authService.restoreSession();

    if (!mounted) return;

    if (user != null) {
      // Session restored — go directly to the correct dashboard
      final route = AppRoutes.getDashboardRoute(
        department: user.department,
        role: user.role,
      );
      Navigator.pushReplacementNamed(context, route);
    } else {
      // No active session — show sign-in
      Navigator.pushReplacementNamed(context, AppRoutes.signIn);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a plain white screen while checking auth
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF0F172A),
          strokeWidth: 2,
        ),
      ),
    );
  }
}