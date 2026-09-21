import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_button.dart';
import '../domain/ride_notifier.dart';

class RideCompleteScreen extends ConsumerStatefulWidget {
  const RideCompleteScreen({super.key});

  @override
  ConsumerState<RideCompleteScreen> createState() => _RideCompleteScreenState();
}

class _RideCompleteScreenState extends ConsumerState<RideCompleteScreen> {
  int _selectedStars = 5;
  final List<String> _feedbackTags = ['Safe Driving 🛵', 'Punctual ⏱️', 'Clean Helmet 🪖', 'Polite Driver 😊'];
  final Set<String> _selectedTags = {'Safe Driving 🛵'};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rideState = ref.watch(rideNotifierProvider);
    final ride = rideState.currentRide;

    final fare = ride?.finalFare ?? 45.0;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Success Checkmark Badge
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 50),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ride Completed!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                'Hope you enjoyed your Payano two-wheeler commute.',
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 24),

              // Fare Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: AppRadius.borderLg,
                  boxShadow: AppShadows.cardShadow(isDark),
                ),
                child: Column(
                  children: [
                    const Text('Total Amount Payable', style: TextStyle(fontSize: 13)),
                    const SizedBox(height: 4),
                    Text(
                      '₹${fare.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.payment, color: AppColors.success, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Paid via UPI / Cash',
                            style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildTripMetric('DISTANCE', '${ride?.distanceKm ?? 6.5} km'),
                        _buildTripMetric('DURATION', '${ride?.durationMinutes.toStringAsFixed(0) ?? 18} mins'),
                        _buildTripMetric('VEHICLE', rideState.selectedCategory.title),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Rating Driver Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: AppRadius.borderLg,
                  boxShadow: AppShadows.cardShadow(isDark),
                ),
                child: Column(
                  children: [
                    Text(
                      'Rate Driver ${ride?.driverName ?? "Ramesh"}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        5,
                        (index) => IconButton(
                          icon: Icon(
                            index < _selectedStars ? Icons.star : Icons.star_border,
                            color: AppColors.primary,
                            size: 36,
                          ),
                          onPressed: () => setState(() => _selectedStars = index + 1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Feedback Tag Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _feedbackTags.map((tag) {
                        final isSelected = _selectedTags.contains(tag);
                        return FilterChip(
                          label: Text(tag),
                          selected: isSelected,
                          selectedColor: AppColors.primary.withAlpha(40),
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedTags.add(tag);
                              } else {
                                _selectedTags.remove(tag);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
              AppButton(
                text: 'Done & Back to Home',
                onPressed: () {
                  ref.read(rideNotifierProvider.notifier).resetRide();
                  context.go('/home');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTripMetric(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
