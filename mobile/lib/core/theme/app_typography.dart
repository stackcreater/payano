import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  static TextStyle displayLarge(bool isDark) => GoogleFonts.outfit(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        height: 1.2,
      );

  static TextStyle displayMedium(bool isDark) => GoogleFonts.outfit(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        height: 1.2,
      );

  static TextStyle headlineLarge(bool isDark) => GoogleFonts.outfit(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      );

  static TextStyle headlineMedium(bool isDark) => GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      );

  static TextStyle titleLarge(bool isDark) => GoogleFonts.inter(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      );

  static TextStyle titleMedium(bool isDark) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      );

  static TextStyle bodyLarge(bool isDark) => GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      );

  static TextStyle bodyMedium(bool isDark) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      );

  static TextStyle bodySmall(bool isDark) => GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
      );

  static TextStyle labelLarge(bool isDark) => GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      );

  static TextStyle labelSmall(bool isDark) => GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
      );
}
