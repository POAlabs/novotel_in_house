import 'package:flutter/material.dart';
import '../../config/routes.dart';
import '../../models/floor_model.dart';
import '../../models/issue_model.dart';

/// Employee dashboard
/// Floor diagnostic system with persistent sidebar navigation
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

  // Current view: null = home, otherwise = selected floor id
  String? _selectedFloorId;

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

  // Mock issues for development
  final List<IssueModel> _issues = [
    IssueModel(id: '1', floor: 'B3', area: 'Engineering Workshop', description: 'Main HVAC Compressor Leak', status: 'Ongoing', priority: 'Urgent', department: 'Engineering', timeAgo: '45m ago', timestamp: DateTime.now().subtract(const Duration(minutes: 45))),
    IssueModel(id: '2', floor: 'G', area: 'Front Office', description: 'Check-in Kiosk offline', status: 'Completed', priority: 'Medium', department: 'IT', timeAgo: '2h ago', timestamp: DateTime.now().subtract(const Duration(hours: 2))),
    IssueModel(id: '3', floor: '1', area: 'Gym', description: 'Equipment safety inspection due', status: 'Ongoing', priority: 'High', department: 'Engineering', timeAgo: '1h ago', timestamp: DateTime.now().subtract(const Duration(hours: 1))),
    IssueModel(id: '4', floor: 'B2', area: 'Control Room', description: 'Security camera offline', status: 'Ongoing', priority: 'High', department: 'Security', timeAgo: '12m ago', timestamp: DateTime.now().subtract(const Duration(minutes: 12))),
    IssueModel(id: '5', floor: 'G', area: 'Main Kitchen', description: 'Freezer Temp Drop (-4C)', status: 'Ongoing', priority: 'High', department: 'Engineering', timeAgo: '1h ago', timestamp: DateTime.now().subtract(const Duration(hours: 1))),
    IssueModel(id: '6', floor: 'B1', area: 'Parking', description: 'Parking gate malfunction', status: 'Ongoing', priority: 'Low', department: 'Engineering', timeAgo: '3h ago', timestamp: DateTime.now().subtract(const Duration(hours: 3))),
    // Room issues for testing
    IssueModel(id: '7', floor: '7', area: 'Room 712', description: 'AC not cooling', status: 'Ongoing', priority: 'High', department: 'Engineering', timeAgo: '30m ago', timestamp: DateTime.now().subtract(const Duration(minutes: 30))),
    IssueModel(id: '8', floor: '7', area: 'Room 725', description: 'TV remote missing', status: 'Ongoing', priority: 'Low', department: 'Housekeeping', timeAgo: '1h ago', timestamp: DateTime.now().subtract(const Duration(hours: 1))),
    IssueModel(id: '9', floor: '5', area: 'Room 503', description: 'Bathroom leak', status: 'Ongoing', priority: 'Urgent', department: 'Engineering', timeAgo: '15m ago', timestamp: DateTime.now().subtract(const Duration(minutes: 15))),
    IssueModel(id: '10', floor: '3', area: 'Corridor', description: 'Light bulb out near elevator', status: 'Ongoing', priority: 'Low', department: 'Engineering', timeAgo: '2h ago', timestamp: DateTime.now().subtract(const Duration(hours: 2))),
    IssueModel(id: '11', floor: '10', area: 'Pool Bar', description: 'Ice machine broken', status: 'Ongoing', priority: 'Medium', department: 'Engineering', timeAgo: '45m ago', timestamp: DateTime.now().subtract(const Duration(minutes: 45))),
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
        child: Row(
          children: [
            // Persistent sidebar
            _buildSidebar(),
            // Main viewport switches between home and floor view
            Expanded(
              child: _selectedFloorId == null
                  ? _buildHomeView()
                  : _buildFloorView(),
            ),
          ],
        ),
      ),
    );
  }

  // ─── SIDEBAR ────────────────────────────────────────────────────

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
          // Home button
          _sidebarIcon(
            Icons.home,
            isActive: _selectedFloorId == null,
            onTap: () => setState(() => _selectedFloorId = null),
          ),
          const SizedBox(height: 12),
          // Divider
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
                final isSelected = _selectedFloorId == floor.id;
                return _floorChip(floor, hasIssue, isSelected);
              },
            ),
          ),
          // Settings / Logout
          _sidebarIcon(
            Icons.logout,
            isActive: false,
            onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.signIn),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  /// Sidebar icon button
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

  /// Floor chip button in sidebar
  Widget _floorChip(FloorModel floor, bool hasIssue, bool isSelected) {
    // Selected state gets solid color, unselected gets tinted border
    final Color bg;
    final Color border;
    final Color text;

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
      onTap: () => setState(() => _selectedFloorId = floor.id),
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

  // ─── TOP BAR ────────────────────────────────────────────────────

  Widget _buildTopBar(String title) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          // Dynamic title
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: Color(0xFF94A3B8),
            ),
          ),
          const Spacer(),
          // User identity block
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Staff Member', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kDark)),
              Text('EMPLOYEE', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 2, color: Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.person, size: 14, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  // ─── HOME VIEW ──────────────────────────────────────────────────

  Widget _buildHomeView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMetricsRow(),
          const SizedBox(height: 24),
          _buildDiagnosticsFeed(),
        ],
      ),
    );
  }

  /// Overview metrics - clearer display for mobile
  Widget _buildMetricsRow() {
    final ongoing = _issues.where((i) => i.isOngoing).length;
    final urgent = _issues.where((i) => i.isOngoing && i.isHighPriority).length;
    final floorsAffected = _issues.where((i) => i.isOngoing).map((i) => i.floor).toSet().length;

    return Column(
      children: [
        // Main alert banner if there are issues
        if (ongoing > 0)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              border: Border.all(color: kRed.withOpacity(0.3), width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kRed,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.warning_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$ongoing Active Issue${ongoing > 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$floorsAffected floor${floorsAffected > 1 ? 's' : ''} affected • $urgent urgent',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              border: Border.all(color: kGreen.withOpacity(0.3), width: 2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: kGreen,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.check_circle, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                const Text(
                  'All Systems Operational',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: kGreen),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Issues grouped by floor for quick overview
  Widget _buildDiagnosticsFeed() {
    // Get floors with ongoing issues
    final floorsWithIssues = <String, List<IssueModel>>{};
    for (final issue in _issues.where((i) => i.isOngoing)) {
      floorsWithIssues.putIfAbsent(issue.floor, () => []).add(issue);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            const Text(
              'ACTIVE ISSUES BY FLOOR',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 4, color: Color(0xFF94A3B8)),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: kDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text('+ REPORT ISSUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Floor cards with issues
        if (floorsWithIssues.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              border: Border.all(color: const Color(0xFFBBF7D0)),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, color: kGreen, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'All systems operational',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: kGreen),
                ),
              ],
            ),
          )
        else
          ...floorsWithIssues.entries.map((entry) => _buildFloorIssueCard(entry.key, entry.value)),
      ],
    );
  }

  /// Floor card showing all issues for that floor
  Widget _buildFloorIssueCard(String floorId, List<IssueModel> issues) {
    final floor = _floors.firstWhere((f) => f.id == floorId, orElse: () => FloorModel(id: floorId, name: 'Floor $floorId', areas: []));
    final urgentCount = issues.where((i) => i.isHighPriority).length;

    return GestureDetector(
      onTap: () => setState(() => _selectedFloorId = floorId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          border: Border.all(color: const Color(0xFFFECACA), width: 2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Floor header with issue count
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: kRed,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    floorId,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  floor.name.toUpperCase(),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1, color: kDark),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_rounded, size: 14, color: kRed),
                      const SizedBox(width: 4),
                      Text(
                        '${issues.length} issue${issues.length > 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: kRed),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Issue list
            ...issues.map((issue) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: issue.isHighPriority ? kRed : const Color(0xFFF97316),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      issue.description,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    issue.area,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade500),
                  ),
                ],
              ),
            )),
            // Tap to view hint
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'TAP TO VIEW FLOOR',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1, color: kRed.withOpacity(0.6)),
                ),
                const SizedBox(width: 4),
                Icon(Icons.arrow_forward, size: 12, color: kRed.withOpacity(0.6)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── FLOOR VIEW (inline, not a separate screen) ─────────────────

  Widget _buildFloorView() {
    final floor = _selectedFloor!;
    final floorIssues = _currentFloorIssues;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Floor title - smaller for mobile
          Text(
            floor.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kDark),
          ),
          const SizedBox(height: 16),
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
    return Container(
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
