/*
  Admin/System Admin Dashboard
  - Bottom navigation with 3 tabs: Building, Home, Settings
  - Full visibility across all departments
  - Can manage users
  - Can see debug logs
*/

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../settings_screen.dart';
import '../report_issue/report_issue_flow.dart';
import '../../models/floor_model.dart';
import '../../models/issue_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/issue_service.dart';
import '../../config/departments.dart';
import '../admin/user_management_screen.dart';
import '../../widgets/issue_action_sheets.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Design colors
  static const Color kBg = Color(0xFFF8FAFC);
  static const Color kDark = Color(0xFF0F172A);
  static const Color kGrey = Color(0xFF64748B);
  static const Color kGreen = Color(0xFF10B981);
  static const Color kRed = Color(0xFFEF4444);
  static const Color kAccent = Color(0xFF3B82F6);
  static const Color kPurple = Color(0xFF8B5CF6);

  // Current bottom nav tab: 0 = Building, 1 = Home, 2 = Settings
  int _currentNavIndex = 1; // Start on Home

  // Selected floor in Building tab
  String? _selectedFloorId;

  // Get current user from auth service
  UserModel? get _currentUser => AuthService().currentUser;

  // Issue service for Firebase data
  final IssueService _issueService = IssueService();

  // Live issues from Firebase
  List<IssueModel> _issues = [];

  // All hotel floors
  final List<FloorModel> _floors = const [
    FloorModel(id: '11', name: '11th Floor', areas: ['TnT', 'Kitchen', 'General']),
    FloorModel(id: '10', name: '10th Floor', areas: ['Kitchen', 'Executive Lounge', 'Pool Bar', 'Swimming Pool', 'General']),
    FloorModel(id: '9', name: '9th Floor', areas: ['General']),
    FloorModel(id: '8', name: '8th Floor', areas: ['General']),
    FloorModel(id: '7', name: '7th Floor', areas: ['General']),
    FloorModel(id: '6', name: '6th Floor', areas: ['General']),
    FloorModel(id: '5', name: '5th Floor', areas: ['General']),
    FloorModel(id: '4', name: '4th Floor', areas: ['General']),
    FloorModel(id: '3', name: '3rd Floor', areas: ['General']),
    FloorModel(id: '2', name: '2nd Floor', areas: ['General']),
    FloorModel(id: '1', name: '1st Floor', areas: ['Meeting Rooms', 'Washrooms', 'Spa', 'Gym', 'General']),
    FloorModel(id: 'G', name: 'Ground Floor', areas: ["Gemma's", 'Main Kitchen', 'Social Hub', 'Front Office', 'Simba Ballroom', 'General']),
    FloorModel(id: 'B1', name: 'Basement 1', areas: ['Back Office', 'Finance', 'Staff Cafeteria', 'Parking', 'General']),
    FloorModel(id: 'B2', name: 'Basement 2', areas: ['Parking', 'Bakery', 'Control Room', 'Laundry', 'General']),
    FloorModel(id: 'B3', name: 'Basement 3', areas: ['Engineering Workshop', 'Stores', 'Parking', 'General']),
  ];

  bool _hasIssue(String floorId) {
    return _issues.any((i) => i.floor == floorId && i.isOngoing);
  }

  FloorModel? get _selectedFloor {
    if (_selectedFloorId == null) return null;
    return _floors.firstWhere((f) => f.id == _selectedFloorId);
  }

  List<IssueModel> get _currentFloorIssues {
    if (_selectedFloorId == null) return [];
    return _issues.where((i) => i.floor == _selectedFloorId && i.isOngoing).toList();
  }

  // Admin sees ALL issues
  List<IssueModel> get _allActiveIssues {
    return _issues.where((i) => i.isOngoing).toList();
  }

  int _getDepartmentIssueCount(String department) {
    return _issues.where((i) => i.department == department && i.isOngoing).length;
  }

  int _getFloorIssueCount(String floorId) {
    return _issues.where((i) => i.floor == floorId && i.isOngoing).length;
  }

  /// Handle back button press
  bool _handleBackPress() {
    if (_selectedFloorId != null) {
      setState(() => _selectedFloorId = null);
      return true;
    }
    if (_currentNavIndex != 1) {
      setState(() => _currentNavIndex = 1);
      return true;
    }
    return false;
  }

  void _openReportIssueFlow() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportIssueFlow(preselectedFloor: _selectedFloorId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPress();
      },
      child: Scaffold(
        backgroundColor: kBg,
        body: SafeArea(
          bottom: false,
          child: StreamBuilder<List<IssueModel>>(
            stream: _issueService.getAllOngoingIssues(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                _issues = snapshot.data!;
              }
              return _buildCurrentTabContent();
            },
          ),
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    switch (_currentNavIndex) {
      case 0:
        return _buildBuildingTab();
      case 1:
        return _buildHomeView();
      case 2:
        return SettingsScreen(currentUser: _currentUser);
      default:
        return _buildHomeView();
    }
  }

  // ─── BOTTOM NAVIGATION BAR ────────────────────────────────────────

  Widget _buildBottomNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(svgAsset: 'assets/building.svg', index: 0),
              _buildNavItem(svgAsset: 'assets/home.svg', index: 1),
              _buildNavItem(svgAsset: 'assets/user.svg', index: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required String svgAsset, required int index}) {
    final isActive = _currentNavIndex == index;
    const activeColor = Color(0xFF3B82F6);
    return GestureDetector(
      onTap: () => setState(() {
        _currentNavIndex = index;
        if (index != 0) _selectedFloorId = null;
      }),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        height: 56,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SvgPicture.asset(
              svgAsset,
              width: 22,
              height: 22,
              colorFilter: ColorFilter.mode(
                isActive ? activeColor : const Color(0xFF475569),
                BlendMode.srcIn,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── BUILDING TAB ────────────────────────────────────────────────

  Widget _buildBuildingTab() {
    if (_selectedFloorId != null) {
      return _buildFloorView();
    }
    return _buildFloorListView();
  }

  Widget _buildFloorListView() {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Text(
              'BUILDING OVERVIEW',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: kAccent,
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildFloorRow(_floors[index]),
              childCount: _floors.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloorRow(FloorModel floor) {
    final issueCount = _getFloorIssueCount(floor.id);
    final hasIssue = issueCount > 0;
    final hasRooms = _floorHasRooms(floor.id);
    final floorNum = int.tryParse(floor.id);

    final List<Widget> components = [];

    if (hasRooms && floorNum != null) {
      for (int i = 0; i < 40; i++) {
        final roomNum = '$floorNum${(i + 1).toString().padLeft(2, '0')}';
        final roomHasIssue = _issues.any(
          (iss) => iss.area == 'Room $roomNum' && iss.floor == floor.id && iss.isOngoing,
        );
        components.add(_buildClickableRoomCard(floor.id, roomNum, roomHasIssue));
      }
    } else {
      for (final area in floor.areas) {
        final areaHasIssue = _issues.any(
          (i) => i.area == area && i.floor == floor.id && i.isOngoing,
        );
        components.add(_buildClickableAreaCard(floor.id, area, areaHasIssue));
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _selectedFloorId = floor.id),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hasIssue ? const Color(0xFFFEF2F2) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasIssue ? kRed : const Color(0xFFCBD5E1),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  floor.id,
                  style: GoogleFonts.inter(
                    fontSize: floor.id.length > 2 ? 12 : 16,
                    fontWeight: FontWeight.w700,
                    color: hasIssue ? kRed : kDark,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: components,
            ),
          ),
        ],
      ),
    );
  }

  bool _floorHasRooms(String floorId) {
    final num = int.tryParse(floorId);
    return num != null && num >= 2 && num <= 10;
  }

  Widget _buildClickableAreaCard(String floorId, String area, bool hasIssue) {
    return GestureDetector(
      onTap: () => setState(() => _selectedFloorId = floorId),
      child: _areaCard(area, hasIssue),
    );
  }

  Widget _buildClickableRoomCard(String floorId, String roomNum, bool hasIssue) {
    return GestureDetector(
      onTap: () => setState(() => _selectedFloorId = floorId),
      child: _roomCard(roomNum, hasIssue),
    );
  }

  Widget _areaCard(String area, bool hasIssue) {
    return Container(
      width: 100,
      height: 56,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: hasIssue ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
        border: Border.all(
          color: hasIssue ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            Icons.location_on,
            size: 10,
            color: hasIssue ? kRed.withOpacity(0.6) : kGreen.withOpacity(0.4),
          ),
          Text(
            area.toUpperCase(),
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: hasIssue ? kRed : kGreen,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _roomCard(String roomNum, bool hasIssue) {
    return Container(
      width: 48,
      height: 40,
      decoration: BoxDecoration(
        color: hasIssue ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
        border: Border.all(
          color: hasIssue ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            roomNum,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: hasIssue ? kRed : kGreen,
            ),
          ),
          Icon(
            hasIssue ? Icons.warning_rounded : Icons.check_circle,
            size: 8,
            color: hasIssue ? kRed : kGreen.withOpacity(0.4),
          ),
        ],
      ),
    );
  }

  // ─── HOME VIEW ────────────────────────────────────────────────────

  Widget _buildHomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAdminHeader(),
          const SizedBox(height: 24),
          // User Management Button
          _buildUserManagementButton(),
          const SizedBox(height: 16),
          // Report Issue Button
          _buildReportIssueButton(),
          const SizedBox(height: 32),
          // Department cards
          Text(
            'DEPARTMENTS',
            style: GoogleFonts.sora(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          _buildDepartmentCards(),
        ],
      ),
    );
  }

  Widget _buildAdminHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kDark, kDark.withOpacity(0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: kPurple.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.admin_panel_settings, color: kPurple, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentUser?.displayName ?? 'System Admin',
                      style: GoogleFonts.sora(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'System Administrator • ${_currentUser?.department ?? "IT"}',
                      style: GoogleFonts.sora(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'You have full visibility across all departments.',
            style: GoogleFonts.sora(
              fontSize: 13,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserManagementButton() {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const UserManagementScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kPurple,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.people, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Management',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Add, edit, or manage users',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.5), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildReportIssueButton() {
    return GestureDetector(
      onTap: _openReportIssueFlow,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Report an Issue',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to report a new issue',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.5), size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentCards() {
    return Column(
      children: Departments.all.map((dept) => _buildDepartmentCard(dept)).toList(),
    );
  }

  Widget _buildDepartmentCard(String department) {
    final issueCount = _getDepartmentIssueCount(department);
    final hasIssues = issueCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: hasIssues ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasIssues ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: hasIssues ? kRed.withOpacity(0.1) : kGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '$issueCount',
                style: GoogleFonts.sora(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: hasIssues ? kRed : kGreen,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  department,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kDark,
                  ),
                ),
                Text(
                  hasIssues ? '$issueCount active issue${issueCount == 1 ? '' : 's'}' : 'All clear',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: hasIssues ? kRed : kGreen,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            hasIssues ? Icons.warning_rounded : Icons.check_circle,
            color: hasIssues ? kRed : kGreen,
            size: 24,
          ),
        ],
      ),
    );
  }

  // ─── FLOOR VIEW ────────────────────────────────────────────────────

  Widget _buildFloorView() {
    final floor = _selectedFloor!;
    final floorIssues = _currentFloorIssues;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedFloorId = null),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, size: 18, color: kDark),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  floor.name,
                  style: GoogleFonts.sora(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: kDark,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _openReportIssueFlow,
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
          const SizedBox(height: 24),
          _buildAreaGrid(floor),
          if (floorIssues.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'ISSUES ON THIS FLOOR',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 12),
            ...floorIssues.map((issue) => _buildBreachCard(issue)),
          ],
        ],
      ),
    );
  }

  Widget _buildAreaGrid(FloorModel floor) {
    final hasRooms = _floorHasRooms(floor.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (floor.areas.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: floor.areas.map((area) {
              final hasIssue = _issues.any((i) => i.area == area && i.floor == floor.id && i.isOngoing);
              return _areaCard(area, hasIssue);
            }).toList(),
          ),
        if (hasRooms) ...[
          const SizedBox(height: 20),
          const Text(
            'GUEST ROOMS',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),
          _buildRoomGrid(floor),
        ],
      ],
    );
  }

  Widget _buildRoomGrid(FloorModel floor) {
    final floorNum = int.tryParse(floor.id);
    if (floorNum == null) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: List.generate(40, (i) {
        final roomNum = '$floorNum${(i + 1).toString().padLeft(2, '0')}';
        final hasIssue = _issues.any((iss) => iss.area == 'Room $roomNum' && iss.floor == floor.id && iss.isOngoing);
        return _roomCard(roomNum, hasIssue);
      }),
    );
  }

  Widget _buildBreachCard(IssueModel issue) {
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(12)),
                    child: Text(
                      issue.priority.toUpperCase(),
                      style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 2, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getDeptColor(issue.department).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      issue.department,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: _getDeptColor(issue.department)),
                    ),
                  ),
                ],
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
            issue.area.toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 2, color: kRed),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_currentUser != null) {
                  showTakeActionSheet(
                    context: context,
                    issue: issue,
                    currentUser: _currentUser!,
                  );
                }
              },
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

  Color _getDeptColor(String dept) {
    switch (dept) {
      case 'Engineering': return kAccent;
      case 'IT': return kPurple;
      case 'Housekeeping': return kGreen;
      case 'Front Office': return const Color(0xFFF59E0B);
      case 'Security': return kRed;
      case 'F&B': return const Color(0xFFEC4899);
      default: return kDark;
    }
  }
}
