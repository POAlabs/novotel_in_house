import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../settings_screen.dart';
import '../report_issue/report_issue_flow.dart';
import '../../models/floor_model.dart';
import '../../models/issue_model.dart';
import '../../models/user_model.dart';
import '../../models/room_model.dart';
import '../../services/auth_service.dart';
import '../../services/issue_service.dart';
import '../../services/room_service.dart';
import '../../config/departments.dart';
import '../../widgets/issue_action_sheets.dart';
import '../housekeeping/room_cleaning_screen.dart';
import '../housekeeping/room_inspection_screen.dart';
import '../front_office/room_management_screen.dart';

/// Employee dashboard
/// Floor diagnostic system with bottom navigation
class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> with TickerProviderStateMixin {
  // Design system colors
  static const Color kBg = Color(0xFFF8FAFC);
  static const Color kDark = Color(0xFF0F172A);
  static const Color kNavy = Color(0xFF1E3A5F);
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

  // View filter mode: 'department', 'all', 'arrivals'
  String _viewMode = 'department';

  // Get current user from auth service
  UserModel? get _currentUser => AuthService().currentUser;

  // Issue service for Firebase data
  final IssueService _issueService = IssueService();
  
  // Room service for room statuses
  final RoomService _roomService = RoomService();

  // Live issues from Firebase
  List<IssueModel> _issues = [];
  
  // Live rooms from Firebase
  Map<String, RoomModel> _roomsMap = {};

  // ScrollController for floor view to auto-scroll to issues
  final ScrollController _floorViewScrollController = ScrollController();

  // Target room to scroll to after navigating to floor
  String? _scrollToRoom;

  // GlobalKey for the target room/area to scroll to (created fresh each time)
  GlobalKey? _targetRoomKey;

  // Animation controllers for orbital home view
  late AnimationController _orbitController;
  late AnimationController _entryController;
  late Animation<double> _centerScaleAnimation;
  late Animation<double> _orbitExpansionAnimation;
  
  // Front Office animation controllers
  late AnimationController _foEntryController;
  late Animation<double> _foMainCircleScale;
  late Animation<double> _foSecondaryCirclesScale;
  late Animation<double> _foChartSlideUp;
  late Animation<double> _foChartFade;
  late Animation<double> _foHeaderFade;
  late Animation<double> _foProgressAnimation;
  
  // Housekeeping Supervisor animation controllers
  late AnimationController _hkEntryController;
  late Animation<double> _hkHeaderFade;
  late Animation<double> _hkDonutDraw;
  late Animation<double> _hkListStagger1;
  late Animation<double> _hkListStagger2;
  late Animation<double> _hkListStagger3;
  late Animation<double> _hkPulseOpacity;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    // Continuous orbit rotation (120 seconds for full rotation - slow and smooth)
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 120),
    )..repeat();

    // Entry animation (1.2 seconds)
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Center number scale animation
    _centerScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Orbit expansion animation (circles fly out from center)
    _orbitExpansionAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Start entry animation
    _entryController.forward();
    
    // Front Office entry animation — 2800ms for a premium, hotel-quality feel
    _foEntryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // Header fades in first — graceful and slow
    _foHeaderFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _foEntryController,
        curve: const Interval(0.0, 0.22, curve: Curves.easeOut),
      ),
    );

    // Main circle scales in with elastic bounce — starts after header
    _foMainCircleScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _foEntryController,
        curve: const Interval(0.12, 0.58, curve: Curves.elasticOut),
      ),
    );

    // Secondary circles — staggered later for a cascade effect
    _foSecondaryCirclesScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _foEntryController,
        curve: const Interval(0.35, 0.78, curve: Curves.elasticOut),
      ),
    );

    // Progress rings fill up as circles finish scaling
    _foProgressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _foEntryController,
        curve: const Interval(0.20, 0.88, curve: Curves.easeOutCubic),
      ),
    );

    // Chart slides up from further below — starts after circles settle
    _foChartSlideUp = Tween<double>(begin: 80.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _foEntryController,
        curve: const Interval(0.62, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Chart fades in cleanly alongside the slide
    _foChartFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _foEntryController,
        curve: const Interval(0.58, 0.95, curve: Curves.easeOut),
      ),
    );

    // Start Front Office animation
    _foEntryController.forward();
  }

  @override
  void dispose() {
    _floorViewScrollController.dispose();
    _orbitController.dispose();
    _entryController.dispose();
    _foEntryController.dispose();
    super.dispose();
  }

  /// Navigate to floor and scroll to specific room/area
  void _navigateToFloorAndScrollTo(String floorId, String area) {
    setState(() {
      _currentNavIndex = 0; // Switch to Building tab
      _selectedFloorId = floorId;
      _scrollToRoom = area;
      _targetRoomKey = GlobalKey(); // Create fresh key
    });
    // Scroll after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToTargetRoom();
    });
  }

  /// Scroll to the target room/area
  void _scrollToTargetRoom() {
    if (_scrollToRoom == null || _targetRoomKey == null) return;
    if (_targetRoomKey!.currentContext != null) {
      Scrollable.ensureVisible(
        _targetRoomKey!.currentContext!,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        alignment: 0.3,
      );
    }
    _scrollToRoom = null;
    _targetRoomKey = null;
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

  /// Handle back button press - returns true if handled internally
  bool _handleBackPress() {
    // If viewing a floor detail, go back to floor list
    if (_selectedFloorId != null) {
      setState(() => _selectedFloorId = null);
      return true;
    }
    // If on Building or Settings tab, go to Home tab
    if (_currentNavIndex != 1) {
      setState(() => _currentNavIndex = 1);
      return true;
    }
    // On Home tab - don't handle, let system decide
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (!_handleBackPress()) {
          // On home tab with nothing to go back to - minimize app instead of exit
          // This is standard Android behavior for home screens
        }
      },
      child: Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        bottom: false, // Bottom nav handles its own safe area
        child: StreamBuilder<List<IssueModel>>(
          stream: _issueService.getAllOngoingIssues(),
          builder: (context, issueSnapshot) {
            // Update local issues list when data changes
            if (issueSnapshot.hasData) {
              _issues = issueSnapshot.data!;
            }

            return StreamBuilder<List<RoomModel>>(
              stream: _roomService.getAllRooms(),
              builder: (context, roomSnapshot) {
                if (roomSnapshot.hasData) {
                  _roomsMap = {for (var room in roomSnapshot.data!) room.roomNumber: room};
                }
                return _buildCurrentTabContent();
              },
            );
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
      onTap: () {
        final wasOnHome = _currentNavIndex == 1;
        setState(() {
          _currentNavIndex = index;
          if (index != 0) _selectedFloorId = null;
        });
        // Restart entry animation when navigating to home
        if (index == 1 && !wasOnHome) {
          _restartEntryAnimation();
        }
      },
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
    
    // If viewing all departments, show all issues
    if (_viewMode == 'all') {
      return true;
    }
    
    // System admins and managers can see all issues by default
    if (_currentUser!.isSystemAdmin || _currentUser!.role.name == 'manager') {
      return true;
    }
    
    // Staff can only see issues for their department
    return issue.department == _currentDepartment;
  }

  /// Show filter dialog
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'View Filter',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: kDark,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption(
              title: 'My Department',
              subtitle: 'View issues from $_currentDepartment only',
              icon: Icons.person_outline,
              isSelected: _viewMode == 'department',
              onTap: () {
                setState(() => _viewMode = 'department');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _buildFilterOption(
              title: 'All Departments',
              subtitle: 'View issues from all departments',
              icon: Icons.groups_outlined,
              isSelected: _viewMode == 'all',
              onTap: () {
                setState(() => _viewMode = 'all');
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            _buildFilterOption(
              title: 'Arrivals',
              subtitle: 'View room readiness status',
              icon: Icons.hotel_outlined,
              isSelected: _viewMode == 'arrivals',
              isComingSoon: true,
              onTap: () {
                // Coming soon - do nothing for now
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Arrivals view coming soon!'),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Build a filter option tile
  Widget _buildFilterOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    bool isComingSoon = false,
  }) {
    const blueColor = Color(0xFF3B82F6);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? blueColor.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? blueColor : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected ? blueColor : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kDark,
                        ),
                      ),
                      if (isComingSoon) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'SOON',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: blueColor, size: 20),
          ],
        ),
      ),
    );
  }

  /// Building overview — structure matching screenshot
  Widget _buildFloorListView() {
    return CustomScrollView(
      slivers: [
        // ── Header with filter button ──────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'BUILDING OVERVIEW',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    color: const Color(0xFF3B82F6),
                  ),
                ),
                // Filter button
                GestureDetector(
                  onTap: _showFilterDialog,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _viewMode != 'department' 
                          ? const Color(0xFF3B82F6).withOpacity(0.1)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _viewMode != 'department'
                            ? const Color(0xFF3B82F6)
                            : const Color(0xFFE2E8F0),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.filter_list_rounded,
                          size: 14,
                          color: _viewMode != 'department'
                              ? const Color(0xFF3B82F6)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _viewMode == 'department' 
                              ? 'Filter' 
                              : _viewMode == 'all' 
                                  ? 'All Depts' 
                                  : 'Arrivals',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: _viewMode != 'department'
                                ? const Color(0xFF3B82F6)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
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

  /// Clickable room card that navigates to floor view or room action screen
  Widget _buildClickableRoomCard(String floorId, String roomNum, bool hasIssue) {
    return GestureDetector(
      onTap: () => _onRoomTap(roomNum, floorId),
      child: _roomCard(roomNum, hasIssue),
    );
  }
  
  /// Handle room card tap - navigate to appropriate screen based on status and user role
  void _onRoomTap(String roomNum, String floorId) {
    final room = _roomsMap[roomNum];
    if (room == null) {
      setState(() => _selectedFloorId = floorId);
      return;
    }
    
    final user = _currentUser;
    if (user == null) return;
    
    // Front Office staff: Navigate to premium room management screen
    if (user.isFrontOffice) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoomManagementScreen(
            room: room,
            currentUser: user,
          ),
        ),
      );
      return;
    }
    
    // Navigate based on room status and user permissions
    switch (room.status) {
      case RoomStatus.checkout:
        // Housekeeping staff can start cleaning
        if (user.department == 'Housekeeping' || user.isSystemAdmin) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoomCleaningScreen(roomId: room.id),
            ),
          );
        } else {
          setState(() => _selectedFloorId = floorId);
        }
        break;
      case RoomStatus.cleaning:
        // The cleaner or supervisor can continue
        if (room.cleaningStartedBy == user.uid || 
            user.role == UserRole.supervisor || 
            user.role == UserRole.manager ||
            user.isSystemAdmin) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoomCleaningScreen(roomId: room.id),
            ),
          );
        } else {
          setState(() => _selectedFloorId = floorId);
        }
        break;
      case RoomStatus.inspection:
        // Supervisors and managers can inspect
        if (user.role == UserRole.supervisor || 
            user.role == UserRole.manager ||
            user.isSystemAdmin) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => RoomInspectionScreen(roomId: room.id),
            ),
          );
        } else {
          setState(() => _selectedFloorId = floorId);
        }
        break;
      default:
        setState(() => _selectedFloorId = floorId);
    }
  }
  
  /// Get appropriate icon for room status
  IconData _getRoomStatusIcon(RoomStatus status) {
    switch (status) {
      case RoomStatus.occupied:
        return Icons.person;
      case RoomStatus.checkout:
        return Icons.cleaning_services;
      case RoomStatus.cleaning:
        return Icons.autorenew;
      case RoomStatus.inspection:
        return Icons.search;
      case RoomStatus.ready:
        return Icons.check_circle;
    }
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

  // ─── HOME VIEW - ORBITAL COMMAND CENTER ──────────────────────────────────────────

  Widget _buildHomeView() {
    final user = _currentUser;
    
    // Front Office staff get dedicated room metrics view
    if (user != null && user.isFrontOffice) {
      return _buildFrontOfficeHomeView();
    }
    
    // Other departments get the orbital issues view
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildCommandCenterHeader(),
          const SizedBox(height: 24),
          // Orbital visualization in a fixed height container
          SizedBox(
            height: 380,
            child: _buildOrbitalVisualization(),
          ),
          const SizedBox(height: 24),
          // Report Issue Button (white with blue border)
          _buildReportIssueButton(),
          const SizedBox(height: 28),
          // Active issues by date
          Text(
            'ACTIVE ISSUES',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 14),
          // Issues grouped by date
          _buildIssuesByDateList(),
        ],
      ),
    );
  }
  
  /// Front Office Home View - Premium room status dashboard with animations
  Widget _buildFrontOfficeHomeView() {
    return StreamBuilder<List<RoomModel>>(
      stream: _roomService.getAllRooms(),
      builder: (context, snapshot) {
        final rooms = snapshot.data ?? [];
        final totalRooms = rooms.length;
        
        // Calculate metrics
        final readyRooms = rooms.where((r) => r.status == RoomStatus.ready).length;
        final occupiedRooms = rooms.where((r) => r.status == RoomStatus.occupied).length;
        final cleaningRooms = rooms.where((r) => 
          r.status == RoomStatus.checkout || 
          r.status == RoomStatus.cleaning || 
          r.status == RoomStatus.inspection
        ).length;
        
        return AnimatedBuilder(
          animation: _foEntryController,
          builder: (context, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with fade in
                  Opacity(
                    opacity: _foHeaderFade.value,
                    child: _buildCommandCenterHeader(),
                  ),
                  const SizedBox(height: 32),
                  
                  // Main circular metric - Ready Rooms with scale animation
                  Transform.scale(
                    scale: _foMainCircleScale.value.clamp(0.0, 1.0),
                    child: Opacity(
                      opacity: _foMainCircleScale.value.clamp(0.0, 1.0),
                      child: _buildCircularMetric(
                        value: readyRooms,
                        total: totalRooms,
                        label: 'READY',
                        subLabel: 'ROOMS',
                        color: kGreen,
                        size: 200,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Secondary metrics - Occupied and Cleaning with delayed scale
                  Transform.scale(
                    scale: _foSecondaryCirclesScale.value.clamp(0.0, 1.0),
                    child: Opacity(
                      opacity: _foSecondaryCirclesScale.value.clamp(0.0, 1.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildCircularMetric(
                              value: occupiedRooms,
                              total: totalRooms,
                              label: 'OCCUPIED',
                              subLabel: '',
                              color: const Color(0xFF3B82F6),
                              size: 140,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildCircularMetric(
                              value: cleaningRooms,
                              total: totalRooms,
                              label: 'CLEANING',
                              subLabel: '',
                              color: const Color(0xFF0F172A),
                              size: 140,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Guest Flow Section — slides up and fades in after circles settle
                  Transform.translate(
                    offset: Offset(0, _foChartSlideUp.value),
                    child: Opacity(
                      opacity: _foChartFade.value,
                      child: _buildGuestFlowSection(rooms),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  /// Premium circular progress metric widget
  Widget _buildCircularMetric({
    required int value,
    required int total,
    required String label,
    required String subLabel,
    required Color color,
    required double size,
  }) {
    // Progress ring fills up as part of the entry animation
    final animatedProgress = total > 0
        ? (value / total) * _foProgressAnimation.value
        : 0.0;
    final percentage = total > 0 ? ((value / total) * 100).round() : 0;

    return Center(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              Colors.white,
              color.withOpacity(0.07),
            ],
            radius: 0.85,
          ),
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withOpacity(0.18),
            width: 1.5,
          ),
          boxShadow: [
            // Color-tinted glow
            BoxShadow(
              color: color.withOpacity(0.22),
              blurRadius: 36,
              spreadRadius: 4,
              offset: const Offset(0, 10),
            ),
            // Soft depth shadow
            BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Circular progress ring — animated fill
            Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(size * 0.05),
                child: CircularProgressIndicator(
                  value: animatedProgress,
                  strokeWidth: size * 0.048,
                  backgroundColor: const Color(0xFFF1F5F9),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
            ),
            // Center content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$value',
                    style: GoogleFonts.inter(
                      fontSize: size * 0.26,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: size * 0.063,
                      fontWeight: FontWeight.w700,
                      color: kDark,
                      letterSpacing: 1.5,
                    ),
                  ),
                  if (subLabel.isNotEmpty) ...[
                    Text(
                      subLabel,
                      style: GoogleFonts.inter(
                        fontSize: size * 0.053,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF94A3B8),
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
                  // Percentage badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$percentage%',
                      style: GoogleFonts.inter(
                        fontSize: size * 0.048,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
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
  
  /// Room Activity Section — bar chart using real Firestore room timestamps
  Widget _buildGuestFlowSection(List<RoomModel> rooms) {
    final now = DateTime.now();
    // Build 7-day activity from actual room timestamps
    final weekData = List.generate(7, (index) {
      final day = now.subtract(Duration(days: 6 - index));
      final dayStart = DateTime(day.year, day.month, day.day);
      final dayEnd = dayStart.add(const Duration(days: 1));

      // Rooms approved/made ready on this day
      final readyCount = rooms.where((r) =>
        r.readyAt != null &&
        r.readyAt!.isAfter(dayStart) &&
        r.readyAt!.isBefore(dayEnd)
      ).length;

      // Rooms checked out (guest departed) on this day
      final checkoutCount = rooms.where((r) =>
        r.checkoutAt != null &&
        r.checkoutAt!.isAfter(dayStart) &&
        r.checkoutAt!.isBefore(dayEnd)
      ).length;

      return _GuestFlowDay(
        day: day,
        checkIns: readyCount,
        checkOuts: checkoutCount,
      );
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Room Activity',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: kDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ready vs Checkout — last 7 days',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            // Legend
            Row(
              children: [
                _buildLegendItem('READY', const Color(0xFF60A5FA)),
                const SizedBox(width: 12),
                _buildLegendItem('CHECKOUT', const Color(0xFF0F172A)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Bar chart
        Container(
          padding: const EdgeInsets.all(20),
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
          child: _buildGuestFlowChart(weekData),
        ),
      ],
    );
  }
  
  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
  
  Widget _buildGuestFlowChart(List<_GuestFlowDay> data) {
    final maxValue = data.fold<int>(0, (max, day) => 
      [max, day.checkIns, day.checkOuts].reduce((a, b) => a > b ? a : b)
    );
    
    // Calculate nice Y-axis scale
    final yAxisMax = ((maxValue / 5).ceil() * 5).toInt() + 5;
    final gridLines = 5;
    final gridInterval = yAxisMax / gridLines;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 220,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Y-axis title (rotated, reads bottom-to-top)
              Padding(
                padding: const EdgeInsets.only(bottom: 28),
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'ROOMS',
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              // Y-axis labels
              SizedBox(
                width: 26,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(gridLines + 1, (index) {
                    final value = (yAxisMax - (index * gridInterval)).toInt();
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        '$value',
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF334155),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              // Chart area
              Expanded(
                child: Stack(
                  children: [
                    // Horizontal grid lines
                    ...List.generate(gridLines + 1, (index) {
                      final position = (index / gridLines);
                      return Positioned(
                        left: 0,
                        right: 0,
                        top: position * 180,
                        child: Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFE2E8F0).withOpacity(0.3),
                                const Color(0xFFE2E8F0),
                                const Color(0xFFE2E8F0).withOpacity(0.3),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    // Bars
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10, bottom: 30),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: data.map((day) => _buildDayBar(day, yAxisMax)).toList(),
                        ),
                      ),
                    ),
                    // X-axis line
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 28,
                      child: Container(
                        height: 2,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    // X-axis labels (day names)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 28,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: data.map((day) {
                          final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                          final dayName = dayNames[day.day.weekday - 1];
                          return Expanded(
                            child: Center(
                              child: Text(
                                dayName,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // X-axis title
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Row(
            children: [
              const SizedBox(width: 44), // align with chart area
              Expanded(
                child: Center(
                  child: Text(
                    'DAY OF WEEK',
                    style: GoogleFonts.inter(
                      fontSize: 8,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildDayBar(_GuestFlowDay day, int maxValue) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Ready bar — bright blue
            Expanded(
              child: Container(
                height: maxValue > 0 ? (day.checkIns / maxValue) * 150 : 2,
                decoration: const BoxDecoration(
                  color: Color(0xFF60A5FA),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
            ),
            const SizedBox(width: 2),
            // Checkout bar — dark navy
            Expanded(
              child: Container(
                height: maxValue > 0 ? (day.checkOuts / maxValue) * 150 : 2,
                decoration: const BoxDecoration(
                  color: Color(0xFF0F172A),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Command center header with hotel name
  Widget _buildCommandCenterHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NOVOTEL HOTEL',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: kNavy,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'In-House App',
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  /// Restart the entry animation when returning to home
  void _restartEntryAnimation() {
    _entryController.reset();
    _entryController.forward();
    
    // Also restart Front Office animations if user is Front Office
    if (_currentUser?.isFrontOffice ?? false) {
      _foEntryController.reset();
      _foEntryController.forward();
    }
  }

  /// Main orbital visualization with central count and orbiting floors
  Widget _buildOrbitalVisualization() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final centerX = constraints.maxWidth / 2;
        final centerY = constraints.maxHeight / 2; // Center vertically
        final orbitRadius = math.min(constraints.maxWidth, constraints.maxHeight) * 0.38;

        // Get floors with active issues
        final floorsWithIssues = _floors.where((f) => _hasIssue(f.id)).toList();
        final totalActiveIssues = _departmentIssues.length;

        return AnimatedBuilder(
          animation: Listenable.merge([_orbitController, _entryController]),
          builder: (context, child) {
            return Stack(
              children: [
                // Orbiting floor circles
                ...List.generate(floorsWithIssues.length, (index) {
                  final floor = floorsWithIssues[index];
                  final issueCount = _getFloorIssueCount(floor.id);
                  
                  // Calculate position on orbit
                  final baseAngle = (2 * math.pi * index) / floorsWithIssues.length;
                  final rotationAngle = _orbitController.value * 2 * math.pi;
                  final currentAngle = baseAngle + rotationAngle;
                  
                  // Apply expansion animation
                  final currentRadius = orbitRadius * _orbitExpansionAnimation.value;
                  
                  final x = centerX + currentRadius * math.cos(currentAngle) - 28;
                  final y = centerY + currentRadius * math.sin(currentAngle) - 28;

                  return Positioned(
                    left: x,
                    top: y,
                    child: Opacity(
                      opacity: _orbitExpansionAnimation.value,
                      child: _buildOrbitingFloorCircle(
                        floor.id,
                        issueCount,
                        currentAngle,
                      ),
                    ),
                  );
                }),
                // Central active issues count
                Positioned(
                  left: centerX - 80,
                  top: centerY - 70,
                  child: Transform.scale(
                    scale: _centerScaleAnimation.value,
                    child: _buildCentralIssueCount(totalActiveIssues),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Central floating issue count - RED number (or green with image when 0)
  Widget _buildCentralIssueCount(int count) {
    // If no issues, show all clear image
    if (count == 0) {
      return SizedBox(
        width: 160,
        height: 160,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                'assets/all_clear.jpeg',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '0 ACTIVE',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: kGreen,
                letterSpacing: 2,
              ),
            ),
            Text(
              'ISSUES',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF94A3B8),
                letterSpacing: 3,
              ),
            ),
          ],
        ),
      );
    }
    
    return SizedBox(
      width: 160,
      height: 140,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 96,
              fontWeight: FontWeight.w800,
              color: kRed,
              height: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'A C T I V E',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3B82F6),
              letterSpacing: 6,
            ),
          ),
          Text(
            'ISSUES',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
              letterSpacing: 3,
            ),
          ),
        ],
      ),
    );
  }

  /// All clear card when there are no issues
  Widget _buildAllClearCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'All Clear!',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: kGreen,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No active issues in $_currentDepartment',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Orbiting floor circle with blue glow effect
  Widget _buildOrbitingFloorCircle(String floorId, int issueCount, double angle) {
    const glowColor = Color(0xFF3B82F6); // Blue glow
    
    return GestureDetector(
      onTap: () => setState(() {
        _currentNavIndex = 0;
        _selectedFloorId = floorId;
      }),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            // Blue glow effect
            BoxShadow(
              color: glowColor.withOpacity(0.4),
              blurRadius: 16,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: glowColor.withOpacity(0.2),
              blurRadius: 24,
              spreadRadius: 4,
            ),
            // Subtle shadow for depth
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Text(
            floorId,
            style: GoogleFonts.inter(
              fontSize: floorId.length > 2 ? 14 : 18,
              fontWeight: FontWeight.w700,
              color: kNavy,
            ),
          ),
        ),
      ),
    );
  }

  /// Report Issue button - white with blue border
  Widget _buildReportIssueButton() {
    const blueColor = Color(0xFF3B82F6);
    
    return GestureDetector(
      onTap: _openReportIssueFlow,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: blueColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: blueColor.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: blueColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.add, color: blueColor, size: 24),
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
                      color: kDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to report a new issue',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: blueColor, size: 16),
          ],
        ),
      ),
    );
  }

  /// Greeting header with user's name and current date/time
  Widget _buildGreetingHeader() {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    final firstName = _currentUser?.displayName.split(' ').first ?? 'Team';
    
    // Format date
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dayName = days[now.weekday - 1];
    final dateStr = '$dayName, ${now.day} ${months[now.month - 1]}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$greeting,',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          firstName,
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: kDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          dateStr,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  /// Building health indicator - visual overview of building status
  Widget _buildBuildingHealthCard() {
    final totalFloors = _floors.length;
    final floorsWithIssues = _floors.where((f) => _hasIssue(f.id)).length;
    final healthyFloors = totalFloors - floorsWithIssues;
    final healthPercentage = (healthyFloors / totalFloors * 100).round();
    
    final isHealthy = healthPercentage >= 80;
    final statusColor = isHealthy ? kGreen : (healthPercentage >= 50 ? const Color(0xFFF59E0B) : kRed);
    final statusText = isHealthy ? 'Excellent' : (healthPercentage >= 50 ? 'Moderate' : 'Needs Attention');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Building Health',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: kDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: healthPercentage / 100,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          // Stats row
          Row(
            children: [
              _buildHealthStat('$healthyFloors', 'Floors OK', kGreen),
              const SizedBox(width: 24),
              _buildHealthStat('$floorsWithIssues', 'With Issues', kRed),
              const Spacer(),
              Text(
                '$healthPercentage%',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthStat(String value, String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: kDark,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Quick stats row - resolved today and department active issues
  Widget _buildQuickStatsRow() {
    final activeIssues = _departmentIssues.length;
    final resolvedToday = _getResolvedTodayCount();

    return Row(
      children: [
        Expanded(
          child: _buildQuickStatCard(
            icon: Icons.warning_amber_rounded,
            value: '$activeIssues',
            label: 'Active Issues',
            color: activeIssues > 0 ? kRed : kGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickStatCard(
            icon: Icons.check_circle_outline,
            value: '$resolvedToday',
            label: 'Resolved Today',
            color: kGreen,
          ),
        ),
      ],
    );
  }

  /// Get count of issues resolved today for the department
  int _getResolvedTodayCount() {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    
    // This would need resolved issues stream, for now estimate from all issues
    // In production, you'd query resolved issues from today
    return 0; // Placeholder - will show actual data when resolved issues are tracked
  }

  Widget _buildQuickStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
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
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: kDark,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Get date label for grouping
  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final issueDate = DateTime(date.year, date.month, date.day);

    if (issueDate == today) {
      return 'Today';
    } else if (issueDate == yesterday) {
      return 'Yesterday';
    } else {
      // Format as "23rd February 2025"
      final day = date.day;
      final suffix = _getDaySuffix(day);
      final months = ['January', 'February', 'March', 'April', 'May', 'June', 
                      'July', 'August', 'September', 'October', 'November', 'December'];
      return '$day$suffix ${months[date.month - 1]} ${date.year}';
    }
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  /// Group issues by date
  Map<String, List<IssueModel>> get _issuesByDate {
    final activeIssues = _issues.where((i) => i.isOngoing && _canViewIssue(i)).toList();
    // Sort by date descending (newest first)
    activeIssues.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    final Map<String, List<IssueModel>> grouped = {};
    for (final issue in activeIssues) {
      final label = _getDateLabel(issue.createdAt);
      grouped.putIfAbsent(label, () => []).add(issue);
    }
    return grouped;
  }

  /// Build issues list grouped by date
  Widget _buildIssuesByDateList() {
    final issuesByDate = _issuesByDate;
    if (issuesByDate.isEmpty) {
      return _buildAllClearCard();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: issuesByDate.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date header
            Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 8),
              child: Text(
                entry.key,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kDark,
                ),
              ),
            ),
            // Issues for this date
            ...entry.value.map((issue) => _buildDateIssueCard(issue)),
          ],
        );
      }).toList(),
    );
  }

  /// Issue card for date-grouped view - Blue border with priority text
  Widget _buildDateIssueCard(IssueModel issue) {
    final priorityColor = _getPriorityColor(issue.priority);
    const blueColor = Color(0xFF3B82F6);

    return GestureDetector(
      onTap: () => _navigateToFloorAndScrollTo(issue.floor, issue.area),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: blueColor.withOpacity(0.3), width: 1.5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: blueColor.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Priority badge and time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Priority badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    issue.priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: priorityColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Text(
                  issue.timeAgo,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Description
            Text(
              issue.description,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kDark,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            // Location
            Text(
              'Floor ${issue.floor} • ${issue.area}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── FLOOR VIEW ──────────────────────────────────────────────────

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
          // Floor issue history section
          const SizedBox(height: 24),
          _buildFloorHistorySection(floor.id),
        ],
      ),
    );
  }

  /// Floor-specific resolved issues history section
  Widget _buildFloorHistorySection(String floorId) {
    return StreamBuilder<List<IssueModel>>(
      stream: _issueService.getResolvedIssues(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final resolvedIssues = (snapshot.data ?? [])
            .where((issue) => issue.floor == floorId)
            .toList();
        
        if (resolvedIssues.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FLOOR HISTORY',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2, color: Color(0xFF94A3B8)),
            ),
            const SizedBox(height: 12),
            ...resolvedIssues.map((issue) => _buildHistoryCard(issue)),
          ],
        );
      },
    );
  }

  /// Build a history card for resolved issues
  Widget _buildHistoryCard(IssueModel issue) {
    final resolvedAt = issue.resolvedAt;
    final dateStr = resolvedAt != null
        ? '${resolvedAt.day}/${resolvedAt.month}/${resolvedAt.year}'
        : 'Unknown';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: kGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'RESOLVED',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: kGreen,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            issue.area,
            style: GoogleFonts.sora(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            issue.description,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (issue.resolvedByName != null) ...[
            const SizedBox(height: 6),
            Text(
              'Resolved by ${issue.resolvedByName}',
              style: const TextStyle(
                fontSize: 10,
                color: Color(0xFF94A3B8),
                fontStyle: FontStyle.italic,
              ),
            ),
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
    // Only use key if this is the target room to scroll to
    final isTarget = _scrollToRoom == area;
    
    return Container(
      key: isTarget ? _targetRoomKey : null,
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
        return GestureDetector(
          onTap: () => _onRoomTap(roomNum, floor.id),
          child: _roomCard(roomNum, hasIssue),
        );
      }),
    );
  }

  /// Individual room card - compact for mobile grid
  /// Now shows room cleaning status colors instead of just issue-based colors
  /// If room has an issue, display as red regardless of cleaning status
  Widget _roomCard(String roomNum, bool hasIssue) {
    // Only use key if this is the target room to scroll to
    final areaName = 'Room $roomNum';
    final isTarget = _scrollToRoom == areaName;
    
    // Get room status from room service data
    final room = _roomsMap[roomNum];
    final status = room?.status ?? RoomStatus.ready;
    
    // If room has an issue, override color to red
    final displayColor = hasIssue ? const Color(0xFFEF4444) : status.color;
    final displayBgColor = hasIssue ? const Color(0xFFFEF2F2) : status.backgroundColor;
    final displayBorderColor = hasIssue ? const Color(0xFFFECACA) : status.borderColor;
    final displayIcon = hasIssue ? Icons.warning : _getRoomStatusIcon(status);
    
    return Container(
      key: isTarget ? _targetRoomKey : null,
      width: 52,
      height: 44,
      decoration: BoxDecoration(
        color: displayBgColor,
        border: Border.all(
          color: displayBorderColor,
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
              color: displayColor,
            ),
          ),
          Icon(
            displayIcon,
            size: 10,
            color: displayColor.withOpacity(0.7),
          ),
        ],
      ),
    );
  }

  /// Breach alert card for floor issues - Blue border with priority text
  Widget _buildBreachCard(IssueModel issue) {
    final priorityColor = _getPriorityColor(issue.priority);
    const blueColor = Color(0xFF3B82F6);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: blueColor.withOpacity(0.3), width: 1.5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: blueColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority badge + time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  issue.priority.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: priorityColor,
                  ),
                ),
              ),
              Text(
                issue.timeAgo,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Description
          Text(
            issue.description,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: kDark,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 6),
          // Area
          Text(
            issue.area,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          // Action button
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
                backgroundColor: blueColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'TAKE ACTION',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Show front office action sheet for room management
  void _showFrontOfficeActions(RoomModel room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: room.status.backgroundColor,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: room.status.borderColor),
                  ),
                  child: Text(
                    room.roomNumber,
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: room.status.color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: room.status.color,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    room.status.displayName.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Actions based on room status
            if (room.status == RoomStatus.ready) ...[
              _buildFrontOfficeButton(
                icon: Icons.person_add,
                label: 'Check In Guest',
                color: const Color(0xFF3B82F6),
                onTap: () {
                  Navigator.pop(context);
                  _checkInGuest(room);
                },
              ),
            ],
            if (room.status == RoomStatus.occupied) ...[
              _buildFrontOfficeButton(
                icon: Icons.logout,
                label: 'Check Out Guest',
                color: const Color(0xFFEF4444),
                onTap: () {
                  Navigator.pop(context);
                  _checkOutGuest(room);
                },
              ),
            ],
            if (room.status == RoomStatus.checkout ||
                room.status == RoomStatus.cleaning ||
                room.status == RoomStatus.inspection) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Room is being cleaned by housekeeping',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF92400E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            // Cancel button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFrontOfficeButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Check in a guest (mark room as occupied)
  Future<void> _checkInGuest(RoomModel room) async {
    if (_currentUser == null) return;
    
    try {
      await _roomService.markOccupied(
        roomId: room.id,
        user: _currentUser!,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Room ${room.roomNumber} checked in'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
  
  /// Check out a guest (mark room as needing cleaning)
  Future<void> _checkOutGuest(RoomModel room) async {
    if (_currentUser == null) return;
    
    try {
      await _roomService.markCheckout(
        roomId: room.id,
        user: _currentUser!,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Room ${room.roomNumber} checked out - Ready for cleaning'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}

/// Helper class for guest flow chart data
class _GuestFlowDay {
  final DateTime day;
  int checkIns;
  int checkOuts;
  
  _GuestFlowDay({
    required this.day,
    required this.checkIns,
    required this.checkOuts,
  });
}
