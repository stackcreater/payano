import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final rides = [
      {
        'category': 'Payano Moto',
        'date': 'Yesterday, 6:15 PM',
        'pickup': 'MG Road Metro Station',
        'destination': 'Koramangala 4th Block',
        'fare': 45.0,
        'status': 'COMPLETED',
        'driver': 'Ramesh Driver • KA-01-EQ-5432',
      },
      {
        'category': 'Payano Green EV',
        'date': '26 Aug, 8:30 AM',
        'pickup': 'Indiranagar 100ft Road',
        'destination': 'Forum Mall, Hosur Road',
        'fare': 35.0,
        'status': 'COMPLETED',
        'driver': 'Suresh V • KA-03-EV-1902',
      },
      {
        'category': 'Payano Lite',
        'date': '24 Aug, 2:10 PM',
        'pickup': 'Jayanagar 4th Block',
        'destination': 'JP Nagar Metro',
        'fare': 25.0,
        'status': 'CANCELLED',
        'driver': 'Arun Patel',
      },
    ];

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Ride History'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All Rides'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRideList(context, rides, isDark),
            _buildRideList(context, rides.where((r) => r['status'] == 'COMPLETED').toList(), isDark),
            _buildRideList(context, rides.where((r) => r['status'] == 'CANCELLED').toList(), isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildRideList(BuildContext context, List<Map<String, dynamic>> items, bool isDark) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.two_wheeler, size: 60, color: Colors.grey),
            SizedBox(height: 12),
            Text('No rides in this category yet', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: AppSpacing.screenPadding,
      itemCount: items.length,
      itemBuilder: (context, index) {
        final r = items[index];
        final isCompleted = r['status'] == 'COMPLETED';

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: AppRadius.borderMd,
            boxShadow: AppShadows.cardShadow(isDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.two_wheeler, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r['category'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '\u20B9${(r['fare'] as double).toStringAsFixed(0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                r['date'],
                style: TextStyle(fontSize: 12, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
              ),
              const Divider(height: 20),
              Row(
                children: [
                  const Icon(Icons.my_location, color: AppColors.success, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r['pickup'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppColors.primary, size: 14),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      r['destination'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      r['driver'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isCompleted ? AppColors.success.withAlpha(30) : AppColors.error.withAlpha(30),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      r['status'],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isCompleted ? AppColors.success : AppColors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
