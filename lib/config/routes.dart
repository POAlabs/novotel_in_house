import 'package:flutter/material.dart';
import '../screens/auth/sign_in_page.dart';
import '../screens/dashboards/employee_dashboard.dart';
import '../screens/dashboards/manager_dashboard.dart';
import '../screens/dashboards/admin_dashboard.dart';
import '../splash_screen.dart';
import '../services/auth_service.dart';

/// Application routes configuration
/// Defines all navigation paths in the app
class AppRoutes {
  // Route names as constants
  static const String splash = '/';
  static const String signIn = '/sign-in';
  static const String employeeDashboard = '/employee-dashboard';
  static const String managerDashboard = '/manager-dashboard';
  static const String adminDashboard = '/admin-dashboard';

  // TEMPORARY: Set to false once users are added via Firebase
  static const bool _bypassLogin = true;

  /// Route map for MaterialApp
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => SplashScreen(
        // TEMPORARY: Bypass login and go directly to admin dashboard
        nextScreen: _bypassLogin ? _BypassAdminWrapper() : const SignInPage(),
      ),
      signIn: (context) => const SignInPage(),
      employeeDashboard: (context) => const EmployeeDashboard(),
      managerDashboard: (context) => const ManagerDashboard(),
      adminDashboard: (context) => const AdminDashboard(),
    };
  }
}

/// TEMPORARY: Wrapper to bypass login and set up admin user
/// Remove this class once Firebase users are properly configured
class _BypassAdminWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Set up temporary admin user
    AuthService().bypassLoginAsAdmin();
    return const AdminDashboard();
  }
}
