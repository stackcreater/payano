import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/models/user_model.dart';

class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  const OtpScreen({super.key, required this.phone});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  int _resendCountdown = 30;
  Timer? _timer;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _resendCountdown = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        _timer?.cancel();
      }
    });
  }

  void _verifyOtp() async {
    final otpStr = _controllers.map((c) => c.text).join();
    if (otpStr.length < 6) {
      setState(() => _errorMessage = 'Please enter complete 6-digit OTP code');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = ref.read(authServiceProvider);
    try {
      final user = await authService.verifyOtp(
        widget.phone,
        otpStr,
        role: authService.currentUser?.role ?? UserRole.rider,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (user.role == UserRole.driver) {
          if (user.verificationStatus == 'unverified') {
            context.go('/driver/onboarding');
          } else {
            context.go('/driver/home');
          }
        } else {
          if (!user.profileSetupCompleted) {
            context.go('/profile-setup');
          } else if (user.studentVerificationStatus == 'unverified') {
            context.go('/student-verification');
          } else {
            context.go('/home');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Verification'),
      ),
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Verify Phone Number',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter 6-digit code sent to ${widget.phone}',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 32),

              // 6 PIN Input Boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (index) => SizedBox(
                    width: 48,
                    height: 56,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.borderSm,
                          borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.borderSm,
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      onChanged: (val) {
                        if (val.isNotEmpty && index < 5) {
                          _focusNodes[index + 1].requestFocus();
                        } else if (val.isEmpty && index > 0) {
                          _focusNodes[index - 1].requestFocus();
                        }
                        if (_controllers.map((c) => c.text).join().length == 6) {
                          _verifyOtp();
                        }
                      },
                    ),
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
              ],

              const SizedBox(height: 28),

              // Timer / Resend Code
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _resendCountdown > 0
                        ? 'Resend OTP in 0:${_resendCountdown.toString().padLeft(2, '0')}'
                        : "Didn't receive code? ",
                    style: TextStyle(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                  if (_resendCountdown == 0)
                    GestureDetector(
                      onTap: _startCountdown,
                      child: const Text(
                        'Resend OTP',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),

              const Spacer(),
              AppButton(
                text: 'Verify & Continue',
                isLoading: _isLoading,
                onPressed: _verifyOtp,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
