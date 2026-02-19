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

  /// Check if a floor has active issues
  bool _hasIssue(String floorId) {
    return _issues.any((i) => i.floor == floorId && i.isOngoing);
  }

  /// Get the currently selected floor object
  FloorModel? get _selectedFloor {
    if (_selectedFloorId == null) return null;
    return _floors.firstWhere((f) => f.id == _selectedFloorId);
  }

  /// Issues for currently selected floor
  List<IssueModel> get _currentFloorIssues {
    if (_selectedFloorId == null) return [];
    return _issues.where((i) => i.floor == _selectedFloorId && i.isOngoing).toList();
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

  /// Building overview — each floor is a horizontal row:
  /// [floor label box] | [all components wrapped beside it]
  Widget _buildFloorListView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
          child: Text(
            'BUILDING OVERVIEW',
            style: GoogleFonts.sora(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 3,
              color: const Color(0xFF94A3B8),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            itemCount: _floors.length,
            itemBuilder: (context, index) {
              return _buildFloorRow(_floors[index]);
            },
          ),
        ),
      ],
    );
  }

  /// One row per floor: label box on left, all components on right
  Widget _buildFloorRow(FloorModel floor) {
    final hasIssue = _hasIssue(floor.id);
    final hasRooms = _floorHasRooms(floor.id);
    final floorNum = int.tryParse(floor.id);

    // Build the list of component widgets for this floor
    final List<Widget> components = [];

    if (hasRooms && floorNum != null) {
      // Floors 2-10: show all 40 guest room boxes
      for (int i = 0; i < 40; i++) {
        final roomNum = '$floorNum${(i + 1).toString().padLeft(2, '0')}';
        final roomHasIssue = _issues.any(
          (iss) => iss.area == 'Room $roomNum' && iss.floor == floor.id && iss.isOngoing,
        );
        components.add(_roomCard(roomNum, roomHasIssue));
      }
    } else {
      // All other floors: show named area cards
      for (final area in floor.areas) {
        final areaHasIssue =
            _issues.any((i) => i.area == area && i.floor == floor.id && i.isOngoing);
        components.add(_areaCard(area, areaHasIssue));
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Floor label box ──────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _selectedFloorId = floor.id),
            child: Container(
              width: 38,
              constraints: const BoxConstraints(minHeight: 44),
              decoration: BoxDecoration(
                color: hasIssue ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                border: Border.all(
                  color: hasIssue ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  floor.id,
                  style: TextStyle(
                    fontSize: floor.id.length > 2 ? 8 : 11,
                    fontWeight: FontWeight.w800,
                    color: hasIssue ? kRed : kGreen,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // ── Components (rooms or areas) ───────────────────────────
          Expanded(
            child: Wrap(
              spacing: 5,
              runSpacing: 5,
              children: components,
            ),
          ),
        ],
      ),
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

  /// Get active issues for the current department
  List<IssueModel> get _departmentIssues {
    return _issues.where((i) => i.department == _currentDepartment && i.isOngoing).toList();
  }

  /// Get active issues grouped by floor
  Map<String, List<IssueModel>> get _issuesByFloor {
    final activeIssues = _issues.where((i) => i.isOngoing).toList();
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

  Widget _buildDepartmentWrappedCard() {
    final deptIssues = _departmentIssues;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Department Name
          Text(
            '$_currentDepartment\nDepartment',
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
              '${deptIssues.length}',
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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white, // Changed from 0xFFFEF2F2 to white
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Floor header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: kRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      floorId,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    floorName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: kDark,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.warning_rounded, size: 14, color: kRed),
                      const SizedBox(width: 6),
                      Text(
                        '${issues.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: kRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Issue previews - each tappable to scroll to that issue
            ...issues.take(2).map((issue) => GestureDetector(
              onTap: () => _navigateToFloorAndScrollTo(floorId, issue.area),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: kRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        issue.description,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: kDark,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      issue.area,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 8),
            // Tap to view floor - no line separator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'TAP TO VIEW FLOOR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: kRed.withOpacity(0.7),
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.arrow_forward, size: 16, color: kRed.withOpacity(0.7)),
              ],
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
          // Priority + time
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
          // Description
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
