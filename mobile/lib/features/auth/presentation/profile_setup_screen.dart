import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/services/auth_service.dart';

// Step 0: Profile form (Step 1 of 2)
// Step 1: All set! (Step 2 of 2)

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  int _currentStep = 0;
  String? _selectedImage;

  final TextEditingController _nameController =
      TextEditingController(text: 'Rakshak M P');
  String? _selectedDepartment;
  String? _selectedYear;
  String? _selectedGender;
  final TextEditingController _emergencyContactController =
      TextEditingController();
  bool _isLoading = false;

  final List<String> _departments = [
    'Computer Science',
    'Electronics & Communication',
    'Mechanical Engineering',
    'Civil Engineering',
    'Information Technology',
    'Business Administration',
    'Arts & Humanities',
    'Science',
    'Other',
  ];

  final List<String> _years = [
    '1st Year',
    '2nd Year',
    '3rd Year',
    '4th Year',
    'Postgraduate',
  ];

  final List<String> _genders = ['Male', 'Female', 'Non-binary', 'Prefer not to say'];

  void _pickImage({required bool useCamera}) async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.isNotEmpty) {
        final path = result.files.first.path ?? result.files.first.name;
        setState(() {
          _selectedImage = path;
        });
        ref.read(authServiceProvider).updateProfileImage(path);
      } else {
        const sampleUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400';
        setState(() {
          _selectedImage = sampleUrl;
        });
        ref.read(authServiceProvider).updateProfileImage(sampleUrl);
      }
    } catch (_) {
      const sampleUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400';
      setState(() {
        _selectedImage = sampleUrl;
      });
      ref.read(authServiceProvider).updateProfileImage(sampleUrl);
    }
  }

  void _showImageSourceModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Profile Picture',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEEF4FF),
                    child: Icon(Icons.camera_alt, color: AppColors.primary),
                  ),
                  title: const Text('Take Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Capture using camera'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    _pickImage(useCamera: true);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEEF4FF),
                    child: Icon(Icons.photo_library, color: AppColors.primary),
                  ),
                  title: const Text('Upload Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Choose from gallery'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    _pickImage(useCamera: false);
                  },
                ),
                if (_selectedImage != null)
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFFFEE2E2),
                      child: Icon(Icons.delete_outline, color: AppColors.error),
                    ),
                    title: const Text('Remove Photo', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.error)),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() => _selectedImage = null);
                      ref.read(authServiceProvider).updateProfileImage('');
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _continue() {
    if (_nameController.text.isEmpty) return;

    // Immediately advance UI step for instantaneous feedback
    setState(() {
      _isLoading = false;
      _currentStep = 1;
    });

    // Save profile asynchronously in background without blocking screen transition
    ref.read(authServiceProvider).updateProfile(
          name: _nameController.text.trim(),
          email: '',
          gender: _selectedGender,
          emergencyContact: _emergencyContactController.text.trim().isNotEmpty
              ? _emergencyContactController.text.trim()
              : null,
        );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep == 0
            ? IconButton(
                icon: Icon(Icons.arrow_back,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
                onPressed: () {
                  if (context.canPop()) context.pop();
                },
              )
            : null,
        title: _buildProgressBar(isDark),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _currentStep == 0
            ? _buildProfileForm(isDark)
            : _buildAllSetView(isDark),
      ),
    );
  }

  Widget _buildProgressBar(bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Profile Setup',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(2, (index) {
            bool isActive = index <= _currentStep;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 3,
              width: 60,
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
          _currentStep == 0 ? 'Step 1 of 2' : 'Step 2 of 2',
          style: TextStyle(
              fontSize: 11,
              color: AppColors.primary,
              fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  // ===========================
  // STEP 0: PROFILE FORM
  // ===========================
  Widget _buildProfileForm(bool isDark) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: AppSpacing.screenPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                // Title
                Text(
                  "Let's set up your profile",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Complete your profile to personalize your Payano experience and help other students recognize you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                // Profile photo
                GestureDetector(
                  onTap: () => _showImageSourceModal(context, isDark),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      CircleAvatar(
                        radius: 52,
                        backgroundColor: isDark
                            ? AppColors.surfaceVariantDark
                            : const Color(0xFFE5E7EB),
                        backgroundImage: _selectedImage != null && _selectedImage!.startsWith('http')
                            ? NetworkImage(_selectedImage!) as ImageProvider
                            : null,
                        child: _selectedImage == null || !_selectedImage!.startsWith('http')
                            ? Icon(Icons.person,
                                size: 64,
                                color: isDark ? AppColors.textSecondaryDark : const Color(0xFFD1D5DB))
                            : null,
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: isDark ? AppColors.backgroundDark : Colors.white,
                              width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_outlined,
                            size: 16, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Add a profile photo',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Optional, but recommended',
                    style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight)),
                const SizedBox(height: 28),
                // Full Name
                _buildLabel('Full Name', isDark),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _nameController,
                  hintText: 'Enter your full name',
                  prefixIcon: Icons.person_outline,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                // Department / Course
                _buildLabel('Department / Course', isDark),
                const SizedBox(height: 8),
                _buildDropdown(
                  value: _selectedDepartment,
                  hint: 'Select your Department',
                  items: _departments,
                  prefixIcon: Icons.menu_book_outlined,
                  onChanged: (v) => setState(() => _selectedDepartment = v),
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                // Year of Study
                _buildLabel('Year of Study', isDark),
                const SizedBox(height: 8),
                _buildDropdown(
                  value: _selectedYear,
                  hint: 'Select your year',
                  items: _years,
                  prefixIcon: Icons.auto_stories_outlined,
                  onChanged: (v) => setState(() => _selectedYear = v),
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                // Gender (Optional)
                _buildLabel('Gender (Optional)', isDark),
                const SizedBox(height: 8),
                _buildDropdown(
                  value: _selectedGender,
                  hint: 'Select your gender',
                  items: _genders,
                  prefixIcon: Icons.person_outline,
                  onChanged: (v) => setState(() => _selectedGender = v),
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                // Emergency Contact
                _buildLabel('Emergency Contact', isDark),
                const SizedBox(height: 8),
                _buildTextField(
                  controller: _emergencyContactController,
                  hintText: 'Enter contact number',
                  prefixIcon: Icons.call_outlined,
                  keyboardType: TextInputType.phone,
                  isDark: isDark,
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: AppButton(
            text: 'Continue',
            isLoading: _isLoading,
            onPressed: _continue,
            icon: Icons.arrow_forward,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData prefixIcon,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(prefixIcon,
                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF9CA3AF),
                size: 22),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: TextStyle(
                  fontSize: 15,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : const Color(0xFF9CA3AF)),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required IconData prefixIcon,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(prefixIcon,
                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF9CA3AF),
                size: 22),
          ),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                hint: Text(hint,
                    style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : const Color(0xFF9CA3AF))),
                isExpanded: true,
                icon: Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(Icons.keyboard_arrow_down_rounded,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : const Color(0xFF374151)),
                ),
                dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                style: TextStyle(
                    fontSize: 15,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight),
                onChanged: onChanged,
                items: items
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================
  // STEP 1: ALL SET!
  // ===========================
  Widget _buildAllSetView(bool isDark) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
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
                  color: const Color(0xFF10B981).withValues(alpha: 0.22),
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
                child: Icon(Icons.check, color: Colors.white, size: 54),
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text(
            "You're all set!",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "Your profile has been completed successfully. You're ready to start booking rides across your campus.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          // Scooter illustration
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Icon(
                Icons.electric_moped_outlined,
                size: 100,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Info card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? AppColors.primary.withAlpha(15) : const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(16),
              border: isDark ? Border.all(color: AppColors.borderDark) : null,
            ),
            child: Column(
              children: [
                Text(
                  'Ready for your daily commute',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Book safe, affordable two-wheeler rides with verified students travelling to and from college.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          AppButton(
            text: 'Continue to Verification',
            onPressed: () => context.go('/student-verification'),
            icon: Icons.arrow_forward,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
