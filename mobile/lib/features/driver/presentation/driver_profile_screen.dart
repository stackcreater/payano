import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/models/user_model.dart';
import 'providers/driver_flow_provider.dart';

class DriverProfileScreen extends ConsumerWidget {
  const DriverProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final driverState = ref.watch(driverFlowProvider);
    final profile = driverState.profile;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B111E) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(context, isDark, driverState.isOnline),

            // Scrollable Profile Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Profile',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 1. Driver Identity Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Avatar
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: const DecorationImage(
                                    image: NetworkImage(
                                      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
                                    ),
                                    fit: BoxFit.cover,
                                  ),
                                  border: Border.all(color: const Color(0xFF2563EB), width: 2),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Name & ID
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      profile.name,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Driver ID: ${profile.driverId}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.verified_rounded, color: Color(0xFF2563EB), size: 16),
                                        const SizedBox(width: 4),
                                        const Text(
                                          'Verified Driver',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF2563EB),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9), height: 1),
                          const SizedBox(height: 14),

                          // 3 Stats in Driver Card
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              // Rating
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                                      const SizedBox(width: 4),
                                      Text(
                                        profile.rating.toString(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Rating',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              Container(height: 28, width: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),

                              // Rides Completed
                              Column(
                                children: [
                                  Text(
                                    profile.ridesCompleted.toString(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Rides Completed',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              Container(height: 28, width: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),

                              // College Verified
                              Column(
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.verified_user_rounded, color: Color(0xFF10B981), size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        'College Verified',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Sona College',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 2. Vehicle Details Section
                    Text(
                      'Vehicle Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(Icons.two_wheeler_rounded, color: Color(0xFF2563EB), size: 28),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  profile.vehicleModel,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  profile.vehicleRegNo,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  profile.vehicleColor,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Verified',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. Earnings Summary (This Month)
                    Text(
                      'Earnings Summary (This Month)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryStat(
                            icon: Icons.account_balance_wallet_rounded,
                            value: '₹${profile.monthlyEarnings.toInt()}',
                            label: 'Total Earnings',
                            isDark: isDark,
                          ),
                          Container(height: 32, width: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          _buildSummaryStat(
                            icon: Icons.two_wheeler_rounded,
                            value: profile.monthlyRides.toString(),
                            label: 'Rides',
                            isDark: isDark,
                          ),
                          Container(height: 32, width: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          _buildSummaryStat(
                            icon: Icons.access_time_rounded,
                            value: profile.monthlyOnlineTime,
                            label: 'Online Time',
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 4. Account Section
                    Text(
                      'Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildAccountTile(
                            icon: Icons.verified_user_outlined,
                            title: 'Documents & Verification',
                            subtitle: 'All your documents are verified',
                            onTap: () => context.push('/driver/documents'),
                            isDark: isDark,
                          ),
                          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                          _buildAccountTile(
                            icon: Icons.headset_mic_outlined,
                            title: 'Help & Support',
                            subtitle: 'Get help and contact support',
                            onTap: () => context.push('/driver/support'),
                            isDark: isDark,
                          ),
                          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                          _buildAccountTile(
                            icon: Icons.settings_outlined,
                            title: 'Settings',
                            subtitle: 'App preferences and privacy',
                            onTap: () => context.push('/driver/settings'),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 5. Other Section
                    Text(
                      'Other',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildAccountTile(
                            icon: Icons.swap_horiz_rounded,
                            title: 'Switch to Student Mode',
                            subtitle: 'Book rides as a student',
                            onTap: () {
                              ref.read(authServiceProvider).switchRole(UserRole.rider);
                              context.go('/home');
                            },
                            isDark: isDark,
                          ),
                          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                          _buildAccountTile(
                            icon: Icons.shield_outlined,
                            title: 'Terms & Policies',
                            subtitle: 'Terms of service and privacy policy',
                            onTap: () {},
                            isDark: isDark,
                          ),
                          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                          _buildAccountTile(
                            icon: Icons.logout_rounded,
                            title: 'Log out',
                            subtitle: 'Sign out from your driver account',
                            isDestructive: true,
                            onTap: () => _showLogoutConfirmation(context, ref, isDark),
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, isDark),
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
              decoration: const BoxDecoration(
                color: Color(0xFFFFEBEB),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout, color: Color(0xFFEF4444), size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              'Log Out',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to log out\nfrom your driver account?',
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
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                      backgroundColor: const Color(0xFFEF4444),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) context.go('/login');
                    },
                    child: const Text(
                      'Log Out',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  Widget _buildTopBar(BuildContext context, bool isDark, bool isOnline) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PAYANO',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    'Driver',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Online',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined),
                onPressed: () => context.push('/notifications'),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 18,
                backgroundColor: const Color(0xFFEFF6FF),
                child: const Icon(Icons.person, color: Color(0xFF2563EB), size: 20),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat({
    required IconData icon,
    required String value,
    required String label,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF2563EB), size: 22),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isDestructive
              ? const Color(0xFFFEE2E2)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFEFF6FF)),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isDestructive ? const Color(0xFFDC2626) : const Color(0xFF2563EB),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: isDestructive
              ? const Color(0xFFDC2626)
              : (isDark ? Colors.white : const Color(0xFF0F172A)),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDestructive
              ? const Color(0xFFEF4444)
              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: isDestructive ? const Color(0xFFDC2626) : const Color(0xFF94A3B8),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(context, Icons.home_rounded, 'Home', false, () => context.go('/driver/home')),
          _navItem(context, Icons.two_wheeler_rounded, 'Rides', false, () => context.go('/driver/rides')),
          _navItem(context, Icons.account_balance_wallet_rounded, 'Earnings', false, () => context.go('/driver/earnings')),
          _navItem(context, Icons.person_rounded, 'Profile', true, () {}),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 24,
            color: active ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: active ? FontWeight.bold : FontWeight.w500,
              color: active ? const Color(0xFF2563EB) : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}
