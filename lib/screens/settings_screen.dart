import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/routes.dart';
import '../config/departments.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'admin/user_management_screen.dart';
import 'admin/debug_logs_screen.dart';
import 'issue_history_screen.dart';
import 'lost_and_found_screen.dart';

/// Settings screen with role-based options
/// System Admins see additional user management options
class SettingsScreen extends StatelessWidget {
  final UserModel? currentUser;

  const SettingsScreen({super.key, this.currentUser});

  // Design colors
  static const Color kDark = Color(0xFF0F172A);
  static const Color kGrey = Color(0xFF64748B);
  static const Color kAccent = Color(0xFF3B82F6);
  static const Color kGreen = Color(0xFF10B981);
  static const Color kRed = Color(0xFFEF4444);

  bool get _isAdmin => currentUser?.isSystemAdmin ?? false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // No back button
        title: Text(
          'Settings',
          style: GoogleFonts.sora(color: kDark, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User profile card
            if (currentUser != null) _buildProfileCard(context),
            if (currentUser != null) const SizedBox(height: 24),

            // Account section
            _buildSectionHeader('Account'),
            const SizedBox(height: 16),
            _buildSettingItem(
              icon: Icons.person_outline,
              title: 'Profile',
              subtitle: 'Manage your account',
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'Customize alerts',
              onTap: () {},
            ),
            _buildSettingItem(
              icon: Icons.history,
              title: 'Issue History',
              subtitle: 'View resolved issues',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const IssueHistoryScreen(),
                ),
              ),
              iconColor: kGreen,
            ),
            _buildSettingItem(
              icon: Icons.inventory_2_outlined,
              title: 'Lost & Found',
              subtitle: 'Report or view lost & found items',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LostAndFoundScreen(),
                ),
              ),
              iconColor: const Color(0xFFF59E0B),
            ),

            // Admin section (only for system admins)
            if (_isAdmin) ...[
              const SizedBox(height: 24),
              _buildSectionHeader('Administration'),
              const SizedBox(height: 16),
              _buildSettingItem(
                icon: Icons.people_outline,
                title: 'User Management',
                subtitle: 'Add, edit, or remove users',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserManagementScreen(),
                  ),
                ),
                iconColor: kAccent,
                showBadge: true,
              ),
              _buildSettingItem(
                icon: Icons.business_outlined,
                title: 'Departments',
                subtitle: 'View department structure',
                onTap: () {},
                iconColor: const Color(0xFF10B981),
              ),
              _buildSettingItem(
                icon: Icons.analytics_outlined,
                title: 'System Stats',
                subtitle: 'View usage statistics',
                onTap: () {},
                iconColor: const Color(0xFF8B5CF6),
              ),
              _buildSettingItem(
                icon: Icons.bug_report_outlined,
                title: 'Debug Logs',
                subtitle: 'View system logs and errors',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DebugLogsScreen(),
                  ),
                ),
                iconColor: const Color(0xFFF59E0B),
                showBadge: true,
              ),
            ],

            const SizedBox(height: 32),

            // Logout Button
            _buildLogoutButton(context),
            const SizedBox(height: 24),

            // App info
            Center(
              child: Text(
                'Novotel Westlands In-House App v 1.0.0',
                style: GoogleFonts.sora(
                  fontSize: 12,
                  color: kGrey.withOpacity(0.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final user = currentUser!;
    final roleColor = _getRoleColor(user.role);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kDark, kDark.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                user.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : '?',
                style: GoogleFonts.sora(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        user.role.displayName,
                        style: GoogleFonts.sora(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: roleColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      user.department,
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.sora(
        fontSize: 12,
        color: kGrey,
        fontWeight: FontWeight.w700,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
    bool showBadge = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? kDark).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor ?? kDark, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.sora(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: kDark,
                        ),
                      ),
                      if (showBadge) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: kAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ADMIN',
                            style: GoogleFonts.sora(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.sora(
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: kGrey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: kGrey.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () async {
          await AuthService().signOut();
          if (context.mounted) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.signIn,
              (route) => false,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFEF2F2),
          foregroundColor: kRed,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFFECACA), width: 1),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.logout_rounded, size: 24),
            const SizedBox(width: 12),
            Text(
              'Log Out',
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.systemAdmin:
        return const Color(0xFF8B5CF6);
      case UserRole.manager:
        return kAccent;
      case UserRole.staff:
        return const Color(0xFF10B981);
    }
  }
}
