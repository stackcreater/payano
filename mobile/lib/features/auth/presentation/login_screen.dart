import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  UserRole _selectedRole = UserRole.rider;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Strict verification-based routing:
  /// - Passenger: Must complete student verification -> Passenger Dashboard (/home)
  /// - Driver: Must complete Student Verification AND Driver Onboarding (License & Vehicle) -> Driver Dashboard (/driver/home)
  /// - Admin: -> Admin Portal (/admin)
  void _navigateByRole(
    UserRole role, {
    String? verificationStatus,
    bool profileSetupCompleted = true,
    String? studentVerificationStatus,
  }) {
    if (role == UserRole.admin) {
      context.go('/admin');
      return;
    }

    final isStudentVerified = (studentVerificationStatus == 'verified');
    final isDriverVerified = (verificationStatus == 'verified');

    if (role == UserRole.rider) {
      if (!isStudentVerified) {
        context.go('/student-verification');
      } else {
        context.go('/home');
      }
      return;
    }

    if (role == UserRole.driver) {
      if (!isStudentVerified) {
        context.go('/student-verification');
      } else if (!isDriverVerified) {
        context.go('/driver/onboarding');
      } else {
        context.go('/driver/home');
      }
      return;
    }
  }

  void _handleContinue() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text.trim();

    if (identifier.isEmpty) {
      setState(() => _errorMessage = 'Please enter your username, email, or mobile');
      return;
    }
    if (password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserModel? user;
      try {
        user = await ref.read(authServiceProvider).directLogin(
          username: identifier,
          password: password,
          role: _selectedRole,
        );
      } catch (e) {
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('invalid password') || errStr.contains('401')) {
          throw Exception('Invalid password. Please try again.');
        }

        // Auto-signup with user credentials if account does not exist
        user = await ref.read(authServiceProvider).directSignup(
          username: identifier.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '').toLowerCase(),
          name: identifier,
          phone: identifier.contains('@') ? '+919876543210' : (identifier.length >= 10 ? identifier : '+91$identifier'),
          password: password,
          role: _selectedRole,
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);
        _navigateByRole(
          user.role,
          verificationStatus: user.verificationStatus,
          profileSetupCompleted: user.profileSetupCompleted,
          studentVerificationStatus: user.studentVerificationStatus,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '').trim();
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await ref.read(authServiceProvider).signInWithGoogle(role: _selectedRole);
      if (mounted) {
        setState(() => _isLoading = false);
        if (user != null) {
          _navigateByRole(
            user.role,
            verificationStatus: user.verificationStatus,
            profileSetupCompleted: user.profileSetupCompleted,
            studentVerificationStatus: user.studentVerificationStatus,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '').split(']').last.trim();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Back button ──
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 8),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    if (context.canPop()) context.pop();
                  },
                ),
              ),

              // ── Hero section: text left, illustration right ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Brand + title + subtitle
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // PAYANO brand
                          const Text(
                            'PAYANO',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2563EB),
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Big heading
                          const Text(
                            'Welcome\nto Payano',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Sign in with your email or\nmobile number to access\ncampus rides and continue\nyour journey.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Right: Illustration circle
                    Expanded(
                      flex: 4,
                      child: Container(
                        height: size.width * 0.42,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8EFF8),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.two_wheeler,
                            size: size.width * 0.22,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ── Role toggle (Passenger / Driver) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _roleTab('Passenger', UserRole.rider),
                      _roleTab('Driver', UserRole.driver),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── Username / Email / Mobile field ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _identifierController,
                    keyboardType: TextInputType.text,
                    decoration: InputDecoration(
                      hintText: _selectedRole == UserRole.driver
                          ? 'Username or Mobile Number'
                          : 'Username, Email, or Mobile',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                      prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF2563EB), size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Password field ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Enter Password',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 15),
                      prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2563EB), size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: const Color(0xFF94A3B8),
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── Verification requirement badge ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _selectedRole == UserRole.driver ? Icons.security : Icons.school_outlined,
                        size: 16,
                        color: const Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _selectedRole == UserRole.driver
                              ? 'Driver: Student ID + License & Vehicle verification required'
                              : 'Passenger: Student ID verification required',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1D4ED8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Error message (fixed slot — prevents layout jump) ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: _errorMessage != null
                      ? Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFFECACA)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),


              const SizedBox(height: 20),

              // ── Continue button ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ── OR divider ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Text('Or', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Continue with Google ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _handleGoogleSignIn,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF4285F4),
                          ),
                          child: const Icon(Icons.g_mobiledata, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Continue with Google',
                          style: TextStyle(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Sign Up link ──
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/signup'),
                  child: RichText(
                    text: const TextSpan(
                      text: "Don't have an account? ",
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Sign Up',
                          style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Terms ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    text: 'By continuing, you agree to our ',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                    children: [
                      TextSpan(text: 'Terms of Service', style: TextStyle(color: Color(0xFF2563EB))),
                      TextSpan(text: ' and '),
                      TextSpan(text: 'Privacy Policy', style: TextStyle(color: Color(0xFF2563EB))),
                      TextSpan(text: '.'),
                    ],
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

  Widget _roleTab(String label, UserRole role) {
    final selected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : Colors.black54,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
