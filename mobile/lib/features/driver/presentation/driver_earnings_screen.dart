import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/driver_flow_provider.dart';

class DriverEarningsScreen extends ConsumerStatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  ConsumerState<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends ConsumerState<DriverEarningsScreen> {
  String _selectedPeriod = 'This Week';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final driverState = ref.watch(driverFlowProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B111E) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(isDark, driverState.isOnline),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading & Time Period Selector
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Earnings',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedPeriod,
                              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF475569)),
                              isDense: true,
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              items: ['This Week', 'Today', 'This Month'].map((period) {
                                return DropdownMenuItem(
                                  value: period,
                                  child: Row(
                                    children: [
                                      const Icon(Icons.calendar_today_outlined, size: 14, color: Color(0xFF475569)),
                                      const SizedBox(width: 6),
                                      Text(period),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedPeriod = val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Mint-Green Total Earnings Summary Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFDCFCE7).withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? const Color(0xFF047857) : const Color(0xFF86EFAC),
                        ),
                      ),
                      child: Row(
                        children: [
                          // 3D Wallet Icon
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Text('👛', style: TextStyle(fontSize: 28)),
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Total Amount
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '₹${(driverState.todayEarnings + 392.0).toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Total Earnings',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Divider
                          Container(
                            height: 44,
                            width: 1,
                            color: isDark ? const Color(0xFF047857) : const Color(0xFF86EFAC),
                          ),
                          const SizedBox(width: 14),

                          // Rides & Online stats
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.two_wheeler_rounded, size: 16, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${driverState.todayRides + 12} rides',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded, size: 16, color: Color(0xFF2563EB)),
                                  const SizedBox(width: 6),
                                  Text(
                                    '4h 32m Online',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Earnings Chart Card
                    Container(
                      padding: const EdgeInsets.all(20),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Earnings This Week',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Bar Chart
                          _buildWeeklyBarChart(isDark, driverState.todayEarnings),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Daily Breakdown Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Daily Breakdown',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: const Row(
                            children: [
                              Text(
                                'View all',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                              SizedBox(width: 4),
                              Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF2563EB)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Daily Cards
                    // Today (highlighted in light mint)
                    _buildDailyTile(
                      date: 'Today',
                      ridesCount: '${driverState.todayRides} rides',
                      amount: '₹${driverState.todayEarnings.toStringAsFixed(2)}',
                      isHighlighted: true,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),

                    // Yesterday
                    _buildDailyTile(
                      date: 'Yesterday',
                      ridesCount: '5 rides',
                      amount: '₹218.00',
                      isHighlighted: false,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),

                    // 10 Aug
                    _buildDailyTile(
                      date: '10 Aug',
                      ridesCount: '7 rides',
                      amount: '₹98.00',
                      isHighlighted: false,
                      isDark: isDark,
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

  Widget _buildTopBar(bool isDark, bool isOnline) {
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
              GestureDetector(
                onTap: () => context.push('/driver/profile'),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  child: const Icon(Icons.person_outline, color: Color(0xFF2563EB), size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyBarChart(bool isDark, double todayEarned) {
    final bars = [
      {'day': 'Mon', 'amount': 76.0},
      {'day': 'Tue', 'amount': 98.0},
      {'day': 'Wed', 'amount': 218.0},
      {'day': 'Thu', 'amount': todayEarned},
    ];

    const maxChartVal = 300.0;
    const chartHeight = 140.0;

    return Column(
      children: [
        // Grid Lines with Y-Axis Values
        SizedBox(
          height: chartHeight,
          child: Stack(
            children: [
              // Y-Axis markers & grid lines (₹300, ₹200, ₹100, ₹0)
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [300, 200, 100, 0].map((val) {
                  return Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: Text(
                          '₹$val',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),

              // Bars
              Padding(
                padding: const EdgeInsets.only(left: 45, right: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: bars.map((b) {
                    final amount = b['amount'] as double;
                    final barHeight = (amount / maxChartVal) * (chartHeight - 20);

                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Amount text above bar
                        Text(
                          '₹${amount.toInt()}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // Gradient Bar
                        Container(
                          width: 44,
                          height: barHeight,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF6EE7B7)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Day Labels
        Padding(
          padding: const EdgeInsets.only(left: 45, right: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: bars.map((b) {
              return Text(
                b['day'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyTile({
    required String date,
    required String ridesCount,
    required String amount,
    required bool isHighlighted,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isHighlighted
            ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFDCFCE7).withValues(alpha: 0.6))
            : (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isHighlighted
              ? const Color(0xFF86EFAC)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isHighlighted ? const Color(0xFFE0F2FE) : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.calendar_today_rounded, color: Color(0xFF2563EB), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  date,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  ridesCount,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.chevron_right_rounded, size: 20, color: Color(0xFF94A3B8)),
            ],
          ),
        ],
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
          _navItem(context, Icons.account_balance_wallet_rounded, 'Earnings', true, () {}),
          _navItem(context, Icons.person_rounded, 'Profile', false, () => context.go('/driver/profile')),
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
