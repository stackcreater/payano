import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/models/user_model.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _showImageSourceModal(BuildContext context, WidgetRef ref, bool isDark) {
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
                  'Set Profile Photo',
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
                  subtitle: const Text('Capture photo using camera'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    _pickAndUpdateImage(ref, useCamera: true);
                  },
                ),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFEEF4FF),
                    child: Icon(Icons.photo_library, color: AppColors.primary),
                  ),
                  title: const Text('Upload Photo', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Choose photo from gallery'),
                  onTap: () async {
                    Navigator.pop(ctx);
                    _pickAndUpdateImage(ref, useCamera: false);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _pickAndUpdateImage(WidgetRef ref, {required bool useCamera}) async {
    try {
      final result = await FilePicker.pickFiles(type: FileType.image);
      if (result.isNotEmpty) {
        final path = result.first.path ?? result.first.name;
        ref.read(authServiceProvider).updateProfileImage(path);
      } else {
        const sampleUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400';
        ref.read(authServiceProvider).updateProfileImage(sampleUrl);
      }
    } catch (_) {
      const sampleUrl = 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400';
      ref.read(authServiceProvider).updateProfileImage(sampleUrl);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SafeArea(
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            const SizedBox(height: 12),
            // Header User Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: AppRadius.borderLg,
                boxShadow: AppShadows.cardShadow(isDark),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => _showImageSourceModal(context, ref, isDark),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: AppColors.primary,
                          backgroundImage: user?.profileImage.isNotEmpty == true && user!.profileImage.startsWith('http')
                              ? NetworkImage(user.profileImage) as ImageProvider
                              : null,
                          child: (user?.profileImage ?? '').isEmpty
                              ? const Icon(Icons.person, size: 36, color: Colors.black)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black87,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Rahul Sharma',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.phone ?? '+91 98765 43210',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                          ),
                        ),
                        Text(
                          user?.email ?? 'rahul.s@payano.in',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.primary),
                    onPressed: () => context.push('/profile-setup'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Navigation Options
            _buildProfileTile(
              context,
              icon: Icons.notifications,
              title: 'Notifications',
              onTap: () => context.push('/notifications'),
            ),
            _buildProfileTile(
              context,
              icon: Icons.history,
              title: 'Ride History',
              onTap: () => context.push('/history'),
            ),
            _buildProfileTile(
              context,
              icon: Icons.verified_user,
              title: 'Student Verification',
              onTap: () => context.push('/student-verification'),
            ),
            _buildProfileTile(
              context,
              icon: Icons.account_balance_wallet,
              title: 'Payano Wallet',
              onTap: () => context.push('/wallet'),
            ),
            _buildProfileTile(
              context,
              icon: Icons.two_wheeler,
              title: 'Switch to Driver Mode',
              onTap: () {
                ref.read(authServiceProvider).switchRole(UserRole.driver);
                context.go('/driver/home');
              },
            ),

            _buildProfileTile(
              context,
              icon: Icons.support_agent,
              title: 'Help & Customer Support',
              onTap: () => context.push('/support'),
            ),
            _buildProfileTile(
              context,
              icon: Icons.settings_outlined,
              title: 'Settings',
              onTap: () => context.push('/settings'),
            ),

            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: AppRadius.borderMd,
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error, size: 22),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                trailing: const Icon(Icons.chevron_right, size: 20, color: AppColors.error),
                onTap: () => _showLogoutConfirmation(context, ref, isDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, WidgetRef ref, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.error.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout, color: AppColors.error, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to logout\nfrom your Payano account?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.error,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) context.go('/login');
                    },
                    child: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: AppRadius.borderMd,
        boxShadow: AppShadows.cardShadow(isDark),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 22),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFF94A3B8)),
        onTap: onTap,
      ),
    );
  }
}
