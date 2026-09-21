import 'package:flutter/material.dart';
import '../../shared/models/two_wheeler_category.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

class TwoWheelerCard extends StatelessWidget {
  final TwoWheelerCategory category;
  final bool isSelected;
  final double estimatedFare;
  final VoidCallback onTap;

  const TwoWheelerCard({
    super.key,
    required this.category,
    required this.isSelected,
    required this.estimatedFare,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.surfaceDark : Colors.white)
              : (isDark ? AppColors.surfaceDark.withAlpha(150) : AppColors.surfaceVariantLight),
          borderRadius: AppRadius.borderMd,
          border: Border.all(
            color: isSelected ? category.themeColor : Colors.transparent,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected ? AppShadows.cardShadow(isDark) : [],
        ),
        child: Row(
          children: [
            // Category Icon Badge
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: category.themeColor.withAlpha(35),
                borderRadius: AppRadius.borderMd,
              ),
              child: Icon(
                category.iconData,
                color: category.themeColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),

            // Title & Specs
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        category.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: category.themeColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          category.estimatedEtaText,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: category.themeColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Fare Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${estimatedFare.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                Text(
                  '1 Seat',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
