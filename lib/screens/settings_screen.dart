import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/routes.dart';
import '../config/departments.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'admin/user_management_screen.dart';
import 'admin/debug_logs_screen.dart';
import 'admin/system_metrics_screen.dart';
import 'lost_and_found_screen.dart';
import 'about_screen.dart';

/// Settings screen with role-based options
/// IT/System Admins see: User Management, Debug Logs, System Metrics
/// Managers see: User Management only
class SettingsScreen extends StatefulWidget {
  final UserModel? currentUser;

  const SettingsScreen({super.key, this.currentUser});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Design colors - Premium monochrome palette
  static const Color kDark = Color(0xFF0F172A);
  static const Color kGrey = Color(0xFF64748B);
  static const Color kLightGrey = Color(0xFF94A3B8);
  static const Color kRed = Color(0xFFEF4444);

  // Notification sound toggle state
  bool _notificationSoundEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadNotificationPreference();
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationSoundEnabled = prefs.getBool('notification_sound') ?? false;
    });
  }

  Future<void> _toggleNotificationSound(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_sound', value);
    setState(() {
      _notificationSoundEnabled = value;
    });
  }

  UserModel? get currentUser => widget.currentUser;

  /// IT department users get full admin access (debug logs, system metrics)
  bool get _isITAdmin => currentUser?.isIT ?? false;

  /// Managers can manage users but not see debug logs or system metrics
  bool get _isManager => currentUser?.isManager ?? false;

  /// System admins have full access
  bool get _isSystemAdmin => currentUser?.isSystemAdmin ?? false;

  /// Can access user management (IT, System Admin, or General Manager only)
  /// General Manager is identified as role=manager AND department="Front Office" (GM's department)
  bool get _isGeneralManager => _isManager && currentUser?.department == 'Front Office';
  
  /// Can access user management (IT or System Admin only, plus General Manager)
  bool get _canManageUsers => _isITAdmin || _isSystemAdmin || _isGeneralManager;

  /// Can access debug logs and system metrics (IT or System Admin only)
  bool get _canAccessSystemTools => _isITAdmin || _isSystemAdmin;

  /// Get department-specific image path
  String _getDepartmentImage(String department) {
    switch (department) {
      case 'IT':
        return 'assets/it.jpeg';
      case 'Front Office':
        return 'assets/front_office.jpeg';
      case 'Housekeeping':
        return 'assets/house_keeping.jpeg';
      case 'Engineering':
        return 'assets/engeneering.jpeg';
      default:
        // Fallback to IT image for other departments (Security, F&B, etc.)
        return 'assets/it.jpeg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
          style: GoogleFonts.inter(color: kDark, fontWeight: FontWeight.w700, fontSize: 20),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Modern profile header
            if (currentUser != null) _buildModernProfileHeader(),
            const SizedBox(height: 32),

            // Notifications section
            _buildSectionHeader('Notifications'),
            const SizedBox(height: 12),
            _buildNotificationSettings(),
            const SizedBox(height: 24),

            // General section
            _buildSectionHeader('General'),
            const SizedBox(height: 12),
            _buildSettingItem(
              icon: Icons.inventory_2_outlined,
              title: 'Lost & Found',
              subtitle: 'Report or view lost items',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LostAndFoundScreen(),
                ),
              ),
            ),

            // Administration section (role-based)
            if (_canManageUsers) ...[
              const SizedBox(height: 24),
              _buildSectionHeader('Administration'),
              const SizedBox(height: 12),
              // User Management - available to IT, System Admin, and Managers
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
              ),
              // Debug Logs - IT and System Admin only
              if (_canAccessSystemTools)
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
                ),
              // System Metrics - IT and System Admin only
              if (_canAccessSystemTools)
                _buildSettingItem(
                  icon: Icons.analytics_outlined,
                  title: 'System Metrics',
                  subtitle: 'View usage and cost tracking',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SystemMetricsScreen(),
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 24),

            // About section - link to About screen
            _buildSectionHeader('About'),
            const SizedBox(height: 12),
            _buildSettingItem(
              icon: Icons.info_outline,
              title: 'About This App',
              subtitle: 'Version info and developer credits',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AboutScreen(),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Logout Button
            _buildLogoutButton(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  /// Modern premium profile header - clean monochrome design
  Widget _buildModernProfileHeader() {
    final user = currentUser!;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Avatar with department-specific image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                _getDepartmentImage(user.department),
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            user.displayName,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: kDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          // Department and Role in a clean row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user.department,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kGrey,
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: kLightGrey,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                user.role.displayName,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Notification settings with sound toggle
  Widget _buildNotificationSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: kDark.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.volume_up_outlined, color: kDark, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notification Sound',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: kDark,
                  ),
                ),
                Text(
                  _notificationSoundEnabled ? 'Sound enabled' : 'Sound disabled',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: kGrey,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: _notificationSoundEnabled,
            onChanged: _toggleNotificationSound,
            activeColor: kDark,
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

  /// Clean monochrome setting item
  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: kDark.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: kDark, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: kDark,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                      color: kGrey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: kLightGrey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        await AuthService().signOut();
        if (context.mounted) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRoutes.signIn,
            (route) => false,
          );
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: kRed.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, size: 20, color: kRed),
            const SizedBox(width: 10),
            Text(
              'Log Out',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: kRed,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
