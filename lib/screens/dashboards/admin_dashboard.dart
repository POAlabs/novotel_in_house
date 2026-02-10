import 'package:flutter/material.dart';
import '../../config/routes.dart';

/// System Admin dashboard
/// Full access: view all issues, manage users, system settings
class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  static const Color kDark = Color(0xFF0F172A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 40),
              _buildContent(),
            ],
          ),
        ),
      ),
    );
  }

  /// Top header
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.business, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 16),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Novotel Westlands',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                'System Admin',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.signIn),
          icon: const Icon(Icons.logout, color: Colors.white70),
          tooltip: 'Sign Out',
        ),
      ],
    );
  }

  /// Dashboard content
  Widget _buildContent() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings_outlined,
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              'System Admin Dashboard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'View all issues, manage users, and system settings',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
