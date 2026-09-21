import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DriverSettingsScreen extends ConsumerStatefulWidget {
  const DriverSettingsScreen({super.key});

  @override
  ConsumerState<DriverSettingsScreen> createState() => _DriverSettingsScreenState();
}

class _DriverSettingsScreenState extends ConsumerState<DriverSettingsScreen> {
  bool _soundAlerts = true;
  bool _autoAcceptRides = false;
  bool _biometricLock = true;
  bool _locationSharing = true;
  String _selectedMap = 'Google Maps';
  String _maxDistance = '3 km';

  void _showChangePasswordDialog() {
    final currentPassController = TextEditingController();
    final newPassController = TextEditingController();
    final confirmPassController = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPassController,
                  obscureText: obscure,
                  decoration: const InputDecoration(
                    labelText: 'Current Password',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPassController,
                  obscureText: obscure,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPassController,
                  obscureText: obscure,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Checkbox(
                      value: !obscure,
                      onChanged: (val) => setDialogState(() => obscure = !val!),
                    ),
                    const Text('Show Password', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text('Password updated successfully!'),
                      ],
                    ),
                    backgroundColor: const Color(0xFF10B981),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _clearCache() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.cleaning_services_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('App cache cleared (18.4 MB freed)'),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B111E) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/driver/profile');
            }
          },
        ),
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // ── Section 1: Account & Security ──
            _buildSectionHeader('Account & Security', isDark),
            _buildSettingsCard(
              isDark: isDark,
              children: [
                _buildActionTile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  onTap: _showChangePasswordDialog,
                  isDark: isDark,
                ),
                _divider(isDark),
                _buildSwitchTile(
                  icon: Icons.fingerprint_rounded,
                  title: 'Biometric / PIN Lock',
                  subtitle: 'Require biometric or PIN to open app',
                  value: _biometricLock,
                  onChanged: (val) => setState(() => _biometricLock = val),
                  isDark: isDark,
                ),
                _divider(isDark),
                _buildActionTile(
                  icon: Icons.devices_rounded,
                  title: 'Active Sessions',
                  subtitle: 'Logged in on this device (Chrome / Web)',
                  onTap: () {},
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Section 2: Driver & Trip Preferences ──
            _buildSectionHeader('Driver & Trip Preferences', isDark),
            _buildSettingsCard(
              isDark: isDark,
              children: [
                _buildSwitchTile(
                  icon: Icons.flash_on_rounded,
                  title: 'Auto-Accept Rides',
                  subtitle: 'Automatically accept matching campus ride requests',
                  value: _autoAcceptRides,
                  onChanged: (val) => setState(() => _autoAcceptRides = val),
                  isDark: isDark,
                ),
                _divider(isDark),
                _buildSwitchTile(
                  icon: Icons.volume_up_outlined,
                  title: 'Sound & Ride Chimes',
                  subtitle: 'Play alert sounds when a new ride arrives',
                  value: _soundAlerts,
                  onChanged: (val) => setState(() => _soundAlerts = val),
                  isDark: isDark,
                ),
                _divider(isDark),
                // Navigation App Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.navigation_outlined, size: 22, color: const Color(0xFF2563EB)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Navigation App',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Preferred map for turn-by-turn',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedMap,
                          isDense: true,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          items: ['Google Maps', 'Payano Map', 'Apple Maps']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedMap = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                _divider(isDark),
                // Max Pickup Radius Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      Icon(Icons.near_me_outlined, size: 22, color: const Color(0xFF2563EB)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Max Pickup Radius',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Match rides within distance',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _maxDistance,
                          isDense: true,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          items: ['1 km', '2 km', '3 km', '5 km']
                              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _maxDistance = val);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

              ],
            ),

            const SizedBox(height: 20),

            // ── Section 3: Privacy & Data ──
            _buildSectionHeader('Privacy & Data', isDark),
            _buildSettingsCard(
              isDark: isDark,
              children: [
                _buildSwitchTile(
                  icon: Icons.location_on_outlined,
                  title: 'Location Sharing',
                  subtitle: 'Share live GPS location with campus rider during active trip',
                  value: _locationSharing,
                  onChanged: (val) => setState(() => _locationSharing = val),
                  isDark: isDark,
                ),
                _divider(isDark),
                _buildActionTile(
                  icon: Icons.cleaning_services_outlined,
                  title: 'Clear App Cache',
                  subtitle: 'Free up local offline map & image storage',
                  onTap: _clearCache,
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Section 4: About Payano ──
            _buildSectionHeader('About', isDark),
            _buildSettingsCard(
              isDark: isDark,
              children: [
                _buildActionTile(
                  icon: Icons.info_outline,
                  title: 'App Version',
                  subtitle: 'v2.4.0 (Build 2026.09)',
                  onTap: () {},
                  isDark: isDark,
                ),
                _divider(isDark),
                _buildActionTile(
                  icon: Icons.shield_outlined,
                  title: 'Privacy Policy & Terms',
                  subtitle: 'Read our campus ride-sharing policies',
                  onTap: () => context.push('/driver/support'),
                  isDark: isDark,
                ),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required bool isDark, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFF2563EB), size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, size: 20, color: Color(0xFF94A3B8)),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: const Color(0xFF2563EB), size: 22),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF0F172A),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
      value: value,
      activeThumbColor: const Color(0xFF2563EB),
      onChanged: onChanged,
    );
  }

  Widget _divider(bool isDark) {
    return Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9));
  }
}
