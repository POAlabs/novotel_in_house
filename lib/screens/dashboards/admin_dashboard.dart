import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../settings_screen.dart';
import '../../models/floor_model.dart';
import '../../models/issue_model.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/issue_service.dart';
import '../../config/departments.dart';
import '../admin/user_management_screen.dart';

/// System Admin dashboard
/// Full access: view all issues from ALL departments, manage users, system settings
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // Design system colors
  static const Color kBg = Color(0xFFF8FAFC);
  static const Color kDark = Color(0xFF0F172A);
  static const Color kGrey = Color(0xFF64748B);
  static const Color kGreen = Color(0xFF10B981);
  static const Color kRed = Color(0xFFEF4444);
  static const Color kAccent = Color(0xFF3B82F6);
  static const Color kPurple = Color(0xFF8B5CF6);

  // Current view: null = home, 'department:X' = department view, otherwise = floor id
  String? _selectedView;

  // Get current user from auth service
  UserModel? get _currentUser => AuthService().currentUser;

  // Issue service for Firebase data
  final IssueService _issueService = IssueService();

  // Live issues from Firebase
  List<IssueModel> _issues = [];

  // All hotel floors
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

  bool _hasIssue(String floorId) {
    return _issues.any((i) => i.floor == floorId && i.isOngoing);
  }

  bool get _isViewingDepartment => _selectedView != null && _selectedView!.startsWith('department:');
  String? get _selectedDepartment => _isViewingDepartment ? _selectedView!.split(':')[1] : null;
  bool get _isViewingFloor => _selectedView != null && !_isViewingDepartment;

  FloorModel? get _selectedFloor {
    if (!_isViewingFloor) return null;
    return _floors.firstWhere((f) => f.id == _selectedView);
  }

  List<IssueModel> get _currentFloorIssues {
    if (!_isViewingFloor) return [];
    return _issues.where((i) => i.floor == _selectedView && i.isOngoing).toList();
  }

  List<IssueModel> get _currentDepartmentIssues {
    if (!_isViewingDepartment) return [];
    return _issues.where((i) => i.department == _selectedDepartment && i.isOngoing).toList();
  }

  int _getDepartmentIssueCount(String department) {
    return _issues.where((i) => i.department == department && i.isOngoing).length;
  }

  // Admin sees ALL issues
  List<IssueModel> get _allActiveIssues {
    return _issues.where((i) => i.isOngoing).toList();
  }

  Map<String, List<IssueModel>> get _issuesByFloor {
    final activeIssues = _allActiveIssues;
    final Map<String, List<IssueModel>> grouped = {};
    for (final issue in activeIssues) {
      grouped.putIfAbsent(issue.floor, () => []).add(issue);
    }
    return grouped;
  }

  Map<String, int> get _issuesByDepartment {
    final counts = <String, int>{};
    for (final issue in _allActiveIssues) {
      counts[issue.department] = (counts[issue.department] ?? 0) + 1;
    }
    return counts;
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
                      : _isViewingDepartment
                          ? _buildDepartmentView()
                          : _buildFloorView(),
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
          // Admin badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: kPurple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.admin_panel_settings, size: 20, color: kPurple),
          ),
          const SizedBox(height: 16),
          // Home button
          _sidebarIcon(
            Icons.home,
            isActive: _selectedView == null,
            onTap: () => setState(() => _selectedView = null),
          ),
          const SizedBox(height: 12),
          Container(width: 28, height: 1, color: const Color(0xFFF1F5F9)),
          const SizedBox(height: 12),
          // Floor list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: _floors.length,
              itemBuilder: (context, index) {
                final floor = _floors[index];
                final hasIssue = _hasIssue(floor.id);
                final isSelected = _selectedView == floor.id;
                return _floorChip(floor, hasIssue, isSelected);
              },
            ),
          ),
          // User Management shortcut
          _sidebarIcon(
            Icons.people_outline,
            isActive: false,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UserManagementScreen()),
            ),
          ),
          const SizedBox(height: 12),
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

  Widget _floorChip(FloorModel floor, bool hasIssue, bool isSelected) {
    final Color bg, border, text;

    if (isSelected) {
      bg = hasIssue ? kRed : kGreen;
      border = bg;
      text = Colors.white;
    } else {
      bg = hasIssue ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4);
      border = hasIssue ? const Color(0xFFFECACA) : const Color(0xFFBBF7D0);
      text = hasIssue ? kRed : kGreen;
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedView = floor.id),
      child: Container(
        width: 44,
        height: 44,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [BoxShadow(color: bg.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Center(
          child: Text(
            floor.id,
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: text),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeView() {
    final totalIssues = _allActiveIssues.length;
    final floorsAffected = _issuesByFloor.keys.length;
    final urgentCount = _allActiveIssues.where((i) => i.priority == 'Urgent').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admin header
          _buildAdminHeader(),
          const SizedBox(height: 24),
          // Department cards (large)
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

  Widget _buildQuickStats(int total, int floors, int urgent) {
    return Row(
      children: [
        _statCard('Total Issues', total.toString(), kRed, Icons.warning_rounded),
        const SizedBox(width: 12),
        _statCard('Floors Affected', floors.toString(), kAccent, Icons.layers_rounded),
        const SizedBox(width: 12),
        _statCard('Urgent', urgent.toString(), const Color(0xFFF59E0B), Icons.priority_high_rounded),
      ],
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.sora(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: kDark,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 11,
                color: const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartmentBreakdown() {
    final deptIssues = _issuesByDepartment;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BY DEPARTMENT',
          style: GoogleFonts.sora(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 3,
            color: const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: Departments.all.map((dept) {
            final count = deptIssues[dept] ?? 0;
            return _deptChip(dept, count);
          }).toList(),
        ),
      ],
    );
  }

  Widget _deptChip(String dept, int count) {
    final hasIssues = count > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: hasIssues ? kRed.withOpacity(0.1) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasIssues ? kRed.withOpacity(0.3) : const Color(0xFFBBF7D0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dept,
            style: GoogleFonts.sora(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: hasIssues ? kRed : kGreen,
            ),
          ),
          if (hasIssues) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: kRed,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.sora(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

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
              Text(
                'No active issues',
                style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      );
    }

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

  Widget _buildFloorIssueCard(String floorId, List<IssueModel> issues) {
    final floorName = _getFloorDisplayName(floorId);

    return GestureDetector(
      onTap: () => setState(() => _selectedView = floorId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            ...issues.take(2).map((issue) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(color: kRed, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      issue.description,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kDark,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getDeptColor(issue.department).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      issue.department,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: _getDeptColor(issue.department),
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorView() {
    final floor = _selectedFloor!;
    final floorIssues = _currentFloorIssues;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                floor.name,
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

  bool _floorHasRooms(String floorId) {
    final num = int.tryParse(floorId);
    return num != null && num >= 2 && num <= 10;
  }

  Widget _areaCard(String area, bool hasIssue) {
    return Container(
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
              Icon(Icons.location_on, size: 12, color: hasIssue ? kRed.withOpacity(0.6) : kGreen.withOpacity(0.4)),
              if (!hasIssue) Icon(Icons.check_circle, size: 10, color: kGreen.withOpacity(0.3)),
            ],
          ),
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
        ],
      ),
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

  Widget _roomCard(String roomNum, bool hasIssue) {
    return Container(
      width: 52,
      height: 44,
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

  Widget _buildBreachCard(IssueModel issue) {
    final deptColor = _getDeptColor(issue.department);

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
                      color: deptColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      issue.department,
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: deptColor),
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

  /// Build large department cards (3 main departments)
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

  /// Build department detail view
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
            ...deptIssues.map((issue) => _buildBreachCard(issue)),
        ],
      ),
    );
  }
}
