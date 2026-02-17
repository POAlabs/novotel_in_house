import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../settings_screen.dart';
import '../../models/floor_model.dart';
import '../../models/issue_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/issue_service.dart';
import '../../config/departments.dart';

/// Manager dashboard
/// Shows 3 department cards - tap to view department issues
class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  // Design system colors
  static const Color kBg = Color(0xFFF8FAFC);
  static const Color kDark = Color(0xFF0F172A);
  static const Color kGrey = Color(0xFF64748B);
  static const Color kGreen = Color(0xFF10B981);
  static const Color kRed = Color(0xFFEF4444);
  static const Color kAccent = Color(0xFF3B82F6);
  static const Color kPurple = Color(0xFF8B5CF6);

  // Current view: null = home, 'department:X' = department view
  String? _selectedView;

  // Get current user from auth service
  UserModel? get _currentUser => AuthService().currentUser;

  // Issue service for Firebase data
  final IssueService _issueService = IssueService();

  // Live issues from Firebase
  List<IssueModel> _issues = [];

  bool get _isViewingDepartment => _selectedView != null && _selectedView!.startsWith('department:');
  String? get _selectedDepartment => _isViewingDepartment ? _selectedView!.split(':')[1] : null;

  List<IssueModel> get _currentDepartmentIssues {
    if (!_isViewingDepartment) return [];
    return _issues.where((i) => i.department == _selectedDepartment && i.isOngoing).toList();
  }

  int _getDepartmentIssueCount(String department) {
    return _issues.where((i) => i.department == department && i.isOngoing).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: StreamBuilder<List<IssueModel>>(
          stream: _issueService.getAllOngoingIssues(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              _issues = snapshot.data!;
            }
            
            return Row(
              children: [
                _buildSidebar(),
                Expanded(
                  child: _selectedView == null
                      ? _buildHomeView()
                      : _buildDepartmentView(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 80,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Manager badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.manage_accounts, size: 20, color: kAccent),
          ),
          const SizedBox(height: 16),
          // Home button
          _sidebarIcon(
            Icons.home,
            isActive: _selectedView == null,
            onTap: () => setState(() => _selectedView = null),
          ),
          const Spacer(),
          // Settings
          _sidebarIcon(
            Icons.settings_outlined,
            isActive: false,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => SettingsScreen(currentUser: _currentUser),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sidebarIcon(IconData icon, {required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? kDark : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: isActive ? Colors.white : const Color(0xFFCBD5E1)),
      ),
    );
  }

  Widget _buildHomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Welcome, ${_currentUser?.displayName ?? "Manager"}',
            style: GoogleFonts.sora(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: kDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap a department to view issues',
            style: GoogleFonts.sora(
              fontSize: 14,
              color: kGrey,
            ),
          ),
          const SizedBox(height: 24),
          // Department cards
          _buildDepartmentCards(),
        ],
      ),
    );
  }

  Widget _buildDepartmentCards() {
    final mainDepartments = ['Engineering', 'IT', 'Housekeeping'];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: mainDepartments.map((dept) => _buildLargeDepartmentCard(dept)).toList(),
    );
  }

  Widget _buildLargeDepartmentCard(String department) {
    final issueCount = _getDepartmentIssueCount(department);

    return GestureDetector(
      onTap: () => setState(() => _selectedView = 'department:$department'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Department name
            Text(
              '$department\nDepartment',
              style: GoogleFonts.sora(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: kDark,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 24),
            // Large issue count
            Center(
              child: Text(
                '$issueCount',
                style: GoogleFonts.sora(
                  fontSize: 80,
                  fontWeight: FontWeight.w800,
                  color: kRed,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Active issues label
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: kRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'Active Issues Raised Today',
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kRed,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentView() {
    final department = _selectedDepartment!;
    final deptIssues = _currentDepartmentIssues;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Department header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$department Department',
                style: GoogleFonts.sora(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: kDark,
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {},
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: Colors.black, size: 24),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${deptIssues.length} Active Issue${deptIssues.length == 1 ? "" : "s"}',
            style: GoogleFonts.sora(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kGrey,
            ),
          ),
          const SizedBox(height: 24),
          // Issues list
          if (deptIssues.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  children: [
                    Text(
                      '0',
                      style: GoogleFonts.sora(
                        fontSize: 64,
                        fontWeight: FontWeight.w800,
                        color: kGreen,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No active issues',
                      style: GoogleFonts.sora(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: kGrey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'All clear in $department',
                      style: GoogleFonts.sora(
                        fontSize: 13,
                        color: kGrey.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...deptIssues.map((issue) => _buildIssueCard(issue)),
        ],
      ),
    );
  }

  Widget _buildIssueCard(IssueModel issue) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        border: Border.all(color: const Color(0xFFFECACA), width: 2),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  issue.priority.toUpperCase(),
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 2, color: Colors.white),
                ),
              ),
              Text(issue.timeAgo, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            issue.description.toUpperCase(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: kDark, height: 1.2),
          ),
          const SizedBox(height: 4),
          Text(
            '${issue.floor} - ${issue.area}'.toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2, color: kRed),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: kDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('TAKE ACTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2)),
            ),
          ),
        ],
      ),
    );
  }
}
