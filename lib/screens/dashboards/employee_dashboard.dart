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
import '../../widgets/issue_action_sheets.dart';

/// Employee dashboard
/// Floor diagnostic system with bottom navigation
class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  // Design system colors
  static const Color kBg = Color(0xFFF8FAFC);
  static const Color kDark = Color(0xFF0F172A);
  static const Color kGreen = Color(0xFF10B981);
  static const Color kRed = Color(0xFFEF4444);
  
  // Priority-based colors
  static const Color kUrgent = Color(0xFFDC2626); // Deep red
  static const Color kHigh = Color(0xFFEA580C);   // Orange-red
  static const Color kMedium = Color(0xFFF59E0B); // Amber
  static const Color kLow = Color(0xFFFBBF24);    // Yellow

  /// Get color based on issue priority
  static Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent': return kUrgent;
      case 'high': return kHigh;
      case 'medium': return kMedium;
      case 'low': return kLow;
      default: return kRed;
    }
  }

  /// Get background color based on issue priority
  static Color _getPriorityBgColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent': return const Color(0xFFFEE2E2); // Light red
      case 'high': return const Color(0xFFFFF7ED);   // Light orange
      case 'medium': return const Color(0xFFFFFBEB); // Light amber
      case 'low': return const Color(0xFFFEFCE8);    // Light yellow
      default: return const Color(0xFFFEF2F2);
    }
  }

  /// Get border color based on issue priority
  static Color _getPriorityBorderColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent': return const Color(0xFFFECACA); // Red border
      case 'high': return const Color(0xFFFED7AA);   // Orange border
      case 'medium': return const Color(0xFFFDE68A); // Amber border
      case 'low': return const Color(0xFFFEF08A);    // Yellow border
      default: return const Color(0xFFFECACA);
    }
  }

  // Current bottom nav tab: 0 = Building, 1 = Home, 2 = Settings
  int _currentNavIndex = 1; // Start on Home

  // Selected floor in Building tab (null = show floor list)
  String? _selectedFloorId;

  // Get current user from auth service
  UserModel? get _currentUser => AuthService().currentUser;

  // Issue service for Firebase data
  final IssueService _issueService = IssueService();

  // Live issues from Firebase
  List<IssueModel> _issues = [];

  // ScrollController for floor view to auto-scroll to issues
  final ScrollController _floorViewScrollController = ScrollController();

  // GlobalKeys for room/area cards to scroll to them
  final Map<String, GlobalKey> _roomKeys = {};

  // Target room to scroll to after navigating to floor
  String? _scrollToRoom;

  @override
  void dispose() {
    _floorViewScrollController.dispose();
    super.dispose();
  }

  /// Navigate to floor and scroll to specific room/area
  void _navigateToFloorAndScrollTo(String floorId, String area) {
    setState(() {
      _currentNavIndex = 0; // Switch to Building tab
      _selectedFloorId = floorId;
      _scrollToRoom = area;
    });
    // Scroll after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToTargetRoom();
    });
  }

  /// Scroll to the target room/area
  void _scrollToTargetRoom() {
    if (_scrollToRoom == null) return;
    final key = _roomKeys[_scrollToRoom];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    }
    _scrollToRoom = null;
  }

  /// Open the report issue flow
  void _openReportIssueFlow() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportIssueFlow(
          preselectedFloor: _selectedFloorId,
        ),
      ),
    );
  }

  // All hotel floors (B3 to 11)
  // Floors 2-9: Guest rooms only (40 rooms each)
  // Floor 10: Kitchen, Executive Lounge, Pool Bar, Swimming Pool + Guest Rooms
  // Floor 11: TnT, Kitchen
  final List<FloorModel> _floors = const [
    FloorModel(id: '11', name: '11th Floor', areas: ['TnT', 'Kitchen', 'Corridor']),
    FloorModel(id: '10', name: '10th Floor', areas: ['Kitchen', 'Executive Lounge', 'Pool Bar', 'Swimming Pool', 'Corridor']),
    FloorModel(id: '9', name: '9th Floor', areas: ['Corridor']),
    FloorModel(id: '8', name: '8th Floor', areas: ['Corridor']),
    FloorModel(id: '7', name: '7th Floor', areas: ['Corridor']),
    FloorModel(id: '6', name: '6th Floor', areas: ['Corridor']),
    FloorModel(id: '5', name: '5th Floor', areas: ['Corridor']),
    FloorModel(id: '4', name: '4th Floor', areas: ['Corridor']),
    FloorModel(id: '3', name: '3rd Floor', areas: ['Corridor']),
    FloorModel(id: '2', name: '2nd Floor', areas: ['Corridor']),
    FloorModel(id: '1', name: '1st Floor', areas: ['Meeting Rooms', 'Washrooms', 'Spa', 'Gym', 'Corridor']),
    FloorModel(id: 'G', name: 'Ground Floor', areas: ["Gemma's", 'Main Kitchen', 'Social Hub', 'Front Office', 'Simba Ballroom', 'Corridor']),
    FloorModel(id: 'B1', name: 'Basement 1', areas: ['Back Office', 'Finance', 'Staff Cafeteria', 'Parking', 'Corridor']),
    FloorModel(id: 'B2', name: 'Basement 2', areas: ['Parking', 'Bakery', 'Control Room', 'Laundry', 'Corridor']),
    FloorModel(id: 'B3', name: 'Basement 3', areas: ['Engineering Workshop', 'Stores', 'Parking', 'Corridor']),
  ];

  /// Check if a floor has active issues (filtered by department visibility)
  bool _hasIssue(String floorId) {
    return _issues.any((i) => i.floor == floorId && i.isOngoing && _canViewIssue(i));
  }

  /// Get the currently selected floor object
  FloorModel? get _selectedFloor {
    if (_selectedFloorId == null) return null;
    return _floors.firstWhere((f) => f.id == _selectedFloorId);
  }

  /// Issues for currently selected floor (filtered by department visibility)
  List<IssueModel> get _currentFloorIssues {
    if (_selectedFloorId == null) return [];
    return _issues.where((i) => i.floor == _selectedFloorId && i.isOngoing && _canViewIssue(i)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        bottom: false, // Bottom nav handles its own safe area
        child: StreamBuilder<List<IssueModel>>(
          stream: _issueService.getAllOngoingIssues(),
          builder: (context, snapshot) {
            // Update local issues list when data changes
            if (snapshot.hasData) {
              _issues = snapshot.data!;
            }

            return _buildCurrentTabContent();
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  /// Build content based on current tab
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
        border: Border(
          top: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      // SafeArea here ensures the bar clears the home indicator / gesture bar
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

  Widget _buildNavItem({
    required String svgAsset,
    required int index,
  }) {
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
                isActive ? activeColor : const Color(0xFF94A3B8),
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
    // If a floor is selected, show floor detail view
    if (_selectedFloorId != null) {
      return _buildFloorView();
    }
    // Otherwise show the floor list
    return _buildFloorListView();
  }

  /// Get full floor name with ordinal (1st Floor, 2nd Floor, etc.)
  String _getFloorLabel(String floorId) {
    switch (floorId) {
      case 'G': return 'Ground Floor';
      case 'B1': return 'Basement 1';
      case 'B2': return 'Basement 2';
      case 'B3': return 'Basement 3';
      case '1': return '1st Floor';
      case '2': return '2nd Floor';
      case '3': return '3rd Floor';
      case '11': return '11th Floor';
      case '12': return '12th Floor';
      case '13': return '13th Floor';
      default:
        final num = int.tryParse(floorId);
        if (num != null) return '${num}th Floor';
        return 'Floor $floorId';
    }
  }

  /// Get issue count for a floor (filtered by department)
  int _getFloorIssueCount(String floorId) {
    return _issues.where((i) => 
      i.floor == floorId && 
      i.isOngoing && 
      _canViewIssue(i)
    ).length;
  }

  /// Check if current user can view this issue (department filtering)
  bool _canViewIssue(IssueModel issue) {
    if (_currentUser == null) return false;
    // System admins and managers can see all issues
    if (_currentUser!.isSystemAdmin || _currentUser!.role.name == 'manager') {
      return true;
    }
    // Staff can only see issues for their department
    return issue.department == _currentDepartment;
  }

  /// Building overview — structure matching screenshot
  Widget _buildFloorListView() {
    return CustomScrollView(
      slivers: [
        // ── Header ──────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Text(
              'BUILDING OVERVIEW',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 3,
                color: const Color(0xFF3B82F6),
              ),
            ),
          ),
        ),
        // ── Floor rows ──────────────────────────────
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

  /// One floor row: [Floor Number Box] | [Room/Area Cards]
  /// No separate title row — matches BuildingOverview screenshot.
  Widget _buildFloorRow(FloorModel floor) {
    final issueCount = _getFloorIssueCount(floor.id);
    final hasIssue = issueCount > 0;
    final hasRooms = _floorHasRooms(floor.id);
    final floorNum = int.tryParse(floor.id);

    // Build component widgets
    final List<Widget> components = [];

    if (hasRooms && floorNum != null) {
      // Floors 2-10: 40 guest room boxes
      for (int i = 0; i < 40; i++) {
        final roomNum = '$floorNum${(i + 1).toString().padLeft(2, '0')}';
        final roomHasIssue = _issues.any(
          (iss) => iss.area == 'Room $roomNum' && iss.floor == floor.id && iss.isOngoing && _canViewIssue(iss),
        );
        components.add(_buildClickableRoomCard(floor.id, roomNum, roomHasIssue));
      }
    } else {
      // All other floors: named area cards
      for (final area in floor.areas) {
        final areaHasIssue = _issues.any(
          (i) => i.area == area && i.floor == floor.id && i.isOngoing && _canViewIssue(i),
        );
        components.add(_buildClickableAreaCard(floor.id, area, areaHasIssue));
      }
    }

    return Container(
      // Extra vertical space between floors
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Floor number box ────────────────────
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
          // ── Room / area card grid ───────────────
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

  /// Clickable area card that navigates to floor view
  Widget _buildClickableAreaCard(String floorId, String area, bool hasIssue) {
    return GestureDetector(
      onTap: () => setState(() => _selectedFloorId = floorId),
      child: _areaCard(area, hasIssue),
    );
  }

  /// Clickable room card that navigates to floor view
  Widget _buildClickableRoomCard(String floorId, String roomNum, bool hasIssue) {
    return GestureDetector(
      onTap: () => setState(() => _selectedFloorId = floorId),
      child: _roomCard(roomNum, hasIssue),
    );
  }

  /// Floor grid item for Building tab
  Widget _buildFloorGridItem(FloorModel floor, bool hasIssue) {
    return GestureDetector(
      onTap: () => setState(() => _selectedFloorId = floor.id),
      child: Container(
        decoration: BoxDecoration(
          color: hasIssue ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
          border: Border.all(
            color: hasIssue ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Floor ID
            Text(
              floor.id,
              style: GoogleFonts.sora(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: hasIssue ? kRed : kGreen,
              ),
            ),
            const SizedBox(height: 3),
            // Status dot
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasIssue ? Icons.warning_rounded : Icons.check_circle,
                  size: 9,
                  color: hasIssue ? kRed : kGreen,
                ),
                const SizedBox(width: 2),
                Text(
                  hasIssue ? 'ISSUE' : 'OK',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: hasIssue ? kRed : kGreen,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Get current user's department from auth
  String get _currentDepartment => _currentUser?.department ?? 'Engineering';

  /// Get active issues for the current department (or all if admin/manager)
  List<IssueModel> get _departmentIssues {
    return _issues.where((i) => i.isOngoing && _canViewIssue(i)).toList();
  }

  /// Get active issues grouped by floor (filtered by department visibility)
  Map<String, List<IssueModel>> get _issuesByFloor {
    final activeIssues = _issues.where((i) => i.isOngoing && _canViewIssue(i)).toList();
    final Map<String, List<IssueModel>> grouped = {};
    for (final issue in activeIssues) {
      grouped.putIfAbsent(issue.floor, () => []).add(issue);
    }
    return grouped;
  }

  // ─── HOME VIEW ──────────────────────────────────────────────────

  Widget _buildHomeView() {
    final activeIssues = _issues.where((i) => i.isOngoing).toList();
    final floorsAffected = _issuesByFloor.keys.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Department wrapped card
          _buildDepartmentWrappedCard(),
          const SizedBox(height: 32),
          // Active issues by floor header
          Text(
            'ACTIVE ISSUES BY FLOOR',
            style: GoogleFonts.sora(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          // Issues grouped by floor
          _buildIssuesByFloorList(),
        ],
      ),
    );
  }

  /// Get issues count in the last N days for current department
  int _getIssueCountInLastDays(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _issues.where((i) => 
      i.department == _currentDepartment && 
      i.createdAt.isAfter(cutoff)
    ).length;
  }

  Widget _buildDepartmentWrappedCard() {
    final deptIssues = _departmentIssues;
    final issuesLast30Days = _getIssueCountInLastDays(30);
    final issuesLast1Year = _getIssueCountInLastDays(365);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main today's issues card
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Department Name
                Text(
                  '$_currentDepartment\nDepartment',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kDark,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                // Large issue count
                Center(
                  child: Text(
                    '${deptIssues.length}',
                    style: GoogleFonts.inter(
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                      color: kRed,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Active issues label
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: kRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Active Issues Today',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: kRed,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Right side: 30 days and 1 year stats
        SizedBox(
          width: 90,
          child: Column(
            children: [
              // Last 30 days
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(
                      '$issuesLast30Days',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: kDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '30 Days',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Last 1 year
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
                ),
                child: Column(
                  children: [
                    Text(
                      '$issuesLast1Year',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: kDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '1 Year',
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Active issues summary banner
  Widget _buildActiveIssuesSummary(int totalIssues, int floorsAffected, int urgentCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.warning_rounded, color: kRed, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$totalIssues Active Issues',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: kDark,
                  ),
                ),
                Text(
                  '$floorsAffected floors affected  •  $urgentCount urgent',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Small report button for header row
  Widget _buildSmallReportButton() {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.add, size: 16),
      label: const Text('REPORT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1)),
      style: ElevatedButton.styleFrom(
        backgroundColor: kRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    );
  }

  /// Issues grouped by floor list
  Widget _buildIssuesByFloorList() {
    final issuesByFloor = _issuesByFloor;
    if (issuesByFloor.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.check_circle_outline, size: 48, color: kGreen.withOpacity(0.5)),
              const SizedBox(height: 12),
              const Text(
                'No active issues',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

    // Sort floors: B3, B2, B1, G, 1, 2, ..., 11
    final sortedFloors = issuesByFloor.keys.toList()..sort((a, b) {
      int floorValue(String f) {
        if (f == 'G') return 0;
        if (f.startsWith('B')) return -int.parse(f.substring(1));
        return int.tryParse(f) ?? 0;
      }
      return floorValue(a).compareTo(floorValue(b));
    });

    return Column(
      children: sortedFloors.map((floorId) {
        final floorIssues = issuesByFloor[floorId]!;
        return _buildFloorIssueCard(floorId, floorIssues);
      }).toList(),
    );
  }

  /// Floor issue card showing floor with its issues
  Widget _buildFloorIssueCard(String floorId, List<IssueModel> issues) {
    final floor = _floors.firstWhere((f) => f.id == floorId, orElse: () => FloorModel(id: floorId, name: 'Floor $floorId', areas: []));
    final floorName = _getFloorDisplayName(floorId);

    return GestureDetector(
      onTap: () => setState(() {
        _currentNavIndex = 0; // Switch to Building tab
        _selectedFloorId = floorId;
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Floor header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: kDark,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      floorId,
                      style: TextStyle(
                        fontSize: floorId.length > 2 ? 11 : 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    floorName,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: kRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${issues.length}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: kRed,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Issue previews - each tappable to scroll to that issue
            ...issues.take(2).map((issue) {
              final priorityColor = _getPriorityColor(issue.priority);
              return GestureDetector(
                onTap: () => _navigateToFloorAndScrollTo(floorId, issue.area),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getPriorityBgColor(issue.priority),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _getPriorityBorderColor(issue.priority)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: priorityColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          issue.description,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: kDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        issue.area,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: priorityColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            // Tap to view floor hint
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View floor',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 10, color: const Color(0xFF94A3B8)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get display name for floor
  String _getFloorDisplayName(String floorId) {
    switch (floorId) {
      case 'G': return 'Ground Floor';
      case 'B1': return 'Basement 1';
      case 'B2': return 'Basement 2';
      case 'B3': return 'Basement 3';
      case '1': return '1st Floor';
      case '2': return '2nd Floor';
      case '3': return '3rd Floor';
      default:
        final num = int.tryParse(floorId);
        if (num != null) return '${num}th Floor';
        return 'Floor $floorId';
    }
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
          // Back button + Floor title + Report Button
          Row(
            children: [
              // Back button
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
              // Floor title
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
              // Report Issue Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _openReportIssueFlow(),
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
          // Area grid (or coming soon for numbered floors)
          _buildAreaGrid(floor),
          // Active issues for this floor
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

  /// Check if this floor has guest rooms (floors 2-10)
  bool _floorHasRooms(String floorId) {
    final num = int.tryParse(floorId);
    return num != null && num >= 2 && num <= 10;
  }

  /// Area grid for floors with named areas
  Widget _buildAreaGrid(FloorModel floor) {
    final hasRooms = _floorHasRooms(floor.id);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Named areas section
        if (floor.areas.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: floor.areas.map((area) {
              final hasIssue = _issues.any((i) => i.area == area && i.floor == floor.id && i.isOngoing);
              return _areaCard(area, hasIssue);
            }).toList(),
          ),
        ],
        // Room grid for floors 2-10
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

  /// Individual area card - compact size
  Widget _areaCard(String area, bool hasIssue) {
    // Register GlobalKey for this area
    _roomKeys.putIfAbsent(area, () => GlobalKey());
    
    return Container(
      key: _roomKeys[area],
      width: 120,
      height: 72,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: hasIssue ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
        border: Border.all(
          color: hasIssue ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                Icons.location_on,
                size: 12,
                color: hasIssue ? kRed.withOpacity(0.6) : kGreen.withOpacity(0.4),
              ),
              if (!hasIssue)
                Icon(Icons.check_circle, size: 10, color: kGreen.withOpacity(0.3)),
            ],
          ),
          // Label
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  area.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: hasIssue ? kRed : kGreen,
                    letterSpacing: -0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  hasIssue ? 'ISSUE' : 'OK',
                  style: TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                    color: hasIssue ? const Color(0xFFFCA5A5) : kGreen.withOpacity(0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Room grid for guest room floors (2-10)
  /// Each floor has 40 rooms: e.g., 7th floor = 701-740
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

  /// Individual room card - compact for mobile grid
  Widget _roomCard(String roomNum, bool hasIssue) {
    // Register GlobalKey for this room (area name is "Room XXX")
    final areaName = 'Room $roomNum';
    _roomKeys.putIfAbsent(areaName, () => GlobalKey());
    
    return Container(
      key: _roomKeys[areaName],
      width: 52,
      height: 44,
      decoration: BoxDecoration(
        color: hasIssue ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
        border: Border.all(
          color: hasIssue ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            roomNum,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: hasIssue ? kRed : kGreen,
            ),
          ),
          Icon(
            hasIssue ? Icons.warning_rounded : Icons.check_circle,
            size: 10,
            color: hasIssue ? kRed : kGreen.withOpacity(0.4),
          ),
        ],
      ),
    );
  }

  /// Breach alert card for floor issues
  Widget _buildBreachCard(IssueModel issue) {
    final priorityColor = _getPriorityColor(issue.priority);
    final bgColor = _getPriorityBgColor(issue.priority);
    final borderColor = _getPriorityBorderColor(issue.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority + time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: priorityColor, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  issue.priority.toUpperCase(),
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1, color: Colors.white),
                ),
              ),
              Text(issue.timeAgo, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 12),
          // Description
          Text(
            issue.description,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: kDark,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            issue.area,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: priorityColor),
          ),
          const SizedBox(height: 14),
          // Action
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('TAKE ACTION', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }
}
