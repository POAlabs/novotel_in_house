import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../settings_screen.dart';
import '../../models/issue_model.dart';
import '../../models/floor_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/issue_service.dart';
import '../../widgets/issue_action_sheets.dart';

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
      case 'urgent': return const Color(0xFFFEE2E2);
      case 'high': return const Color(0xFFFFF7ED);
      case 'medium': return const Color(0xFFFFFBEB);
      case 'low': return const Color(0xFFFEFCE8);
      default: return const Color(0xFFFEF2F2);
    }
  }

  /// Get border color based on issue priority
  static Color _getPriorityBorderColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent': return const Color(0xFFFECACA);
      case 'high': return const Color(0xFFFED7AA);
      case 'medium': return const Color(0xFFFDE68A);
      case 'low': return const Color(0xFFFEF08A);
      default: return const Color(0xFFFECACA);
    }
  }

  // Current bottom nav tab: 0 = Building, 1 = Home, 2 = Settings
  int _currentNavIndex = 1; // Start on Home

  // Selected floor in Building tab (null = show floor list)
  String? _selectedFloorId;

  // Current view for department drill-down: null = home, 'department:X' = department view
  String? _selectedView;

  // Check if viewing a specific floor
  bool get _isViewingFloor => _selectedFloorId != null;

  FloorModel? get _selectedFloor {
    if (!_isViewingFloor) return null;
    return _floors.firstWhere((f) => f.id == _selectedFloorId, orElse: () => _floors.first);
  }

  List<IssueModel> get _currentFloorIssues {
    if (!_isViewingFloor) return [];
    return _issues.where((i) => i.floor == _selectedFloorId && i.isOngoing).toList();
  }

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

  /// Handle back button press - returns true if handled internally
  bool _handleBackPress() {
    // If viewing a floor detail, go back to floor list
    if (_selectedFloorId != null) {
      setState(() => _selectedFloorId = null);
      return true;
    }
    // If viewing a department, go back to home
    if (_selectedView != null) {
      setState(() => _selectedView = null);
      return true;
    }
    // If on Building or Settings tab, go to Home tab
    if (_currentNavIndex != 1) {
      setState(() => _currentNavIndex = 1);
      return true;
    }
    // On Home tab - don't handle
    return false;
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

  /// Build content based on current tab
  Widget _buildCurrentTabContent() {
    switch (_currentNavIndex) {
      case 0:
        return _isViewingFloor ? _buildFloorView() : _buildBuildingTab();
      case 1:
        return _isViewingDepartment ? _buildDepartmentView() : _buildHomeView();
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
        if (index != 1) _selectedView = null;
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
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      itemCount: _floors.length + 1, // +1 for header
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Text(
              'BUILDING OVERVIEW',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 2,
                color: kGrey,
              ),
            ),
          );
        }
        return _buildFloorRow(_floors[index - 1]);
      },
    );
  }

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

  int _getFloorIssueCount(String floorId) {
    return _issues.where((i) => i.floor == floorId && i.isOngoing).length;
  }

  bool _floorHasRooms(String floorId) {
    final num = int.tryParse(floorId);
    return num != null && num >= 2 && num <= 10;
  }

  Widget _buildFloorRow(FloorModel floor) {
    final hasIssue = _getFloorIssueCount(floor.id) > 0;
    final hasRooms = _floorHasRooms(floor.id);
    final floorNum = int.tryParse(floor.id);

    final List<Widget> components = [];

    if (hasRooms && floorNum != null) {
      for (int i = 0; i < 40; i++) {
        final roomNum = '$floorNum${(i + 1).toString().padLeft(2, '0')}';
        final roomHasIssue = _issues.any(
          (iss) => iss.area == 'Room $roomNum' && iss.floor == floor.id && iss.isOngoing,
        );
        components.add(_roomCard(roomNum, roomHasIssue, floor.id));
      }
    } else {
      for (final area in floor.areas) {
        final areaHasIssue = _issues.any(
          (i) => i.area == area && i.floor == floor.id && i.isOngoing,
        );
        components.add(_areaCard(area, areaHasIssue, floor.id));
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Floor number box on left - tappable to go to floor view
          GestureDetector(
            onTap: () => setState(() => _selectedFloorId = floor.id),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: hasIssue ? const Color(0xFFFEF2F2) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: hasIssue ? kRed : const Color(0xFFE2E8F0),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  floor.id,
                  style: GoogleFonts.inter(
                    fontSize: floor.id.length > 2 ? 12 : 18,
                    fontWeight: FontWeight.w700,
                    color: hasIssue ? kRed : kDark,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Room/area cards grid on right
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

  Widget _roomCard(String roomNum, bool hasIssue, String floorId) {
    return GestureDetector(
      onTap: () => setState(() => _selectedFloorId = floorId),
      child: Container(
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
      ),
    );
  }

  Widget _areaCard(String area, bool hasIssue, String floorId) {
    return GestureDetector(
      onTap: () => setState(() => _selectedFloorId = floorId),
      child: Container(
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
            Column(
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
          ],
        ),
      ),
    );
  }

  // ─── FLOOR VIEW ─────────────────────────────────────────────────────

  Widget _buildFloorView() {
    final floor = _selectedFloor!;
    final floorIssues = _currentFloorIssues;

    return Column(
      children: [
        // Back header
        Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedFloorId = null),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back, size: 18, color: kDark),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _getFloorLabel(floor.id),
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kDark,
                ),
              ),
            ],
          ),
        ),
        // Floor content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Area grid
                _buildFloorAreaGrid(floor),
                if (floorIssues.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'ISSUES ON THIS FLOOR',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...floorIssues.map((issue) => _buildFloorIssueCard(issue)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloorAreaGrid(FloorModel floor) {
    final hasRooms = _floorHasRooms(floor.id);
    final floorNum = int.tryParse(floor.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Areas
        if (floor.areas.isNotEmpty) ...[
          Text(
            'AREAS',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: floor.areas.map((area) {
              final hasIssue = _issues.any(
                (i) => i.area == area && i.floor == floor.id && i.isOngoing,
              );
              return _floorViewAreaCard(area, hasIssue);
            }).toList(),
          ),
        ],
        // Rooms
        if (hasRooms && floorNum != null) ...[
          const SizedBox(height: 24),
          Text(
            'GUEST ROOMS',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: List.generate(40, (i) {
              final roomNum = '$floorNum${(i + 1).toString().padLeft(2, '0')}';
              final hasIssue = _issues.any(
                (iss) => iss.area == 'Room $roomNum' && iss.floor == floor.id && iss.isOngoing,
              );
              return _floorViewRoomCard(roomNum, hasIssue);
            }),
          ),
        ],
      ],
    );
  }

  Widget _floorViewAreaCard(String area, bool hasIssue) {
    return Container(
      width: 130,
      height: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasIssue ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
        border: Border.all(
          color: hasIssue ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(
            Icons.location_on,
            size: 14,
            color: hasIssue ? kRed.withOpacity(0.6) : kGreen.withOpacity(0.4),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                area.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: hasIssue ? kRed : kGreen,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                hasIssue ? 'ISSUE' : 'OK',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: hasIssue ? const Color(0xFFFCA5A5) : kGreen.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _floorViewRoomCard(String roomNum, bool hasIssue) {
    return Container(
      width: 56,
      height: 48,
      decoration: BoxDecoration(
        color: hasIssue ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
        border: Border.all(
          color: hasIssue ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            roomNum,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: hasIssue ? kRed : kGreen,
            ),
          ),
          Icon(
            hasIssue ? Icons.warning_rounded : Icons.check_circle,
            size: 12,
            color: hasIssue ? kRed : kGreen.withOpacity(0.4),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorIssueCard(IssueModel issue) {
    final priorityColor = _getPriorityColor(issue.priority);
    final bgColor = _getPriorityBgColor(issue.priority);
    final borderColor = _getPriorityBorderColor(issue.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(20),
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
                    decoration: BoxDecoration(
                      color: priorityColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      issue.priority.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: kAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      issue.department,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: kAccent,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                issue.timeAgo,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            issue.description,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: kDark,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            issue.area.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: priorityColor,
            ),
          ),
          const SizedBox(height: 16),
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
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'TAKE ACTION',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Get current user's department
  String get _userDepartment => _currentUser?.department ?? 'Engineering';

  /// Get issues count in the last N days for a specific department
  int _getIssueCountInLastDays(String department, int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return _issues.where((i) => 
      i.department == department && 
      i.createdAt.isAfter(cutoff)
    ).length;
  }

  Widget _buildHomeView() {
    // Order departments: user's department first, then others
    final allDepartments = ['Engineering', 'IT', 'Housekeeping'];
    final orderedDepartments = <String>[
      _userDepartment,
      ...allDepartments.where((d) => d != _userDepartment),
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // All department wrapped cards
          ...orderedDepartments.map((dept) => _buildDepartmentWrappedCard(dept)),
        ],
      ),
    );
  }

  /// Wrapped card for a department (same style as employee dashboard)
  Widget _buildDepartmentWrappedCard(String department) {
    final deptIssues = _issues.where((i) => i.department == department && i.isOngoing).toList();
    final issuesLast30Days = _getIssueCountInLastDays(department, 30);
    final issuesLast1Year = _getIssueCountInLastDays(department, 365);
    final isUserDept = department == _userDepartment;

    return GestureDetector(
      onTap: () => setState(() => _selectedView = 'department:$department'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main today's issues card
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isUserDept ? const Color(0xFFF8FAFC) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isUserDept ? kAccent.withOpacity(0.3) : const Color(0xFFE2E8F0), 
                    width: isUserDept ? 2 : 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Department Name with badge if user's dept
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$department\nDepartment',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: kDark,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (isUserDept)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: kAccent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'YOUR DEPT',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Large issue count
                    Center(
                      child: Text(
                        '${deptIssues.length}',
                        style: GoogleFonts.inter(
                          fontSize: 64,
                          fontWeight: FontWeight.w800,
                          color: deptIssues.isEmpty ? kGreen : kRed,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Active issues label
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: deptIssues.isEmpty ? kGreen.withOpacity(0.1) : kRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          deptIssues.isEmpty ? 'All Clear' : 'Active Issues Today',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: deptIssues.isEmpty ? kGreen : kRed,
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
            '${issue.floor} - ${issue.area}',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: priorityColor),
          ),
          const SizedBox(height: 14),
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
