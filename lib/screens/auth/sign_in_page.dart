import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../config/routes.dart';

/// Sign-in page for user authentication
class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();
  
  // Text controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  // State variables
  bool _obscurePassword = true;
  bool _isLoading = false;
  
  // Services
  final _authService = AuthService();
  
  // Brand colors
  static const Color kDark = Color(0xFF0F172A);
  static const Color kAccent = Color(0xFF3B82F6);
  static const Color kGrey = Color(0xFF64748B);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Handle sign-in button press
  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final role = await _authService.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      String route;
      switch (role) {
        case 'admin':
          route = AppRoutes.adminDashboard;
          break;
        case 'manager':
          route = AppRoutes.managerDashboard;
          break;
        default:
          route = AppRoutes.employeeDashboard;
      }

      Navigator.pushReplacementNamed(context, route);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: \${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 40),
                  _buildForm(),
                  const SizedBox(height: 24),
                  _buildHelpText(),
                  const SizedBox(height: 32),
                  _buildDevCredentials(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Header with logo and title
  Widget _buildHeader() {
    return Column(
      children: [
        // Logo icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: kAccent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.business_rounded,
            color: kAccent,
            size: 36,
          ),
        ),
        const SizedBox(height: 24),
        // Title
        const Text(
          'Novotel Westlands',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: kDark,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'In-House Operations',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: kGrey.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  /// Sign-in form with light theme inputs
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Email label
          const Text(
            'Email',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kDark),
          ),
          const SizedBox(height: 8),
          // Email field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: const TextStyle(fontSize: 15, color: kDark),
            decoration: _inputDecoration(
              hint: 'Enter your email',
              icon: Icons.email_outlined,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your email';
              }
              if (!value.contains('@')) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          
          // Password label
          const Text(
            'Password',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kDark),
          ),
          const SizedBox(height: 8),
          // Password field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            style: const TextStyle(fontSize: 15, color: kDark),
            decoration: _inputDecoration(
              hint: 'Enter your password',
              icon: Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: kGrey,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 28),
          
          // Sign in button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
              style: ElevatedButton.styleFrom(
                backgroundColor: kDark,
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
                  : const Text(
                      'Sign In',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Input decoration for text fields
  InputDecoration _inputDecoration({required String hint, required IconData icon, Widget? suffixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: kGrey.withOpacity(0.5), fontSize: 14),
      prefixIcon: Icon(icon, color: kGrey, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
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
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  /// Help text
  Widget _buildHelpText() {
    return Text(
      'Contact IT Office if you need access',
      style: TextStyle(
        color: kGrey.withOpacity(0.7),
        fontSize: 13,
      ),
    );
  }

  /// Development credentials
  Widget _buildDevCredentials() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE68A),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.code, color: Color(0xFFB45309), size: 14),
              ),
              const SizedBox(width: 10),
              const Text(
                'Development Mode',
                style: TextStyle(
                  color: Color(0xFFB45309),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _credentialRow('Admin', 'admin@novotel.com'),
          const SizedBox(height: 6),
          _credentialRow('Manager', 'manager@novotel.com'),
          const SizedBox(height: 6),
          _credentialRow('Employee', 'employee@novotel.com'),
          const SizedBox(height: 8),
          Text(
            'Password: password123',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  /// Credential row
  Widget _credentialRow(String role, String email) {
    return Row(
      children: [
        SizedBox(
          width: 65,
          child: Text(
            role,
            style: const TextStyle(
              color: Color(0xFF92400E),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          email,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
