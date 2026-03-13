import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../models/room_model.dart';
import '../../models/user_model.dart';
import '../../services/room_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/room_status_card.dart';
import '../settings_screen.dart';
import 'room_cleaning_screen.dart';
import 'room_inspection_screen.dart';

/// Housekeeping Dashboard
/// Shows rooms needing attention filtered by status
/// Different views for staff vs supervisors
class HousekeepingDashboard extends StatefulWidget {
  const HousekeepingDashboard({super.key});

  @override
  State<HousekeepingDashboard> createState() => _HousekeepingDashboardState();
}

class _HousekeepingDashboardState extends State<HousekeepingDashboard> {
  // Design colors
  static const Color kBg = Color(0xFFF8FAFC);
  static const Color kDark = Color(0xFF0F172A);
  static const Color kGrey = Color(0xFF64748B);

  // Navigation
  int _currentNavIndex = 1; // Start on Home

  // Services
  final RoomService _roomService = RoomService();
  
  // Get current user
  UserModel? get _currentUser => AuthService().currentUser;
  bool get _canApproveRooms => _currentUser?.canApproveRooms ?? false;
  bool get _isFrontOffice => _currentUser?.isFrontOffice ?? false;

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
      onTap: () => setState(() => _currentNavIndex = index),
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
    return StreamBuilder<List<RoomModel>>(
      stream: _roomService.getRoomsNeedingAttention(),
      builder: (context, snapshot) {
        final rooms = snapshot.data ?? [];
        
        // Separate rooms by status
        final checkoutRooms = rooms.where((r) => r.status == RoomStatus.checkout).toList();
        final cleaningRooms = rooms.where((r) => r.status == RoomStatus.cleaning).toList();
        final inspectionRooms = rooms.where((r) => r.status == RoomStatus.inspection).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 24),
              
              // Status summary cards
              _buildStatusSummary(
                checkoutCount: checkoutRooms.length,
                cleaningCount: cleaningRooms.length,
                inspectionCount: inspectionRooms.length,
              ),
              const SizedBox(height: 28),

              // Checkout section (needs cleaning) - RED
              if (checkoutRooms.isNotEmpty || _isFrontOffice) ...[
                _buildSectionHeader(
                  'NEEDS CLEANING',
                  color: const Color(0xFFEF4444),
                  count: checkoutRooms.length,
                ),
                const SizedBox(height: 12),
                if (checkoutRooms.isEmpty)
                  _buildEmptyState('No rooms waiting for cleaning')
                else
                  ...checkoutRooms.map((room) => _buildRoomCard(room)),
                const SizedBox(height: 24),
              ],

              // Cleaning in progress section - ORANGE
              if (cleaningRooms.isNotEmpty) ...[
                _buildSectionHeader(
                  'CLEANING IN PROGRESS',
                  color: const Color(0xFFF59E0B),
                  count: cleaningRooms.length,
                ),
                const SizedBox(height: 12),
                ...cleaningRooms.map((room) => _buildRoomCard(room)),
                const SizedBox(height: 24),
              ],

              // Inspection section - YELLOW (Supervisors only see this prominently)
              if (inspectionRooms.isNotEmpty && _canApproveRooms) ...[
                _buildSectionHeader(
                  'AWAITING INSPECTION',
                  color: const Color(0xFFEAB308),
                  count: inspectionRooms.length,
                ),
                const SizedBox(height: 12),
                ...inspectionRooms.map((room) => _buildRoomCard(room)),
              ],

              // Empty state if nothing needs attention
              if (checkoutRooms.isEmpty && cleaningRooms.isEmpty && inspectionRooms.isEmpty)
                _buildAllClearState(),
            ],
          ),
        );
      },
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

  Widget _buildStatusSummary({
    required int checkoutCount,
    required int cleaningCount,
    required int inspectionCount,
  }) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            count: checkoutCount,
            label: 'Checkout',
            color: const Color(0xFFEF4444),
            icon: Icons.cleaning_services,
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
            count: inspectionCount,
            label: 'Inspection',
            color: const Color(0xFFEAB308),
            icon: Icons.search,
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
        // Show continue cleaning button if this user started it
        if (room.cleaningStartedBy == _currentUser?.uid) {
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
        }
        return null;
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
            children: rooms.map((room) => RoomStatusCard(
              room: room,
              onTap: () => _openRoomScreen(room),
            )).toList(),
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
