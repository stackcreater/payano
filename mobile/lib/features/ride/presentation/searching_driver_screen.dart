import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../domain/ride_notifier.dart';

class SearchingDriverScreen extends ConsumerStatefulWidget {
  const SearchingDriverScreen({super.key});

  @override
  ConsumerState<SearchingDriverScreen> createState() => _SearchingDriverScreenState();
}

class _SearchingDriverScreenState extends ConsumerState<SearchingDriverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rideState = ref.watch(rideNotifierProvider);

    // Auto navigate to active ride when driver is assigned
    if (rideState.assignedDriver != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/active-ride');
      });
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Header Title
            const Text(
              'Finding Nearby Driver',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Connecting with top rated Payano two-wheeler riders...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withAlpha(180),
              ),
            ),

            const Spacer(),

            // Radar Pulse Animation Circle
            Center(
              child: AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer Pulse Ring
                      Container(
                        width: 220 * _pulseController.value,
                        height: 220 * _pulseController.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withAlpha((100 * (1 - _pulseController.value)).toInt()),
                        ),
                      ),
                      // Inner Pulse Ring
                      Container(
                        width: 140 * _pulseController.value,
                        height: 140 * _pulseController.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primary.withAlpha((180 * (1 - _pulseController.value)).toInt()),
                        ),
                      ),
                      // Center Brand Icon
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(150),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.two_wheeler,
                          size: 50,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            const Spacer(),

            // Ride Details Card Overlay
            Container(
              margin: const EdgeInsets.all(20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: AppRadius.borderLg,
                boxShadow: AppShadows.cardShadow(isDark),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            rideState.selectedCategory.iconData,
                            color: rideState.selectedCategory.themeColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            rideState.selectedCategory.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '₹${rideState.currentRide?.finalFare.toStringAsFixed(0) ?? "45"}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.my_location, color: AppColors.success, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rideState.currentRide?.pickup.address ?? '',
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rideState.currentRide?.destination.address ?? '',
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    text: 'Cancel Request',
                    variant: AppButtonVariant.danger,
                    onPressed: () {
                      ref.read(rideNotifierProvider.notifier).cancelRide('User cancelled');
                      context.go('/home');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
