import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../config/departments.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import 'add_user_screen.dart';
import 'edit_user_screen.dart';

/// User Management Screen
/// Lists all users with filters and search
class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  // Design colors
  static const Color kDark = Color(0xFF0F172A);
  static const Color kGrey = Color(0xFF64748B);
  static const Color kAccent = Color(0xFF3B82F6);
  static const Color kGreen = Color(0xFF10B981);
  static const Color kRed = Color(0xFFEF4444);

  // Filter state
  String? _selectedDepartment;
  UserRole? _selectedRole;
  bool _showInactive = false;
  String _searchQuery = '';

  final _searchController = TextEditingController();
  final _userService = UserService();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: kDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'User Management',
          style: GoogleFonts.sora(
            color: kDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: kAccent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
            onPressed: () => _navigateToAddUser(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search and filters
          _buildSearchAndFilters(),
          // User list
          Expanded(
            child: _buildUserList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          // Search field
          TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _searchQuery = value),
            style: GoogleFonts.sora(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              hintStyle: GoogleFonts.sora(color: kGrey.withOpacity(0.5)),
              prefixIcon: const Icon(Icons.search, color: kGrey, size: 20),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kAccent, width: 2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Department filter
                _buildFilterDropdown(
                  label: _selectedDepartment ?? 'All Departments',
                  icon: Icons.business,
                  onTap: () => _showDepartmentFilter(),
                  isActive: _selectedDepartment != null,
                ),
                const SizedBox(width: 8),
                // Role filter
                _buildFilterDropdown(
                  label: _selectedRole?.displayName ?? 'All Roles',
                  icon: Icons.badge,
                  onTap: () => _showRoleFilter(),
                  isActive: _selectedRole != null,
                ),
                const SizedBox(width: 8),
                // Show inactive toggle
                _buildFilterChip(
                  label: 'Show Inactive',
                  isActive: _showInactive,
                  onTap: () => setState(() => _showInactive = !_showInactive),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
    required bool isActive,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? kAccent.withOpacity(0.1) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? kAccent : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: isActive ? kAccent : kGrey),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? kAccent : kGrey,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_drop_down, size: 18, color: isActive ? kAccent : kGrey),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? kAccent : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? kAccent : const Color(0xFFE2E8F0),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.sora(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : kGrey,
          ),
        ),
      ),
    );
  }

  Widget _buildUserList() {
    // For dummy mode, show static list
    if (!AuthService.firebaseInitialized) {
      return _buildDummyUserList();
    }

    return StreamBuilder<List<UserModel>>(
      stream: _userService.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: kRed.withOpacity(0.5)),
                const SizedBox(height: 16),
                Text(
                  'Failed to load users',
                  style: GoogleFonts.sora(color: kGrey),
                ),
              ],
            ),
          );
        }

        final users = _filterUsers(snapshot.data ?? []);

        if (users.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) => _buildUserCard(users[index]),
        );
      },
    );
  }

  Widget _buildDummyUserList() {
    // Show dummy users for testing
    final dummyUsers = [
      UserModel(
        uid: 'dummy-admin-uid',
        email: 'admin@novotel.com',
        displayName: 'IT Admin',
        role: UserRole.systemAdmin,
        department: Departments.it,
        isActive: true,
        createdAt: DateTime.now(),
      ),
      UserModel(
        uid: 'dummy-manager-uid',
        email: 'manager@novotel.com',
        displayName: 'Engineering Manager',
        role: UserRole.manager,
        department: Departments.engineering,
        isActive: true,
        createdAt: DateTime.now(),
      ),
      UserModel(
        uid: 'dummy-staff-uid',
        email: 'staff@novotel.com',
        displayName: 'John Staff',
        role: UserRole.staff,
        department: Departments.housekeeping,
        isActive: true,
        createdAt: DateTime.now(),
      ),
    ];

    final filteredUsers = _filterUsers(dummyUsers);

    if (filteredUsers.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) => _buildUserCard(filteredUsers[index]),
    );
  }

  List<UserModel> _filterUsers(List<UserModel> users) {
    return users.where((user) {
      // Filter by active status
      if (!_showInactive && !user.isActive) return false;

      // Filter by department
      if (_selectedDepartment != null && user.department != _selectedDepartment) {
        return false;
      }

      // Filter by role
      if (_selectedRole != null && user.role != _selectedRole) return false;

      // Filter by search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        return user.displayName.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query);
      }

      return true;
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: kGrey.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: kGrey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: GoogleFonts.sora(fontSize: 14, color: kGrey.withOpacity(0.7)),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(UserModel user) {
    final roleColor = _getRoleColor(user.role);

    return GestureDetector(
      onTap: () => _navigateToEditUser(user),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: user.isActive ? const Color(0xFFE2E8F0) : kRed.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: kGrey.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: roleColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.sora(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: roleColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.displayName,
                          style: GoogleFonts.sora(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: kDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!user.isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: kRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'INACTIVE',
                            style: GoogleFonts.sora(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: kRed,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: GoogleFonts.sora(
                      fontSize: 12,
                      color: kGrey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Role badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: roleColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          user.role.displayName,
                          style: GoogleFonts.sora(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: roleColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Department
                      Icon(Icons.business, size: 12, color: kGrey.withOpacity(0.5)),
                      const SizedBox(width: 4),
                      Text(
                        user.department,
                        style: GoogleFonts.sora(
                          fontSize: 11,
                          color: kGrey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(Icons.chevron_right, color: kGrey.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.systemAdmin:
        return const Color(0xFF8B5CF6); // Purple
      case UserRole.manager:
        return kAccent; // Blue
      case UserRole.staff:
        return kGreen; // Green
    }
  }

  void _showDepartmentFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterSheet(
        title: 'Filter by Department',
        options: [
          _FilterOption('All Departments', null),
          ...Departments.all.map((d) => _FilterOption(d, d)),
        ],
        selectedValue: _selectedDepartment,
        onSelect: (value) {
          setState(() => _selectedDepartment = value);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showRoleFilter() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterSheet(
        title: 'Filter by Role',
        options: [
          _FilterOption('All Roles', null),
          ...UserRole.values.map((r) => _FilterOption(r.displayName, r)),
        ],
        selectedValue: _selectedRole,
        onSelect: (value) {
          setState(() => _selectedRole = value);
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildFilterSheet<T>({
    required String title,
    required List<_FilterOption<T>> options,
    required T? selectedValue,
    required void Function(T?) onSelect,
  }) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.sora(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: kDark,
            ),
          ),
          const SizedBox(height: 16),
          ...options.map((option) => ListTile(
                onTap: () => onSelect(option.value),
                leading: Icon(
                  selectedValue == option.value
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: selectedValue == option.value ? kAccent : kGrey,
                ),
                title: Text(
                  option.label,
                  style: GoogleFonts.sora(
                    fontWeight: selectedValue == option.value
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: kDark,
                  ),
                ),
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _navigateToAddUser() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddUserScreen()),
    );
  }

  void _navigateToEditUser(UserModel user) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditUserScreen(user: user)),
    );
  }
}

class _FilterOption<T> {
  final String label;
  final T? value;

  _FilterOption(this.label, this.value);
}
