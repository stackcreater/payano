import 'package:flutter/material.dart';
import '../../shared/models/ride_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class DriverCard extends StatelessWidget {
  final RideModel ride;
  final VoidCallback onCallTap;
  final VoidCallback onChatTap;
  final VoidCallback onCancelTap;

  const DriverCard({
    super.key,
    required this.ride,
    required this.onCallTap,
    required this.onChatTap,
    required this.onCancelTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: AppRadius.borderLg,
        boxShadow: AppShadows.cardShadow(isDark),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Status & Start OTP Pin
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getStatusHeading(ride.status),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'Arriving in ~3 mins',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              // OTP Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  borderRadius: AppRadius.borderSm,
                  border: Border.all(color: AppColors.primary, width: 1),
                ),
                child: Column(
                  children: [
                    Text(
                      'START OTP',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                      ),
                    ),
                    Text(
                      ride.startOtp,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Driver & Vehicle Info
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 26,
                backgroundColor: AppColors.primary.withAlpha(40),
                child: const Icon(Icons.person, color: AppColors.primary, size: 30),
              ),
              const SizedBox(width: 14),

              // Driver Name & Vehicle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          ride.driverName ?? 'Payano Driver',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.star, color: AppColors.primary, size: 16),
                        const Text(
                          '4.9',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${ride.driverVehicle?.modelName ?? "Motorbike"} • ${ride.driverVehicle?.color ?? "Black"}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ride.driverVehicle?.registrationNumber ?? 'KA-01-EQ-5432',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Action Buttons: Call & Chat
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: onCallTap,
                    icon: const Icon(Icons.call, color: AppColors.primary),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary.withAlpha(30),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: onChatTap,
                    icon: const Icon(Icons.chat_bubble, color: AppColors.secondary),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.secondary.withAlpha(30),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Cancel Action
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCancelTap,
              icon: const Icon(Icons.close, color: AppColors.error, size: 18),
              label: const Text('Cancel Ride', style: TextStyle(color: AppColors.error)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusHeading(RideStatus status) {
    switch (status) {
      case RideStatus.driverArriving:
        return 'Driver is on the way!';
      case RideStatus.driverArrived:
        return 'Driver has arrived at pickup';
      case RideStatus.tripStarted:
        return 'Ride in progress 🛵';
      default:
        return 'Driver Assigned';
    }
  }
}
