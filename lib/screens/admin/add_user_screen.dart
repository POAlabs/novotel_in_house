import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../config/departments.dart';
import '../../services/user_service.dart';
import '../../services/auth_service.dart';
import '../../services/debug_log_service.dart';

/// Add User Screen
/// Form to add a new user to the system
class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  // Design colors
  static const Color kDark = Color(0xFF0F172A);
  static const Color kGrey = Color(0xFF64748B);
  static const Color kAccent = Color(0xFF3B82F6);
  static const Color kGreen = Color(0xFF10B981);
  static const Color kRed = Color(0xFFEF4444);

  // Form state
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  UserRole _selectedRole = UserRole.staff;
  String _selectedDepartment = Departments.engineering;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final _userService = UserService();
  final _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _addUser() async {
    debugPrint('\n🟦 [ADD_USER_SCREEN] Form submission started');
    DebugLogService().addLog('ADD_USER_SCREEN', 'Add user button clicked');
    
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ [ADD_USER_SCREEN] Form validation failed');
      DebugLogService().addLog(
        'ADD_USER_SCREEN',
        'Form validation failed',
        isError: true,
      );
      return;
    }

    debugPrint('✅ [ADD_USER_SCREEN] Form validation passed');
    setState(() => _isLoading = true);

    try {
      debugPrint('🟦 [ADD_USER_SCREEN] Checking Firebase initialization status');
      // Check if Firebase is initialized
      if (!AuthService.firebaseInitialized) {
        debugPrint('⚠️  [ADD_USER_SCREEN] Firebase not initialized - running in demo mode');
        DebugLogService().addLog(
          'ADD_USER_SCREEN',
          'Firebase not initialized - demo mode',
          data: {'userName': _nameController.text},
        );
        // Dummy mode - just show success
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Demo mode: User "${_nameController.text}" would be added',
                style: GoogleFonts.sora(),
              ),
              backgroundColor: kGreen,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      debugPrint('✅ [ADD_USER_SCREEN] Firebase is initialized');
      debugPrint('🟦 [ADD_USER_SCREEN] Getting current admin user');
      
      // Get current admin's UID
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        debugPrint('❌ [ADD_USER_SCREEN] No current user found - not logged in');
        DebugLogService().addLog(
          'ADD_USER_SCREEN',
          'No current user - not logged in',
          isError: true,
        );
        throw Exception('You must be logged in to add users');
      }

      debugPrint('✅ [ADD_USER_SCREEN] Current user: ${currentUser.email} (${currentUser.uid})');
      debugPrint('🟦 [ADD_USER_SCREEN] Preparing user data:');
      debugPrint('   - Email: ${_emailController.text.trim()}');
      debugPrint('   - Name: ${_nameController.text.trim()}');
      debugPrint('   - Role: ${_selectedRole.displayName}');
      debugPrint('   - Department: $_selectedDepartment');
      debugPrint('   - Password length: ${_passwordController.text.length}');
      
      DebugLogService().addLog(
        'ADD_USER_SCREEN',
        'Calling UserService.addUser',
        data: {
          'email': _emailController.text.trim(),
          'displayName': _nameController.text.trim(),
          'role': _selectedRole.displayName,
          'department': _selectedDepartment,
          'createdBy': currentUser.uid,
        },
      );

      // Add user via service
      debugPrint('🟦 [ADD_USER_SCREEN] Calling UserService.addUser()...');
      await _userService.addUser(
        email: _emailController.text.trim(),
        displayName: _nameController.text.trim(),
        role: _selectedRole,
        department: _selectedDepartment,
        temporaryPassword: _passwordController.text,
        createdByUid: currentUser.uid,
      );

      debugPrint('✅ [ADD_USER_SCREEN] User added successfully!');
      DebugLogService().addLog(
        'ADD_USER_SCREEN',
        'User added successfully',
        data: {'email': _emailController.text.trim()},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'User added successfully',
              style: GoogleFonts.sora(),
            ),
            backgroundColor: kGreen,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [ADD_USER_SCREEN] Error occurred during user creation');
      debugPrint('   Error: $e');
      debugPrint('   Stack trace: $stackTrace');
      
      DebugLogService().addLog(
        'ADD_USER_SCREEN',
        'Failed to add user: $e',
        data: {
          'email': _emailController.text.trim(),
          'error': e.toString(),
          'stackTrace': stackTrace.toString(),
        },
        isError: true,
      );
      
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
      debugPrint('🟦 [ADD_USER_SCREEN] Add user operation completed\n');
    }
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
          'Add New User',
          style: GoogleFonts.sora(
            color: kDark,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info banner
              _buildInfoBanner(),
              const SizedBox(height: 24),

              // Email field
              _buildLabel('Email Address'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _emailController,
                hint: 'user@novotel.com',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Email is required';
                  }
                  if (!value.contains('@') || !value.contains('.')) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Name field
              _buildLabel('Display Name'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _nameController,
                hint: 'John Doe',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Password field
              _buildLabel('Temporary Password'),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _passwordController,
                hint: 'At least 6 characters',
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: kGrey,
                    size: 20,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Password is required';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
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
                  }
                },
                icon: Icons.business_outlined,
              ),
              const SizedBox(height: 32),

              // Add button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Add User',
                          style: GoogleFonts.sora(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: kAccent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_outline, color: kAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New User Setup',
                  style: GoogleFonts.sora(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: kDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'User will receive login credentials via email. They can change their password after first login.',
                  style: GoogleFonts.sora(
                    fontSize: 11,
                    color: kGrey,
                  ),
                ),
              ],
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
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: GoogleFonts.sora(fontSize: 14, color: kDark),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.sora(color: kGrey.withOpacity(0.5), fontSize: 14),
        prefixIcon: Icon(icon, color: kGrey, size: 20),
        suffixIcon: suffixIcon,
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kRed, width: 2),
        ),
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
}
