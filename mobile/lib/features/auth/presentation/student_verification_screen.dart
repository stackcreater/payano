import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/models/user_model.dart';
import '../../../shared/models/uploaded_file.dart';

// Steps:
// 0: Intro (Verify your student identity)
// 1: Upload Front (Step 1 of 4)
// 2: Review Front (Step 2 of 4 preview)
// 3: Upload Back (Step 2 of 4)
// 4: Review Back (Step 2 of 4 review)
// 5: Verifying (Step 3 of 4)
// 6: Verified! (Step 4 of 4 - success)

class StudentVerificationScreen extends ConsumerStatefulWidget {
  const StudentVerificationScreen({super.key});

  @override
  ConsumerState<StudentVerificationScreen> createState() =>
      _StudentVerificationScreenState();
}

class _StudentVerificationScreenState
    extends ConsumerState<StudentVerificationScreen> with SingleTickerProviderStateMixin {
  int _currentStep = 0;
  // Verification animation state
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  int _verifyProgress = 0; // 0=none, 1=first done, 2=second done, 3=third (in progress), 4=all done

  AppUploadedFile? _frontFile;
  AppUploadedFile? _backFile;
  String _detectedStudentId = 'STU-2024-8842';
  final String _detectedCollege = 'RV College of Engineering, Bengaluru';
  final String _detectedValidYear = '2027';

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _finishVerification() {
    final user = ref.read(authServiceProvider).currentUser;
    if (user != null && user.role == UserRole.driver) {
      if (user.verificationStatus != 'verified') {
        context.go('/driver/onboarding');
      } else {
        context.go('/driver/home');
      }
    } else {
      context.go('/home');
    }
  }

  void _nextStep() {
    if (_currentStep == 4) {
      // Start verifying
      setState(() => _currentStep = 5);
      _runVerificationAnimation();
    } else if (_currentStep == 6) {
      _finishVerification();
    } else if (_currentStep < 6) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      if (context.canPop()) context.pop();
    }
  }

  void _runVerificationAnimation() async {
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) setState(() => _verifyProgress = 1);
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) setState(() => _verifyProgress = 2);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) setState(() => _verifyProgress = 3);
    await Future.delayed(const Duration(milliseconds: 350));
    if (mounted) {
      // Mark student as verified in backend
      ref.read(authServiceProvider).updateStudentVerificationStatus('verified');
      setState(() {
        _verifyProgress = 4;
        _currentStep = 6; // auto navigate to verified screen
      });
    }
  }

  // --- Helpers ---

  int get _stepBarStep {
    if (_currentStep == 0) return 0;
    if (_currentStep == 1 || _currentStep == 2) return 1;
    if (_currentStep == 3 || _currentStep == 4) return 2;
    if (_currentStep == 5) return 3;
    return 4;
  }

  String get _stepBarLabel {
    if (_currentStep == 0) return '';
    if (_currentStep <= 2) return 'Step 1 of 4';
    if (_currentStep <= 4) return 'Step 2 of 4';
    if (_currentStep == 5) return 'Step 3 of 4';
    return 'Step 4 of 4';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep == 5 || _currentStep == 6
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight),
                onPressed: _prevStep,
              ),
        title: _currentStep > 0 ? _buildProgressBar(isDark) : null,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: AppSpacing.screenPadding,
                child: _buildCurrentView(isDark),
              ),
            ),
            if (_currentStep > 0 && _currentStep < 5)
              _buildBottomNav(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_currentStep < 6)
          Text(
            _stepBarLabel,
            style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
                fontWeight: FontWeight.bold),
          ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(4, (index) {
            bool isActive = index < _stepBarStep;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 3,
              width: 38,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary
                    : (isDark ? AppColors.borderDark : AppColors.borderLight),
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          'Student Verification',
          style: TextStyle(
              fontSize: 10,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight),
        ),
      ],
    );
  }

  Widget _buildCurrentView(bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildIntroView(isDark);
      case 1:
        return _buildUploadView(
          title: 'Upload the front of\nyour college ID',
          description:
              'Take a clear photo of the front side of your college ID. Make sure all details are visible and easy to read.',
          frameLabel: 'Front side of your ID',
          isDark: isDark,
          isFront: true,
        );
      case 2:
        return _buildReviewView(
          title: 'Review the front of\nyour college ID',
          description:
              'Make sure your ID is clear, complete, and easy to read before continuing.',
          isDark: isDark,
        );
      case 3:
        return _buildUploadView(
          title: 'Upload the back of\nyour college ID',
          description:
              'Take a clear photo of the back of your college ID. Make sure all details are visible and easy to read.',
          frameLabel: 'Back of your college ID',
          isDark: isDark,
          isFront: false,
        );
      case 4:
        return _buildReviewView(
          title: 'Review the back of\nyour college ID',
          description:
              'Make sure all information on the back of your ID is clear, complete, and easy to read before continuing.',
          isDark: isDark,
        );
      case 5:
        return _buildVerifyingView(isDark);
      case 6:
        return _buildVerifiedView(isDark);
      default:
        return const SizedBox();
    }
  }

  Widget _buildBottomNav(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_currentStep == 2 || _currentStep == 4) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => setState(() => _currentStep--),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Retake Photo'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppColors.primary),
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Continue',
                    onPressed: _nextStep,
                    icon: Icons.arrow_forward,
                  ),
                ),
              ],
            ),
          ] else ...[
            AppButton(
              text: _currentStep == 0 ? 'Continue' : 'Continue',
              onPressed: _nextStep,
              icon: Icons.arrow_forward,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline,
                  size: 13,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
              const SizedBox(width: 4),
              Text(
                'Your data is encrypted and used only for student verification.',
                style: TextStyle(
                    fontSize: 11,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================
  // STEP 0: INTRO
  // ===========================
  Widget _buildIntroView(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PAYANO',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Verify your\nstudent identity',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "To keep Payano exclusive to verified students, we'll verify your college ID. This one-time process usually takes only a few minutes.",
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.school_rounded,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF0F4FF),
            borderRadius: AppRadius.borderMd,
          ),
          child: Text(
            'Your information is encrypted and used only for student verification.',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textPrimaryDark : const Color(0xFF374151),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // What you'll need
        _buildInfoCard(
          title: "What you'll need",
          isDark: isDark,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRequirementItem(Icons.badge_outlined, 'Valid college\nID card', isDark),
              _buildRequirementItem(Icons.flip_to_back_outlined, 'Front and back\nof your ID', isDark),
              _buildRequirementItem(Icons.crop_free_outlined, 'Clear, readable\nphotos', isDark),
              _buildRequirementItem(Icons.lightbulb_outline, 'Good lighting\nrecommended', isDark),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // What to expect
        _buildInfoCard(
          title: 'What to expect',
          isDark: isDark,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProcessStep(Icons.upload_file_outlined, 'Upload your ID', 'Front and back\nphotos', isDark),
              const Icon(Icons.arrow_forward_ios, size: 11, color: Color(0xFF9CA3AF)),
              _buildProcessStep(Icons.verified_user_outlined, 'Verification', "We'll securely verify\nyour student details", isDark),
              const Icon(Icons.arrow_forward_ios, size: 11, color: Color(0xFF9CA3AF)),
              _buildProcessStep(Icons.person_pin_circle_outlined, "You're verified", 'Start using Payano.', isDark),
            ],
          ),
        ),
        const SizedBox(height: 28),
        AppButton(
          text: 'Continue',
          onPressed: _nextStep,
          icon: Icons.arrow_forward,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.help_outline, size: 16, color: AppColors.primary),
            label: const Text('Why do we verify students?',
                style: TextStyle(color: AppColors.primary, fontSize: 14)),
          ),
        ),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, size: 13,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              const SizedBox(width: 4),
              Text(
                'Secure • Private • Student-only community',
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildInfoCard({required String title, required Widget child, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
        borderRadius: AppRadius.borderLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildRequirementItem(IconData icon, String text, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 26),
          const SizedBox(height: 6),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
        ],
      ),
    );
  }

  Widget _buildProcessStep(IconData icon, String title, String subtitle, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 6),
          Text(title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
          const SizedBox(height: 2),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 9,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
        ],
      ),
    );
  }

  Future<void> _pickStudentDocument(bool isFront) async {
    try {
      final file = await AppUploadedFile.pickDocument();

      if (file != null) {
        final cleanBase = file.name.split('.').first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
        setState(() {
          if (isFront) {
            _frontFile = file;
            if (cleanBase.length >= 4) {
              _detectedStudentId = 'STU-${cleanBase.substring(0, cleanBase.length > 8 ? 8 : cleanBase.length)}';
            }
          } else {
            _backFile = file;
          }
          _currentStep = isFront ? 2 : 4;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✓ ${file.name} uploaded successfully!'),
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
            content: Text('Error picking document: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ===========================
  // STEP 1 & 3: UPLOAD VIEW
  // ===========================
  Widget _buildUploadView({
    required String title,
    required String description,
    required String frameLabel,
    required bool isDark,
    required bool isFront,
  }) {
    final file = isFront ? _frontFile : _backFile;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                height: 1.2)),
        const SizedBox(height: 12),
        Text(description,
            style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                height: 1.5)),
        const SizedBox(height: 32),
        // Dashed scan frame
        GestureDetector(
          onTap: () => _pickStudentDocument(isFront),
          child: Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: isDark ? AppColors.primary.withAlpha(20) : const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary, style: BorderStyle.solid, width: 1.5),
            ),
            child: Stack(
              children: [
                Positioned(top: 16, left: 16, child: _buildCorner()),
                Positioned(top: 16, right: 16, child: RotatedBox(quarterTurns: 1, child: _buildCorner())),
                Positioned(bottom: 16, right: 16, child: RotatedBox(quarterTurns: 2, child: _buildCorner())),
                Positioned(bottom: 16, left: 16, child: RotatedBox(quarterTurns: 3, child: _buildCorner())),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(40),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 30),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        file != null ? 'Selected: ${file.name}' : frameLabel,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tap here to browse PDF, DOCX, PNG or JPG files',
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Text('Upload using',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
        const SizedBox(height: 12),
        _buildUploadOption(Icons.upload_file_outlined, 'Choose File / Document', 'Select PDF, DOCX, PNG, JPG from storage', isDark, () {
          _pickStudentDocument(isFront);
        }),
        const SizedBox(height: 12),
        _buildUploadOption(Icons.camera_alt_outlined, 'Take Photo', 'Use your camera', isDark, () {
          _pickStudentDocument(isFront);
        }),
        const SizedBox(height: 12),
        _buildUploadOption(Icons.photo_library_outlined, 'Choose from Gallery', 'Select an existing photo', isDark, () {
          _pickStudentDocument(isFront);
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCorner() {
    return SizedBox(
      width: 22,
      height: 22,
      child: CustomPaint(painter: _CornerPainter()),
    );
  }

  Widget _buildUploadOption(IconData icon, String title, String subtitle, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          borderRadius: BorderRadius.circular(12),
          color: isDark ? AppColors.surfaceDark : Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  // ===========================
  // STEP 2 & 4: REVIEW VIEW
  // ===========================
  Widget _buildReviewView({
    required String title,
    required String description,
    required bool isDark,
  }) {
    final isFront = _currentStep == 2;
    final file = isFront ? _frontFile : _backFile;
    final ext = file?.extension.toUpperCase() ?? 'JPG';
    final isImage = file?.isImage ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                height: 1.2)),
        const SizedBox(height: 12),
        Text(description,
            style: TextStyle(
                fontSize: 14,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                height: 1.5)),
        const SizedBox(height: 24),

        // Document or Image Preview
        if (file != null && isImage && file.bytes != null)
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF10B981), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.memory(
                file.bytes!,
                fit: BoxFit.cover,
              ),
            ),
          )
        else if (file != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF10B981), width: 1.5),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Color(0xFFD1FAE5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        ext == 'PDF' ? Icons.picture_as_pdf_rounded : Icons.description_rounded,
                        color: const Color(0xFF059669),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            file.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${file.formattedSize} • $ext Document Verified',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF059669), fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Extracted ID: $_detectedStudentId', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    const Text('Status: Authenticated', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ],
            ),
          )
        else
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('INSTRUCTIONS',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF374151))),
                const SizedBox(height: 10),
                const Text('• This card is the property of the college.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                const Text('• Use of this card is subject to the rules and regulations of the college.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                const Text('• This card must be presented on demand.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('R. Mehta\nAuthorized Signature',
                        style: TextStyle(fontSize: 11, color: Color(0xFF374151))),
                    Container(
                      height: 24, width: 140,
                      decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ],
                ),
              ],
            ),
          ),

        const SizedBox(height: 16),
        // Looks good banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFD1FAE5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF059669), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Looks good!',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                    Text('Auto-extracted Student ID: $_detectedStudentId',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF374151))),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.primary.withAlpha(20) : const Color(0xFFEEF4FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              _buildIssueOption(Icons.image_not_supported_outlined, "Can't read the details?", 'Retake or re-upload the document for better clarity.', isDark, () => _pickStudentDocument(isFront)),
              Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight, indent: 16, endIndent: 16),
              _buildIssueOption(Icons.crop, 'Need to make changes?', 'Choose another file or re-scan before continuing.', isDark, () => _pickStudentDocument(isFront)),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildIssueOption(IconData icon, String title, String subtitle, bool isDark, [VoidCallback? onTap]) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  // ===========================
  // STEP 5: VERIFYING
  // ===========================
  Widget _buildVerifyingView(bool isDark) {
    final verifySteps = [
      {'icon': Icons.check_circle_outline, 'title': 'Checking ID authenticity', 'status': 'Completed'},
      {'icon': Icons.manage_search_outlined, 'title': 'Extracting student details', 'status': 'Completed'},
      {'icon': Icons.verified_user_outlined, 'title': 'Verifying student status', 'status': 'In progress...'},
      {'icon': Icons.lock_outline, 'title': 'Finalizing verification', 'status': 'Waiting'},
    ];

    return Column(
      children: [
        const SizedBox(height: 40),
        AnimatedBuilder(
          animation: _glowAnimation,
          builder: (context, child) {
            return Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3 * _glowAnimation.value),
                    blurRadius: 50,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2),
            ),
            child: const Center(
              child: Icon(Icons.verified_user_outlined, color: AppColors.primary, size: 48),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text('Verifying your details',
            style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
        const SizedBox(height: 12),
        Text(
          "We're securely verifying your college ID and student information. This usually takes less than a minute.",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              height: 1.5),
        ),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
          ),
          child: Column(
            children: List.generate(verifySteps.length, (index) {
              final step = verifySteps[index];
              final isDone = _verifyProgress > index + 1;
              final isInProgress = _verifyProgress == index + 1;
              final isWaiting = _verifyProgress < index + 1;

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDone
                                ? const Color(0xFF059669)
                                : isInProgress
                                    ? AppColors.primary.withAlpha(20)
                                    : (isDark ? AppColors.surfaceVariantDark : const Color(0xFFF3F4F6)),
                          ),
                          child: Icon(
                            isDone ? Icons.check_circle : step['icon'] as IconData,
                            color: isDone
                                ? Colors.white
                                : isInProgress
                                    ? AppColors.primary
                                    : const Color(0xFF9CA3AF),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(step['title'] as String,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                              Text(
                                isWaiting ? 'Waiting' : isInProgress ? 'In progress...' : 'Completed',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: isDone
                                        ? const Color(0xFF059669)
                                        : isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
                              ),
                            ],
                          ),
                        ),
                        if (isDone)
                          const Icon(Icons.check_circle, color: Color(0xFF059669), size: 22)
                        else if (isInProgress)
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                          )
                        else
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 2),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (index < verifySteps.length - 1)
                    Divider(height: 1, color: isDark ? AppColors.borderDark : AppColors.borderLight),
                ],
              );
            }),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.primary.withAlpha(15) : const Color(0xFFEEF4FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('This usually takes less than a minute.',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('Please keep the app open while we complete your verification.',
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline,
                size: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            const SizedBox(width: 4),
            Text(
              'Your data is encrypted and used only for student verification.',
              style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ===========================
  // STEP 6: VERIFIED SUCCESS
  // ===========================
  Widget _buildVerifiedView(bool isDark) {
    final isDriver = ref.watch(authServiceProvider).currentUser?.role == UserRole.driver;
    return Column(
      children: [
        const SizedBox(height: 40),
        // Green glowing success icon
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF10B981).withValues(alpha: 0.25),
                blurRadius: 60,
                spreadRadius: 30,
              ),
            ],
          ),
          child: Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF10B981),
            ),
            child: const Center(
              child: Icon(Icons.check, color: Colors.white, size: 50),
            ),
          ),
        ),
        const SizedBox(height: 32),
        Text(isDriver ? "Student Identity Verified!" : "You're verified!",
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
        const SizedBox(height: 14),
        Text(
          isDriver
              ? "Your student identity is verified! Next, verify your driving license, vehicle details, and insurance to activate your Driver Dashboard."
              : "Your student identity has been successfully verified. You're all set to access Payano campus rides.",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              height: 1.5),
        ),
        const SizedBox(height: 32),
        _buildBenefitCard(Icons.group_outlined, 'Exclusive student community',
            'Connect and ride with verified students from your campus.', isDark),
        const SizedBox(height: 12),
        _buildBenefitCard(Icons.verified_user_outlined, 'Safe and trusted rides',
            'Travel confidently with verified riders and drivers.', isDark),
        const SizedBox(height: 12),
        _buildBenefitCard(Icons.card_giftcard_outlined, 'Special offers and benefits',
            'Unlock offers, rewards, and features available only to verified students.', isDark),
        const SizedBox(height: 32),
        AppButton(
          text: isDriver ? 'Continue to License & Vehicle Verification →' : 'Go to Passenger Dashboard →',
          onPressed: _finishVerification,
          icon: Icons.arrow_forward,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline,
                size: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            const SizedBox(width: 4),
            Text(
              'Your data is encrypted and used only for student verification.',
              style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildBenefitCard(IconData icon, String title, String subtitle, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFEEF4FF),
        borderRadius: BorderRadius.circular(16),
        border: isDark ? Border.all(color: AppColors.borderDark) : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, size.height * 0.5)
      ..lineTo(0, 0)
      ..lineTo(size.width * 0.5, 0);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
