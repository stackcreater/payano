import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/user_model.dart';
import '../../../core/services/auth_service.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  UserRole _selectedRole = UserRole.rider;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final phoneText = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessage = 'Please enter your full name');
      return;
    }
    if (email.isNotEmpty && !RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$').hasMatch(email)) {
      setState(() => _errorMessage = 'Please enter a valid email address');
      return;
    }
    if (phoneText.length < 10) {
      setState(() => _errorMessage = 'Please enter a valid mobile number');
      return;
    }
    if (password.length < 6) {
      setState(() => _errorMessage = 'Password must be at least 6 characters');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final fullPhone = phoneText.startsWith('+') ? phoneText : '+91$phoneText';

    try {
      final user = await ref.read(authServiceProvider).directSignup(
        username: phoneText,
        name: name,
        phone: fullPhone,
        password: password,
        email: email,
        role: _selectedRole,
      );

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

  Widget _roleTab(String label, UserRole role) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final user = await ref.read(authServiceProvider).signInWithGoogle(role: UserRole.rider);
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

              // ── Hero section ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          const Text(
                            'Create your\naccount',
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Join Payano with your email\nand mobile number to start\nbooking campus rides.',
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
                            Icons.person_add_alt_1,
                            size: size.width * 0.18,
                            color: const Color(0xFF2563EB),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

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

              // ── Full Name field ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Full Name',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15),
                        decoration: const InputDecoration(
                          hintText: 'Enter your full name',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                          prefixIcon: Icon(Icons.person_outline, color: Color(0xFF2563EB), size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Email field ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email Address (Optional)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15),
                        decoration: const InputDecoration(
                          hintText: 'Enter your email address',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                          prefixIcon: Icon(Icons.email_outlined, color: Color(0xFF2563EB), size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Used for receipts and account notifications.',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Mobile Number field ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mobile Number',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15),
                        decoration: const InputDecoration(
                          hintText: 'Enter 10-digit mobile number',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                          prefixIcon: Icon(Icons.phone_outlined, color: Color(0xFF2563EB), size: 20),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Password field ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 15),
                        decoration: InputDecoration(
                          hintText: 'Create a secure password',
                          hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
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
                          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // ── Role verification requirement badge ──
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

              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
              ],

              const SizedBox(height: 24),

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

              // ── Log In link ──
              Center(
                child: GestureDetector(
                  onTap: () => context.go('/login'),
                  child: RichText(
                    text: const TextSpan(
                      text: "Already have an account? ",
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                      children: [
                        TextSpan(
                          text: 'Log In',
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
                      TextSpan(text: 'Terms of Service\n', style: TextStyle(color: Color(0xFF2563EB))),
                      TextSpan(text: 'and '),
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
}
