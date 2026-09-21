import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum AppButtonVariant { primary, secondary, outline, text, danger }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool iconTrailing; // if true, icon goes after text (like "Next →")
  final bool isLoading;
  final bool isFullWidth;
  final double? height;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.iconTrailing = false,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 52.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color fg;
    BorderSide border = BorderSide.none;

    switch (variant) {
      case AppButtonVariant.primary:
        bg = AppColors.primary;
        fg = Colors.white; // ✅ White text on blue button
        break;
      case AppButtonVariant.secondary:
        bg = isDark ? AppColors.surfaceVariantDark : AppColors.surfaceVariantLight;
        fg = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
        break;
      case AppButtonVariant.outline:
        bg = Colors.transparent;
        fg = AppColors.primary;
        border = const BorderSide(color: AppColors.primary, width: 1.5);
        break;
      case AppButtonVariant.text:
        bg = Colors.transparent;
        fg = AppColors.primary;
        break;
      case AppButtonVariant.danger:
        bg = AppColors.error;
        fg = Colors.white;
        break;
    }

    Widget iconWidget = Icon(icon, size: 18, color: fg);

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ] else if (icon != null && !iconTrailing) ...[
          iconWidget,
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ] else if (icon != null && iconTrailing) ...[
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(width: 8),
          iconWidget,
        ] else ...[
          Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: fg,
          elevation: variant == AppButtonVariant.primary ? 0 : 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50), // ✅ Pill-shaped
            side: border,
          ),
        ),
        child: content,
      ),
    );
  }
}
