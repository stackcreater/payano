import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  double _surgeMultiplier = 1.2;

  final List<Map<String, String>> _pendingDrivers = [
    {'name': 'Deepak S', 'phone': '+91 98112 34567', 'vehicle': 'Hero Splendor (KA-05-AB-1234)', 'doc': 'DL & RC Pending'},
    {'name': 'Kiran Gowda', 'phone': '+91 97441 98765', 'vehicle': 'Ather 450X (KA-03-EV-7890)', 'doc': 'Insurance Pending'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payano Admin Portal'),
        backgroundColor: Colors.black,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text('System Metrics Overview', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),

              // Metric Grid Cards
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildMetricCard('ACTIVE DRIVERS', '412 Online', Icons.two_wheeler, AppColors.primary, isDark),
                  _buildMetricCard('RIDES TODAY', '1,890 Rides', Icons.check_circle, AppColors.success, isDark),
                  _buildMetricCard('TOTAL REVENUE', '₹1,45,200', Icons.currency_rupee, AppColors.secondary, isDark),
                  _buildMetricCard('OPEN TICKETS', '14 Pending', Icons.confirmation_number, AppColors.warning, isDark),
                ],
              ),

              const SizedBox(height: 28),
              // Dynamic Surge Controller
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: AppRadius.borderLg,
                  boxShadow: AppShadows.cardShadow(isDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('City Surge Pricing Multiplier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(4)),
                          child: Text('${_surgeMultiplier.toStringAsFixed(1)}x', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Slider(
                      value: _surgeMultiplier,
                      min: 1.0,
                      max: 2.5,
                      divisions: 15,
                      activeColor: AppColors.primary,
                      onChanged: (val) => setState(() => _surgeMultiplier = val),
                    ),
                    Text(
                      'Applies real-time surge multiplier across Payano Lite, Moto, EV, and Express categories during peak hours.',
                      style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),
              const Text('Driver Verification Queue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              ..._pendingDrivers.map((driver) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: AppRadius.borderMd,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(driver['name']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(color: AppColors.warning.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                            child: Text(driver['doc']!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.warning)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('${driver['phone']} • ${driver['vehicle']}', style: TextStyle(fontSize: 13, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight)),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.error)),
                              child: const Text('Reject', style: TextStyle(color: AppColors.error)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _pendingDrivers.remove(driver);
                                });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Driver ${driver['name']} Approved!')),
                                );
                              },
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
                              child: const Text('Approve Driver', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: AppRadius.borderMd,
        boxShadow: AppShadows.cardShadow(isDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight)),
        ],
      ),
    );
  }
}
