import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/user_model.dart';
import '../../config/departments.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';

/// Edit User Screen
/// Edit user details, change role/department, deactivate user
class EditUserScreen extends StatefulWidget {
  final UserModel user;

  const EditUserScreen({super.key, required this.user});

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  // Design colors
  static const Color kDark = Color(0xFF0F172A);
  static const Color kGrey = Color(0xFF64748B);
  static const Color kAccent = Color(0xFF3B82F6);
  static const Color kGreen = Color(0xFF10B981);
  static const Color kRed = Color(0xFFEF4444);

  // Form state
  late TextEditingController _nameController;
  late UserRole _selectedRole;
  late String _selectedDepartment;
  late bool _isActive;
  bool _isLoading = false;
  bool _hasChanges = false;

  final _userService = UserService();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
    _selectedRole = widget.user.role;
    _selectedDepartment = widget.user.department;
    _isActive = widget.user.isActive;

    _nameController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    final hasChanges = _nameController.text != widget.user.displayName ||
        _selectedRole != widget.user.role ||
        _selectedDepartment != widget.user.department ||
        _isActive != widget.user.isActive;

    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Name cannot be empty', style: GoogleFonts.sora()),
          backgroundColor: kRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (!AuthService.firebaseInitialized) {
        // Dummy mode
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Demo mode: Changes would be saved',
                style: GoogleFonts.sora(),
              ),
              backgroundColor: kGreen,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      await _userService.updateUser(
        uid: widget.user.uid,
        displayName: _nameController.text.trim(),
        role: _selectedRole,
        department: _selectedDepartment,
        isActive: _isActive,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User updated successfully', style: GoogleFonts.sora()),
            backgroundColor: kGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: GoogleFonts.sora(),
            ),
            backgroundColor: kRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showDeactivateDialog() {
    final action = _isActive ? 'Deactivate' : 'Reactivate';
    final message = _isActive
        ? 'This user will no longer be able to log in to the application.'
        : 'This user will be able to log in again.';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          '$action User?',
          style: GoogleFonts.sora(fontWeight: FontWeight.w700, color: kDark),
        ),
        content: Text(
          message,
          style: GoogleFonts.sora(color: kGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.sora(color: kGrey, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isActive = !_isActive;
                _checkForChanges();
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _isActive ? kRed : kGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              action,
              style: GoogleFonts.sora(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
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
          'Edit User',
          style: GoogleFonts.sora(
            color: kDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_hasChanges)
            TextButton(
              onPressed: _isLoading ? null : _saveChanges,
              child: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Save',
                      style: GoogleFonts.sora(
                        color: kAccent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User header card
            _buildUserHeader(),
            const SizedBox(height: 24),

            // Status banner (if inactive)
            if (!_isActive) _buildInactiveBanner(),
            if (!_isActive) const SizedBox(height: 24),

            // Name field
            _buildLabel('Display Name'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _nameController,
              hint: 'Enter name',
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 20),

            // Email (read-only)
            _buildLabel('Email Address'),
            const SizedBox(height: 8),
            _buildReadOnlyField(
              value: widget.user.email,
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 20),

            // Role dropdown
            _buildLabel('Role'),
            const SizedBox(height: 8),
            _buildDropdown<UserRole>(
              value: _selectedRole,
              items: UserRole.values.map((role) => DropdownMenuItem(
                value: role,
                child: Text(role.displayName),
              )).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedRole = value);
                  _checkForChanges();
                }
              },
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 20),

            // Department dropdown
            _buildLabel('Department'),
            const SizedBox(height: 8),
            _buildDropdown<String>(
              value: _selectedDepartment,
              items: Departments.all.map((dept) => DropdownMenuItem(
                value: dept,
                child: Text(dept),
              )).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedDepartment = value);
                  _checkForChanges();
                }
              },
              icon: Icons.business_outlined,
            ),
            const SizedBox(height: 32),

            // Deactivate/Reactivate button
            _buildActionButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader() {
    final roleColor = _getRoleColor(widget.user.role);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                widget.user.displayName.isNotEmpty
                    ? widget.user.displayName[0].toUpperCase()
                    : '?',
                style: GoogleFonts.sora(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: roleColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.displayName,
                  style: GoogleFonts.sora(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: kDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.user.email,
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    color: kGrey,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _isActive ? kGreen.withOpacity(0.1) : kRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _isActive ? 'Active' : 'Inactive',
                        style: GoogleFonts.sora(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _isActive ? kGreen : kRed,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInactiveBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kRed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_rounded, color: kRed, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'This user is deactivated and cannot log in.',
              style: GoogleFonts.sora(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: kRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.sora(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: kDark,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.sora(fontSize: 14, color: kDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.sora(color: kGrey.withOpacity(0.5), fontSize: 14),
        prefixIcon: Icon(icon, color: kGrey, size: 20),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
    );
  }

  Widget _buildReadOnlyField({
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Icon(icon, color: kGrey.withOpacity(0.5), size: 20),
          const SizedBox(width: 12),
          Text(
            value,
            style: GoogleFonts.sora(
              fontSize: 14,
              color: kGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items: items,
        onChanged: onChanged,
        style: GoogleFonts.sora(fontSize: 14, color: kDark),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: kGrey, size: 20),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: InputBorder.none,
        ),
        icon: const Icon(Icons.arrow_drop_down, color: kGrey),
        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _showDeactivateDialog,
        icon: Icon(
          _isActive ? Icons.block : Icons.check_circle_outline,
          size: 20,
        ),
        label: Text(
          _isActive ? 'Deactivate User' : 'Reactivate User',
          style: GoogleFonts.sora(fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: _isActive ? kRed : kGreen,
          side: BorderSide(color: _isActive ? kRed : kGreen),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.systemAdmin:
        return const Color(0xFF8B5CF6);
      case UserRole.manager:
        return kAccent;
      case UserRole.staff:
        return kGreen;
    }
  }
}
