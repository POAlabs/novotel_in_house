import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/room_model.dart';
import '../../models/user_model.dart';
import '../../models/issue_model.dart';
import '../../services/room_service.dart';
import '../../services/auth_service.dart';
import '../../services/issue_service.dart';
import '../../widgets/room_status_card.dart';
import '../settings_screen.dart';
import 'room_cleaning_screen.dart';
import 'room_inspection_screen.dart';
import '../front_office/room_management_screen.dart';

/// Housekeeping Dashboard
/// Shows rooms needing attention filtered by status
/// Different views for staff vs supervisors
class HousekeepingDashboard extends StatefulWidget {
  const HousekeepingDashboard({super.key});

  @override
  State<HousekeepingDashboard> createState() => _HousekeepingDashboardState();
}

class _HousekeepingDashboardState extends State<HousekeepingDashboard> with TickerProviderStateMixin {
  // Design colors
  static const Color kBg = Color(0xFFF8FAFC);
  static const Color kDark = Color(0xFF0F172A);
  static const Color kGrey = Color(0xFF64748B);
  static const Color kLuminousGreen = Color(0xFF10B981); // Luminous green for Need Supervision
  static const Color kGreyLight = Color(0xFF94A3B8); // Light grey
  static const Color kGreyMedium = Color(0xFF64748B); // Medium grey

  // Navigation
  int _currentNavIndex = 1; // Start on Home

  // Services
  final RoomService _roomService = RoomService();
  final IssueService _issueService = IssueService();
  
  // Live issues from Firebase
  List<IssueModel> _issues = [];
  
  // Get current user
  UserModel? get _currentUser => AuthService().currentUser;
  bool get _canApproveRooms => _currentUser?.canApproveRooms ?? false;
  bool get _isFrontOffice => _currentUser?.isFrontOffice ?? false;
  
  // Animation controllers for Supervisor view
  late AnimationController _hkEntryController;
  late AnimationController _hkPulseController;
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
    // Main entry animation (1.5 seconds)
    _hkEntryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Header fade in
    _hkHeaderFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _hkEntryController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );
    
    // Donut chart drawing animation with elastic ease-out
    _hkDonutDraw = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _hkEntryController,
        curve: const Interval(0.1, 0.7, curve: Curves.easeOut),
      ),
    );
    
    // Staggered list item animations (waterfall effect)
    _hkListStagger1 = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _hkEntryController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeOut),
      ),
    );
    
    _hkListStagger2 = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _hkEntryController,
        curve: const Interval(0.5, 0.8, curve: Curves.easeOut),
      ),
    );
    
    _hkListStagger3 = Tween<double>(begin: 20.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _hkEntryController,
        curve: const Interval(0.6, 0.9, curve: Curves.easeOut),
      ),
    );
    
    // Start entry animation
    _hkEntryController.forward();
    
    // Continuous pulse for Need Supervision indicator (2 second cycle)
    _hkPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _hkPulseOpacity = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _hkPulseController,
        curve: Curves.easeInOut,
      ),
    );
  }
  
  @override
  void dispose() {
    _hkEntryController.dispose();
    _hkPulseController.dispose();
    super.dispose();
  }

  /// Handle back button press
  bool _handleBackPress() {
    if (_currentNavIndex != 1) {
      setState(() => _currentNavIndex = 1);
      return true;
    }
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
          child: _buildCurrentTabContent(),
        ),
        bottomNavigationBar: _buildBottomNavBar(),
      ),
    );
  }

  Widget _buildCurrentTabContent() {
    switch (_currentNavIndex) {
      case 0:
        return _buildRoomsOverview();
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
      onTap: () {
        final wasOnHome = _currentNavIndex == 1;
        setState(() => _currentNavIndex = index);
        // Restart animations when navigating to home
        if (index == 1 && !wasOnHome && _canApproveRooms) {
          _hkEntryController.reset();
          _hkEntryController.forward();
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

  // ─── HOME VIEW ────────────────────────────────────────────────────

  Widget _buildHomeView() {
    // Show supervisor view or staff view based on role
    if (_canApproveRooms) {
      return _buildSupervisorHomeView();
    } else {
      return _buildStaffHomeView();
    }
  }
  
  /// Housekeeping Staff Home View - Focus on rooms to clean
  Widget _buildStaffHomeView() {
    return StreamBuilder<List<RoomModel>>(
      stream: _roomService.getRoomsNeedingAttention(),
      builder: (context, snapshot) {
        final rooms = snapshot.data ?? [];
        
        // Separate rooms by status
        final checkoutRooms = rooms.where((r) => r.status == RoomStatus.checkout).toList();
        final cleaningRooms = rooms.where((r) => r.status == RoomStatus.cleaning).toList();
        final readyRooms = rooms.where((r) => r.status == RoomStatus.ready).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 24),
              
              // Staff-specific metrics
              _buildStaffMetrics(
                needsCleaningCount: checkoutRooms.length,
                inProgressCount: cleaningRooms.length,
                cleanedTodayCount: readyRooms.length,
              ),
              const SizedBox(height: 28),

              // Rooms needing cleaning - RED (Priority for staff)
              if (checkoutRooms.isNotEmpty) ...[
                _buildSectionHeader(
                  'NEEDS CLEANING',
                  color: const Color(0xFFEF4444),
                  count: checkoutRooms.length,
                ),
                const SizedBox(height: 12),
                ...checkoutRooms.map((room) => _buildRoomCard(room)),
                const SizedBox(height: 24),
              ],

              // Cleaning in progress section - ORANGE
              if (cleaningRooms.isNotEmpty) ...[
                _buildSectionHeader(
                  'IN PROGRESS',
                  color: const Color(0xFFF59E0B),
                  count: cleaningRooms.length,
                ),
                const SizedBox(height: 12),
                ...cleaningRooms.map((room) => _buildRoomCard(room)),
              ],

              // Empty state if nothing needs attention
              if (checkoutRooms.isEmpty && cleaningRooms.isEmpty)
                _buildAllClearState(),
            ],
          ),
        );
      },
    );
  }
  
  /// Housekeeping Supervisor Home View - Premium animated dashboard
  Widget _buildSupervisorHomeView() {
    return StreamBuilder<List<RoomModel>>(
      stream: _roomService.getAllRooms(),
      builder: (context, snapshot) {
        final rooms = snapshot.data ?? [];
        final totalRooms = rooms.length;
        
        // Calculate room status counts
        final needSupervision = rooms.where((r) => r.status == RoomStatus.inspection).length;
        final underCleaning = rooms.where((r) => 
          r.status == RoomStatus.cleaning || r.status == RoomStatus.checkout
        ).length;
        final occupied = rooms.where((r) => r.status == RoomStatus.occupied).length;

        return AnimatedBuilder(
          animation: _hkEntryController,
          builder: (context, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with fade in
                  Opacity(
                    opacity: _hkHeaderFade.value,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'NOVOTEL HOTEL',
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1E3A5F),
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'In-House App · Housekeeping Supervisor',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Section title
                  Opacity(
                    opacity: _hkHeaderFade.value,
                    child: Text(
                      'Room Status Overview',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: kDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Opacity(
                    opacity: _hkHeaderFade.value,
                    child: Text(
                      'REAL-TIME HOUSEKEEPING DISTRIBUTION',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  
                  // Animated Donut Chart
                  _buildAnimatedDonutChart(
                    total: totalRooms,
                    needSupervision: needSupervision,
                    underCleaning: underCleaning,
                    occupied: occupied,
                    progress: _hkDonutDraw.value,
                  ),
                  const SizedBox(height: 32),
                  
                  // Staggered Status List
                  _buildStaggeredStatusList(
                    total: totalRooms,
                    needSupervision: needSupervision,
                    underCleaning: underCleaning,
                    occupied: occupied,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Animated donut chart showing room status distribution
  Widget _buildAnimatedDonutChart({
    required int total,
    required int needSupervision,
    required int underCleaning,
    required int occupied,
    required double progress,
  }) {
    return Center(
      child: Container(
        width: 240,
        height: 240,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Custom painted donut chart
            CustomPaint(
              size: const Size(240, 240),
              painter: _DonutChartPainter(
                total: total,
                needSupervision: needSupervision,
                underCleaning: underCleaning,
                occupied: occupied,
                progress: progress,
              ),
            ),
            // Center number
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$total',
                    style: GoogleFonts.inter(
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      color: kDark,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'TOTAL ROOMS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: kGrey,
                      letterSpacing: 1.5,
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
  
  /// Staggered status list with slide-up animations
  Widget _buildStaggeredStatusList({
    required int total,
    required int needSupervision,
    required int underCleaning,
    required int occupied,
  }) {
    return Column(
      children: [
        // Need Supervision - with pulsing animation
        AnimatedBuilder(
          animation: _hkPulseController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _hkListStagger1.value),
              child: Opacity(
                opacity: _hkListStagger1.value < 15 ? (20 - _hkListStagger1.value) / 20 : 1.0,
                child: Opacity(
                  opacity: _hkPulseOpacity.value,
                  child: _buildStatusItem(
                    count: needSupervision,
                    label: 'Need Supervision',
                    color: kLuminousGreen,
                    total: total,
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        
        // Under Cleaning
        Transform.translate(
          offset: Offset(0, _hkListStagger2.value),
          child: Opacity(
            opacity: _hkListStagger2.value < 15 ? (20 - _hkListStagger2.value) / 20 : 1.0,
            child: _buildStatusItem(
              count: underCleaning,
              label: 'Under Cleaning',
              color: kGreyLight,
              total: total,
            ),
          ),
        ),
        const SizedBox(height: 12),
        
        // Occupied
        Transform.translate(
          offset: Offset(0, _hkListStagger3.value),
          child: Opacity(
            opacity: _hkListStagger3.value < 15 ? (20 - _hkListStagger3.value) / 20 : 1.0,
            child: _buildStatusItem(
              count: occupied,
              label: 'Occupied',
              color: kGreyMedium,
              total: total,
            ),
          ),
        ),
      ],
    );
  }
  
  /// Individual status item in the list
  Widget _buildStatusItem({
    required int count,
    required String label,
    required Color color,
    required int total,
  }) {
    final percentage = total > 0 ? ((count / total) * 100).round() : 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Color indicator
          Container(
            width: 8,
            height: 48,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 16),
          // Label and count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$percentage% of total',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: kGrey,
                  ),
                ),
              ],
            ),
          ),
          // Count number
          Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Housekeeping',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: kDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _canApproveRooms ? 'Supervisor View' : 'Staff View',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: kGrey,
          ),
        ),
      ],
    );
  }

  /// Staff metrics - Focus on cleaning workload
  Widget _buildStaffMetrics({
    required int needsCleaningCount,
    required int inProgressCount,
    required int cleanedTodayCount,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            count: needsCleaningCount,
            label: 'To Clean',
            color: const Color(0xFFEF4444),
            icon: Icons.cleaning_services,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            count: inProgressCount,
            label: 'In Progress',
            color: const Color(0xFFF59E0B),
            icon: Icons.autorenew,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            count: cleanedTodayCount,
            label: 'Cleaned',
            color: const Color(0xFF10B981),
            icon: Icons.check_circle,
          ),
        ),
      ],
    );
  }
  
  /// Supervisor metrics - Focus on inspection and oversight
  Widget _buildSupervisorMetrics({
    required int awaitingInspectionCount,
    required int cleaningCount,
    required int checkoutCount,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            count: awaitingInspectionCount,
            label: 'Inspect',
            color: const Color(0xFFEAB308),
            icon: Icons.search,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            count: cleaningCount,
            label: 'Cleaning',
            color: const Color(0xFFF59E0B),
            icon: Icons.autorenew,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            count: checkoutCount,
            label: 'Pending',
            color: const Color(0xFFEF4444),
            icon: Icons.pending_actions,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required int count,
    required String label,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: kDark,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: kGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {required Color color, required int count}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRoomCard(RoomModel room) {
    return RoomDetailCard(
      room: room,
      onTap: () => _openRoomScreen(room),
      actionButton: _buildActionButton(room),
    );
  }

  Widget? _buildActionButton(RoomModel room) {
    switch (room.status) {
      case RoomStatus.checkout:
        // Staff can start cleaning
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _startCleaning(room),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text(
              'START CLEANING',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
            ),
          ),
        );
      case RoomStatus.cleaning:
        // Any housekeeping staff can continue cleaning any room
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _openRoomScreen(room),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF59E0B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text(
              'CONTINUE CLEANING',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
            ),
          ),
        );
      case RoomStatus.inspection:
        // Supervisors can inspect
        if (_canApproveRooms) {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _openRoomScreen(room),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEAB308),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                'INSPECT ROOM',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1),
              ),
            ),
          );
        }
        return null;
      default:
        return null;
    }
  }

  Widget _buildEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(
          message,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: kGrey,
          ),
        ),
      ),
    );
  }

  Widget _buildAllClearState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Color(0xFF10B981),
          ),
          const SizedBox(height: 16),
          Text(
            'All Clear!',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No rooms need attention right now',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ─── ROOMS OVERVIEW (Building Tab) ────────────────────────────────

  Widget _buildRoomsOverview() {
    return StreamBuilder<List<IssueModel>>(
      stream: _issueService.getAllOngoingIssues(),
      builder: (context, issueSnapshot) {
        // Update local issues list when data changes
        if (issueSnapshot.hasData) {
          _issues = issueSnapshot.data!;
        }
        
        return StreamBuilder<List<RoomModel>>(
          stream: _roomService.getAllRooms(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final rooms = snapshot.data ?? [];
            
            // Group rooms by floor
            final roomsByFloor = <String, List<RoomModel>>{};
            for (var room in rooms) {
              roomsByFloor.putIfAbsent(room.floor, () => []).add(room);
            }

            // Sort floors
            final sortedFloors = roomsByFloor.keys.toList()
              ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

            return CustomScrollView(
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ROOMS OVERVIEW',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                            color: const Color(0xFF3B82F6),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Legend
                        const RoomStatusLegend(),
                      ],
                    ),
                  ),
                ),
                // Floor sections
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final floor = sortedFloors[index];
                        final floorRooms = roomsByFloor[floor]!;
                        return _buildFloorSection(floor, floorRooms);
                      },
                      childCount: sortedFloors.length,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFloorSection(String floor, List<RoomModel> rooms) {
    // Sort rooms by number
    rooms.sort((a, b) => a.roomNumber.compareTo(b.roomNumber));
    
    // Count rooms needing attention
    final needsAttentionCount = rooms.where((r) => 
      r.status == RoomStatus.checkout || 
      r.status == RoomStatus.cleaning || 
      r.status == RoomStatus.inspection
    ).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Floor header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: needsAttentionCount > 0 
                      ? const Color(0xFFFEF2F2) 
                      : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: needsAttentionCount > 0 
                        ? const Color(0xFFFECACA) 
                        : const Color(0xFFBBF7D0),
                  ),
                ),
                child: Text(
                  'Floor $floor',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: needsAttentionCount > 0 
                        ? const Color(0xFFEF4444) 
                        : const Color(0xFF10B981),
                  ),
                ),
              ),
              if (needsAttentionCount > 0) ...[
                const SizedBox(width: 8),
                Text(
                  '$needsAttentionCount need attention',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFFEF4444),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          // Room grid
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: rooms.map((room) {
              // Check if room has an issue
              final roomHasIssue = _issues.any(
                (i) => i.area == 'Room ${room.roomNumber}' && i.floor == room.floor && i.isOngoing,
              );
              return RoomStatusCard(
                room: room,
                hasIssue: roomHasIssue,
                onTap: () => _handleRoomTap(room),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ─── ACTIONS ──────────────────────────────────────────────────────

  Future<void> _startCleaning(RoomModel room) async {
    if (_currentUser == null) return;

    try {
      await _roomService.startCleaning(
        roomId: room.id,
        user: _currentUser!,
      );
      
      if (mounted) {
        // Navigate to cleaning screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RoomCleaningScreen(roomId: room.id),
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

  /// Handle room card tap - navigate to appropriate screen based on room status and user role
  void _handleRoomTap(RoomModel room) {
    final user = _currentUser;
    if (user == null) return;
    
    // Housekeeping staff: Handle cleaning workflow
    if (user.isHousekeeping || user.isSystemAdmin) {
      _openRoomScreen(room);
      return;
    }
    
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
    
    // Other departments: Just view room details
    _openRoomScreen(room);
  }
  
  void _openRoomScreen(RoomModel room) {
    if (room.status == RoomStatus.inspection && _canApproveRooms) {
      // Supervisors go to inspection screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoomInspectionScreen(roomId: room.id),
        ),
      );
    } else if (room.status == RoomStatus.cleaning) {
      // Anyone can view cleaning progress
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RoomCleaningScreen(roomId: room.id),
        ),
      );
    } else if (room.status == RoomStatus.checkout) {
      // Start cleaning
      _startCleaning(room);
    }
  }
}

/// Custom painter for animated donut chart
class _DonutChartPainter extends CustomPainter {
  final int total;
  final int needSupervision;
  final int underCleaning;
  final int occupied;
  final double progress;
  
  _DonutChartPainter({
    required this.total,
    required this.needSupervision,
    required this.underCleaning,
    required this.occupied,
    required this.progress,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;
    
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;
    final strokeWidth = 24.0;
    
    // Calculate angles for each segment
    final supervisionAngle = (needSupervision / total) * 360 * progress;
    final cleaningAngle = (underCleaning / total) * 360 * progress;
    final occupiedAngle = (occupied / total) * 360 * progress;
    
    // Background ring (light grey)
    final bgPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, bgPaint);
    
    // Draw segments sequentially
    double startAngle = -90; // Start from top
    
    // 1. Need Supervision (Luminous Green)
    if (supervisionAngle > 0) {
      final paint1 = Paint()
        ..color = const Color(0xFF10B981)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        rect,
        _degreesToRadians(startAngle),
        _degreesToRadians(supervisionAngle),
        false,
        paint1,
      );
      startAngle += supervisionAngle;
    }
    
    // 2. Under Cleaning (Light Grey)
    if (cleaningAngle > 0) {
      final paint2 = Paint()
        ..color = const Color(0xFF94A3B8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        rect,
        _degreesToRadians(startAngle),
        _degreesToRadians(cleaningAngle),
        false,
        paint2,
      );
      startAngle += cleaningAngle;
    }
    
    // 3. Occupied (Medium Grey)
    if (occupiedAngle > 0) {
      final paint3 = Paint()
        ..color = const Color(0xFF64748B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(
        rect,
        _degreesToRadians(startAngle),
        _degreesToRadians(occupiedAngle),
        false,
        paint3,
      );
    }
  }
  
  double _degreesToRadians(double degrees) {
    return degrees * (3.141592653589793 / 180);
  }
  
  @override
  bool shouldRepaint(_DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
           oldDelegate.needSupervision != needSupervision ||
           oldDelegate.underCleaning != underCleaning ||
           oldDelegate.occupied != occupied;
  }
}
