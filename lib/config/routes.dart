import 'package:flutter/material.dart';
import '../screens/auth/sign_in_page.dart';
import '../screens/dashboards/employee_dashboard.dart';
import '../screens/dashboards/manager_dashboard.dart';
import '../screens/dashboards/admin_dashboard.dart';
import '../splash_screen.dart';

/// Application routes configuration
/// Defines all navigation paths in the app
class AppRoutes {
  // Route names as constants
  static const String splash = '/';
  static const String signIn = '/sign-in';
  static const String employeeDashboard = '/employee-dashboard';
  static const String managerDashboard = '/manager-dashboard';
  static const String adminDashboard = '/admin-dashboard';

  /// Route map for MaterialApp
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      splash: (context) => SplashScreen(
        nextScreen: const SignInPage(),
      ),
      signIn: (context) => const SignInPage(),
      employeeDashboard: (context) => const EmployeeDashboard(),
      managerDashboard: (context) => const ManagerDashboard(),
      adminDashboard: (context) => const AdminDashboard(),
    };
  }
}
