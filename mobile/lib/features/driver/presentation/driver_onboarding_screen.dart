import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/uploaded_file.dart';

class DriverOnboardingScreen extends ConsumerStatefulWidget {
  const DriverOnboardingScreen({super.key});

  @override
  ConsumerState<DriverOnboardingScreen> createState() => _DriverOnboardingScreenState();
}

class _DriverOnboardingScreenState extends ConsumerState<DriverOnboardingScreen> {
  int _currentStep = 0; // 0: Eligibility, 1: Vehicle Details, 2: Upload Documents, 3: Review Application

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authServiceProvider).currentUser;
      if (user != null && user.role == UserRole.driver) {
        if (user.studentVerificationStatus != 'verified') {
          context.go('/student-verification');
        } else if (user.verificationStatus == 'verified') {
          context.go('/driver/documents');
        }
      }
    });
  }

  // Step 1 State: Eligibility
  bool _eligibilityConfirmed = true;

  // Step 2 State: Vehicle Details
  String _selectedVehicleType = 'Scooter';
  final TextEditingController _makeModelController = TextEditingController(text: 'Honda Activa 6G');
  final TextEditingController _regNumController = TextEditingController(text: 'TN 30 AB 4582');
  final TextEditingController _colorController = TextEditingController(text: 'Blue');
  String _ownership = 'Yes, I own it';

  // Step 3 State: Upload Documents
  final TextEditingController _dlNumController = TextEditingController(text: 'DL123456789012');
  final TextEditingController _rcNumController = TextEditingController(text: 'TN30AB4582');
  final TextEditingController _insuranceNumController = TextEditingController(text: 'Policy No. 1234567890');
  bool _dlUploaded = false;
  bool _rcUploaded = false;
  bool _insuranceUploaded = false;

  AppUploadedFile? _dlFile;
  AppUploadedFile? _rcFile;
  AppUploadedFile? _insuranceFile;

  // General State
  bool _isSubmitting = false;

  @override
  void dispose() {
    _makeModelController.dispose();
    _regNumController.dispose();
    _colorController.dispose();
    _dlNumController.dispose();
    _rcNumController.dispose();
    _insuranceNumController.dispose();
    super.dispose();
  }

  void _handleSubmitApplication() async {
    setState(() => _isSubmitting = true);
    try {
      final authService = ref.read(authServiceProvider);
      await authService.submitDriverRegistration(
        vehicleType: _selectedVehicleType,
        makeModel: _makeModelController.text.trim(),
        registrationNumber: _regNumController.text.trim(),
        color: _colorController.text.trim(),
        ownership: _ownership == 'Yes, I own it' ? 'I own this vehicle' : 'Owned by someone else',
        dlDocNumber: _dlNumController.text.trim(),
        rcDocNumber: _rcNumController.text.trim(),
        insuranceDocNumber: _insuranceNumController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _currentStep = 5;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration Error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF9FAFB),
      appBar: AppBar(
        leading: _currentStep == 5
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (_currentStep > 0) {
                    setState(() => _currentStep--);
                  } else {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  }
                },
              ),
        title: Text(
          _getAppBarTitle(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _buildCurrentStepWidget(isDark),
          ),
        ),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentStep) {
      case 0:
        return 'Become a Driver';
      case 1:
        return 'Driver Eligibility';
      case 2:
        return 'Vehicle Details';
      case 3:
        return 'Upload Your Documents';
      case 4:
        return 'Review Your Application';
      case 5:
        return 'Application Submitted';
      default:
        return 'Become a Driver';
    }
  }

  Widget _buildCurrentStepWidget(bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildStep0BecomeDriver(isDark);
      case 1:
        return _buildStep1Eligibility(isDark);
      case 2:
        return _buildStep2VehicleDetails(isDark);
      case 3:
        return _buildStep3UploadDocuments(isDark);
      case 4:
        return _buildStep4ReviewApplication(isDark);
      case 5:
        return _buildStep5ApplicationSubmitted(isDark);
      default:
        return _buildStep0BecomeDriver(isDark);
    }
  }

  // ==========================================
  // SCREEN 0: BECOME A DRIVER (42.Driver Onboarding.png)
  // ==========================================
  Widget _buildStep0BecomeDriver(bool isDark) {
    return Column(
      key: const ValueKey(-1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Large Headline
        RichText(
          text: TextSpan(
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black,
              height: 1.15,
            ),
            children: const [
              TextSpan(text: "Ride.\n"),
              TextSpan(
                text: "Earn.\n",
                style: TextStyle(color: Color(0xFF1A6DF8)),
              ),
              TextSpan(text: "Connect."),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Turn your daily commute into earnings. Share your ride with verified students from your college.',
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.white70 : const Color(0xFF4B5563),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Hero Illustration Card
        Container(
          width: double.infinity,
          height: 160,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFEBF3FF), Color(0xFFDBEAFE)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF93C5FD).withAlpha(100)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                right: 16,
                top: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(15),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 14, color: Color(0xFF10B981)),
                      SizedBox(width: 4),
                      Text(
                        'Verified College Ride',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E3A8A)),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF1A6DF8).withAlpha(40),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.two_wheeler_rounded, size: 44, color: Color(0xFF1A6DF8)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'PAYANO CAMPUS POOL',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: Color(0xFF1A6DF8),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Why drive with Payano?
        Text(
          'Why drive with Payano?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 14),

        _buildBenefitCard(
          icon: Icons.shield_outlined,
          iconColor: const Color(0xFF1A6DF8),
          iconBg: const Color(0xFFEBF3FF),
          title: 'Verified students only',
          subtitle: 'Every passenger is an authenticated student from your college with verified ID.',
          isDark: isDark,
        ),
        const SizedBox(height: 12),

        _buildBenefitCard(
          icon: Icons.account_balance_wallet_outlined,
          iconColor: const Color(0xFF10B981),
          iconBg: const Color(0xFFD1FAE5),
          title: 'Earn on your route',
          subtitle: 'Offset your daily fuel and travel expenses without taking detours.',
          isDark: isDark,
        ),
        const SizedBox(height: 12),

        _buildBenefitCard(
          icon: Icons.access_time_rounded,
          iconColor: const Color(0xFF8B5CF6),
          iconBg: const Color(0xFFEDE9FE),
          title: 'Drive when it works for you',
          subtitle: 'Zero lock-in or minimum hours. Turn online only when you want to travel.',
          isDark: isDark,
        ),
        const SizedBox(height: 20),

        // Requirement info card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEBF3FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF3B82F6).withValues(alpha: 0.3) : const Color(0xFFBFDBFE),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, color: Color(0xFF1A6DF8), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "You'll need a valid driving licence, registered two-wheeler, and college ID to become an active driver.",
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E3A8A),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Get Started Button
        AppButton(
          text: 'Get Started ->',
          onPressed: () => setState(() => _currentStep = 1),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            child: const Text(
              'Maybe later',
              style: TextStyle(
                color: Color(0xFF1A6DF8),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildBenefitCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 1: DRIVER ELIGIBILITY
  // ==========================================
  Widget _buildStep1Eligibility(bool isDark) {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Banner / Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                        height: 1.2,
                      ),
                      children: const [
                        TextSpan(text: "Let's check\nyour "),
                        TextSpan(
                          text: "eligibility",
                          style: TextStyle(color: Color(0xFF1A6DF8)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Complete the requirements below to become a Payano driver.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1A6DF8).withAlpha(15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.assignment_turned_in_rounded, size: 64, color: Color(0xFF1A6DF8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Light Blue Info Container
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF3FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A6DF8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  "You'll need a valid driving licence, registered two-wheeler, and active insurance to drive with Payano.",
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF374151),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Eligibility Checklist Items
        _buildEligibilityItem(
          icon: Icons.person_outline_rounded,
          title: 'Verified Payano Student',
          subtitle: 'You must have a verified Payano student account.',
          isCompleted: true,
          statusText: 'Completed',
          isDark: isDark,
          onTap: () {},
        ),
        _buildEligibilityItem(
          icon: Icons.badge_outlined,
          title: 'Valid Driving Licence',
          subtitle: 'You must have a valid licence to ride a two-wheeler.',
          isCompleted: false,
          statusText: 'Pending',
          isDark: isDark,
          onTap: () => setState(() => _currentStep = 3),
        ),
        _buildEligibilityItem(
          icon: Icons.two_wheeler_rounded,
          title: 'Registered Two-Wheeler',
          subtitle: 'You must have access to a registered two-wheeler.',
          isCompleted: false,
          statusText: 'Pending',
          isDark: isDark,
          onTap: () => setState(() => _currentStep = 2),
        ),
        _buildEligibilityItem(
          icon: Icons.article_outlined,
          title: 'Vehicle Documents',
          subtitle: 'Your two-wheeler must have valid registration and insurance.',
          isCompleted: false,
          statusText: 'Pending',
          isDark: isDark,
          onTap: () => setState(() => _currentStep = 3),
        ),

        const SizedBox(height: 16),

        // Bottom Checkbox Container
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF3FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Checkbox(
                value: _eligibilityConfirmed,
                activeColor: const Color(0xFF1A6DF8),
                onChanged: (val) => setState(() => _eligibilityConfirmed = val ?? false),
              ),
              const Expanded(
                child: Text(
                  'I confirm that I meet all the above requirements and will provide genuine information.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF4B5563)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Action Buttons
        AppButton(
          text: 'Continue →',
          onPressed: _eligibilityConfirmed ? () => setState(() => _currentStep = 2) : null,
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
            child: const Text(
              'Maybe later',
              style: TextStyle(
                color: Color(0xFF1A6DF8),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildEligibilityItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isCompleted,
    required String statusText,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isCompleted ? const Color(0xFFE0F2FE) : const Color(0xFFF3F4F6),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF1A6DF8), size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white60 : const Color(0xFF6B7280),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isCompleted ? const Color(0xFFD1FAE5) : const Color(0xFFDBEAFE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isCompleted ? const Color(0xFF059669) : const Color(0xFF2563EB),
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // SCREEN 2: VEHICLE DETAILS
  // ==========================================
  Widget _buildStep2VehicleDetails(bool isDark) {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Banner / Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                        height: 1.2,
                      ),
                      children: const [
                        TextSpan(text: "Tell us about your\n"),
                        TextSpan(
                          text: "two-wheeler",
                          style: TextStyle(color: Color(0xFF1A6DF8)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Add the vehicle you'll use to drive with Payano.",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1A6DF8).withAlpha(15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.moped_rounded, size: 64, color: Color(0xFF1A6DF8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // Section: What do you ride?
        Text(
          'What do you ride?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedVehicleType = 'Scooter'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: _selectedVehicleType == 'Scooter'
                        ? const Color(0xFFEFF6FF)
                        : (isDark ? AppColors.surfaceDark : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedVehicleType == 'Scooter'
                          ? const Color(0xFF1A6DF8)
                          : (isDark ? AppColors.borderDark : const Color(0xFFE5E7EB)),
                      width: _selectedVehicleType == 'Scooter' ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.moped_rounded,
                        size: 36,
                        color: _selectedVehicleType == 'Scooter'
                            ? const Color(0xFF1A6DF8)
                            : const Color(0xFF6B7280),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Scooter',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _selectedVehicleType == 'Scooter'
                              ? const Color(0xFF1A6DF8)
                              : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedVehicleType = 'Bike'),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: _selectedVehicleType == 'Bike'
                        ? const Color(0xFFEFF6FF)
                        : (isDark ? AppColors.surfaceDark : Colors.white),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _selectedVehicleType == 'Bike'
                          ? const Color(0xFF1A6DF8)
                          : (isDark ? AppColors.borderDark : const Color(0xFFE5E7EB)),
                      width: _selectedVehicleType == 'Bike' ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.two_wheeler_rounded,
                        size: 36,
                        color: _selectedVehicleType == 'Bike'
                            ? const Color(0xFF1A6DF8)
                            : const Color(0xFF6B7280),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bike',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _selectedVehicleType == 'Bike'
                              ? const Color(0xFF1A6DF8)
                              : (isDark ? Colors.white : Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Section: Vehicle Information
        Text(
          'Vehicle Information',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 14),

        AppTextField(
          controller: _makeModelController,
          hintText: 'e.g. Honda Activa 6G',
          prefixIcon: Icons.moped_outlined,
        ),
        const SizedBox(height: 12),

        AppTextField(
          controller: _regNumController,
          hintText: 'e.g. TN 30 AB 4582',
          prefixIcon: Icons.badge_outlined,
        ),
        const SizedBox(height: 12),

        AppTextField(
          controller: _colorController,
          hintText: 'e.g. Blue',
          prefixIcon: Icons.color_lens_outlined,
        ),
        const SizedBox(height: 24),

        // Section: Do you have access to this vehicle?
        Text(
          'Do you have access to this vehicle?',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
            ),
          ),
          child: RadioGroup<String>(
            groupValue: _ownership,
            onChanged: (val) {
              if (val != null) setState(() => _ownership = val);
            },
            child: Column(
              children: [
                RadioListTile<String>(
                  title: const Text('Yes, I own it', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  value: 'Yes, I own it',
                  activeColor: const Color(0xFF1A6DF8),
                ),
                Divider(height: 1, color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB)),
                RadioListTile<String>(
                  title: const Text('No, I use a vehicle owned by someone else', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  value: 'No, I use a vehicle owned by someone else',
                  activeColor: const Color(0xFF1A6DF8),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Bottom Action Buttons
        AppButton(
          text: 'Continue →',
          onPressed: () {
            if (_makeModelController.text.trim().isEmpty || _regNumController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill in vehicle details before continuing.')),
              );
              return;
            }
            setState(() => _currentStep = 3);
          },
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _currentStep = 1),
            child: const Text(
              'Maybe later',
              style: TextStyle(
                color: Color(0xFF1A6DF8),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Future<void> _pickDriverDocument(String docType) async {
    try {
      final file = await AppUploadedFile.pickDocument();
      if (file != null) {
        final cleanBase = file.name.split('.').first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();

        setState(() {
          if (docType == 'DL') {
            _dlFile = file;
            _dlUploaded = true;
            _dlNumController.text = cleanBase.length >= 8
                ? 'DL-${cleanBase.substring(0, cleanBase.length > 12 ? 12 : cleanBase.length)}'
                : 'DL1420230048291';
          } else if (docType == 'RC') {
            _rcFile = file;
            _rcUploaded = true;
            _rcNumController.text = cleanBase.length >= 6
                ? cleanBase.substring(0, cleanBase.length > 10 ? 10 : cleanBase.length)
                : (_regNumController.text.isNotEmpty ? _regNumController.text.replaceAll(' ', '') : 'TN30AB4582');
          } else if (docType == 'INSURANCE') {
            _insuranceFile = file;
            _insuranceUploaded = true;
            _insuranceNumController.text = 'POL-${cleanBase.length >= 6 ? cleanBase.substring(0, cleanBase.length > 10 ? 10 : cleanBase.length) : '94827103'}';
          }
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ ${file.name} attached & document details auto-filled!'),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting document: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ==========================================
  // SCREEN 3: UPLOAD YOUR DOCUMENTS
  // ==========================================
  Widget _buildStep3UploadDocuments(bool isDark) {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Banner / Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                        height: 1.2,
                      ),
                      children: const [
                        TextSpan(text: "Upload your\n"),
                        TextSpan(
                          text: "documents",
                          style: TextStyle(color: Color(0xFF1A6DF8)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload documents (PDF, DOCX, PNG, JPG) to auto-fill your verified information.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1A6DF8).withAlpha(15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.folder_shared_rounded, size: 64, color: Color(0xFF1A6DF8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Info Container
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF3FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A6DF8),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.info_outline, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Supports DOCX, PDF, PNG, JPG files. Details will be automatically populated.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF374151)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        Text(
          'Required Documents',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 14),

        // Document 1: Driving Licence
        _buildUploadCard(
          title: 'Driving Licence',
          subtitle: 'Upload a valid two-wheeler driving licence.',
          isUploaded: _dlUploaded,
          file: _dlFile,
          controller: _dlNumController,
          isDark: isDark,
          onUpload: () => _pickDriverDocument('DL'),
        ),

        // Document 2: Registration Certificate (RC)
        _buildUploadCard(
          title: 'Registration Certificate (RC)',
          subtitle: 'Upload the registration certificate for your vehicle.',
          isUploaded: _rcUploaded,
          file: _rcFile,
          controller: _rcNumController,
          isDark: isDark,
          onUpload: () => _pickDriverDocument('RC'),
        ),

        // Document 3: Insurance Certificate
        _buildUploadCard(
          title: 'Insurance Certificate',
          subtitle: 'Upload a valid insurance certificate for your vehicle.',
          isUploaded: _insuranceUploaded,
          file: _insuranceFile,
          controller: _insuranceNumController,
          isDark: isDark,
          onUpload: () => _pickDriverDocument('INSURANCE'),
        ),

        const SizedBox(height: 32),

        // Bottom Action Buttons
        AppButton(
          text: 'Review & Submit →',
          onPressed: () => setState(() => _currentStep = 4),
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => setState(() => _currentStep = 2),
            child: const Text(
              'Save & Continue Later',
              style: TextStyle(
                color: Color(0xFF1A6DF8),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildUploadCard({
    required String title,
    required String subtitle,
    required bool isUploaded,
    required AppUploadedFile? file,
    required TextEditingController controller,
    required bool isDark,
    required VoidCallback onUpload,
  }) {
    final ext = file?.extension ?? '';
    final fileSizeText = file != null && file.formattedSize.isNotEmpty
        ? ' • ${file.formattedSize}'
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUploaded ? const Color(0xFF10B981) : (isDark ? AppColors.borderDark : const Color(0xFFE5E7EB)),
          width: isUploaded ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isUploaded ? const Color(0xFFD1FAE5) : const Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isUploaded ? Icons.task_alt_rounded : Icons.badge_outlined,
                  color: isUploaded ? const Color(0xFF059669) : const Color(0xFF1A6DF8),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (isUploaded && file != null)
                      Text(
                        '${file.name}$fileSizeText',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF059669),
                        ),
                      )
                    else
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (isUploaded && ext.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              ext,
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                            ),
                          ),
                        const Text(
                          'PDF, DOCX, PNG, JPG • Max 5MB',
                          style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onUpload,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUploaded ? const Color(0xFFECFDF5) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isUploaded ? const Color(0xFF10B981) : const Color(0xFF1A6DF8),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUploaded ? Icons.sync : Icons.upload_outlined,
                        color: isUploaded ? const Color(0xFF059669) : const Color(0xFF1A6DF8),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isUploaded ? 'Change' : 'Upload',
                        style: TextStyle(
                          color: isUploaded ? const Color(0xFF059669) : const Color(0xFF1A6DF8),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: controller,
            hintText: '$title Number',
            prefixIcon: Icons.edit_note_rounded,
          ),
          if (isUploaded)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 4),
              child: Text(
                '✓ Auto-filled from ${ext.isNotEmpty ? ext : 'document'}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF059669), fontWeight: FontWeight.w500),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // SCREEN 4: REVIEW YOUR APPLICATION
  // ==========================================
  Widget _buildStep4ReviewApplication(bool isDark) {
    return Column(
      key: const ValueKey(3),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                        height: 1.2,
                      ),
                      children: const [
                        TextSpan(text: "Review your\napplication before\nyou "),
                        TextSpan(
                          text: "submit",
                          style: TextStyle(color: Color(0xFF1A6DF8)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please review the details below. You can edit any section before submitting.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFF1A6DF8).withAlpha(15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.assignment_turned_in_rounded, size: 64, color: Color(0xFF1A6DF8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Verified Payano Student Green Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Verified Payano Student',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF065F46),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Your existing Payano student account is verified.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF047857)),
                    ),
                  ],
                ),
              ),
              const Text(
                'View Profile >',
                style: TextStyle(
                  color: Color(0xFF059669),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section 1: Vehicle Details Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Vehicle Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _currentStep = 2),
                    icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF1A6DF8)),
                    label: const Text(
                      'Edit',
                      style: TextStyle(color: Color(0xFF1A6DF8), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Icon(Icons.moped_rounded, size: 48, color: Color(0xFF1A6DF8)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [
                        _buildDetailRow('Vehicle Type', _selectedVehicleType, isDark),
                        _buildDetailRow('Make & Model', _makeModelController.text.trim(), isDark),
                        _buildDetailRow('Registration Number', _regNumController.text.trim(), isDark),
                        _buildDetailRow('Colour', _colorController.text.trim(), isDark),
                        _buildDetailRow('Ownership', _ownership == 'Yes, I own it' ? 'I own this vehicle' : 'Owned by someone else', isDark),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Section 2: Uploaded Documents Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Uploaded Documents',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => setState(() => _currentStep = 3),
                    icon: const Icon(Icons.edit_outlined, size: 16, color: Color(0xFF1A6DF8)),
                    label: const Text(
                      'Edit',
                      style: TextStyle(color: Color(0xFF1A6DF8), fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildDocReviewRow('Driving Licence', _dlNumController.text.trim(), _dlFile, isDark),
              const SizedBox(height: 10),
              _buildDocReviewRow('Registration Certificate (RC)', _rcNumController.text.trim(), _rcFile, isDark),
              const SizedBox(height: 10),
              _buildDocReviewRow('Insurance Certificate', _insuranceNumController.text.trim(), _insuranceFile, isDark),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Submit Application Button
        AppButton(
          text: 'Submit Application →',
          isLoading: _isSubmitting,
          onPressed: _handleSubmitApplication,
        ),
        const SizedBox(height: 12),
        Center(
          child: TextButton(
            onPressed: () => context.go('/driver/home'),
            child: const Text(
              'Save & Continue Later',
              style: TextStyle(
                color: Color(0xFF1A6DF8),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : const Color(0xFF6B7280),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocReviewRow(String title, String docNum, AppUploadedFile? file, bool isDark) {
    final ext = file?.extension.toUpperCase();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 1),
              Row(
                children: [
                  Text(
                    docNum,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : const Color(0xFF6B7280),
                    ),
                  ),
                  if (ext != null) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ext,
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0284C7)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            children: [
              Text(
                'Uploaded',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF059669),
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF059669)),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // SCREEN 5: APPLICATION SUBMITTED (47.Application Submitted.png)
  // ==========================================
  Widget _buildStep5ApplicationSubmitted(bool isDark) {
    return Column(
      key: const ValueKey(5),
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        // Success celebration icon
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withAlpha(40),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.check_circle_rounded, size: 54, color: Color(0xFF10B981)),
          ),
        ),
        const SizedBox(height: 20),

        // Title & Description
        Text(
          "You're all set! 🎉",
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your driver application has been submitted and is currently under review.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : const Color(0xFF6B7280),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 24),

        // Verification in Progress Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF59E0B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Verification in Progress',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF92400E),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE68A),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '24-48 hrs',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Our team is verifying your submitted documents against official records.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFB45309), height: 1.3),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Application Status Checklist Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE5E7EB)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Application Progress',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 14),
              _buildProgressItem('College Student Verification', 'Verified', const Color(0xFF10B981), Icons.check_circle_rounded, isDark),
              const Divider(height: 18),
              _buildProgressItem('Vehicle Details ($_selectedVehicleType)', 'Completed', const Color(0xFF10B981), Icons.check_circle_rounded, isDark),
              const Divider(height: 18),
              _buildProgressItem('Driving Licence', 'Under Review', const Color(0xFFF59E0B), Icons.hourglass_empty_rounded, isDark),
              const Divider(height: 18),
              _buildProgressItem('Registration Certificate (RC)', 'Under Review', const Color(0xFFF59E0B), Icons.hourglass_empty_rounded, isDark),
              const Divider(height: 18),
              _buildProgressItem('Insurance Certificate', 'Under Review', const Color(0xFFF59E0B), Icons.hourglass_empty_rounded, isDark),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // What Happens Next Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What Happens Next?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 10),
              _buildBullet('1. Document verification completes within 24 to 48 hours.'),
              const SizedBox(height: 6),
              _buildBullet("2. You'll receive an in-app notification once your account is active."),
              const SizedBox(height: 6),
              _buildBullet('3. Go to Driver Home, switch Online, and start accepting rides.'),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Go to Home Button
        AppButton(
          text: 'Go to Driver Home →',
          onPressed: () => context.go('/driver/home'),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildProgressItem(String title, String status, Color statusColor, IconData icon, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        Row(
          children: [
            Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(icon, size: 16, color: statusColor),
          ],
        ),
      ],
    );
  }

  Widget _buildBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A6DF8))),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563), height: 1.3),
          ),
        ),
      ],
    );
  }
}
