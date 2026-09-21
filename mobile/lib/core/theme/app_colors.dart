import 'package:flutter/material.dart';

class AppColors {
  // ─── Primary Blue (from Figma design) ───────────────────────────────────────
  static const Color primary = Color(0xFF2563EB);       // Vibrant Blue (button, accents)
  static const Color primaryDark = Color(0xFF1D4ED8);   // Deeper Blue (pressed state)
  static const Color primaryLight = Color(0xFF3B82F6);  // Lighter Blue
  static const Color primarySurface = Color(0xFFEBF0FF); // Very light blue (circle bg, chips)
  static const Color primaryMuted = Color(0xFFBFD3FF);  // Muted blue (inactive elements)

  // ─── Secondary / Accent ─────────────────────────────────────────────────────
  static const Color secondary = Color(0xFF60A5FA);     // Sky Blue
  static const Color secondaryDark = Color(0xFF2563EB);
  static const Color secondaryLight = Color(0xFFBADAFD);

  // ─── Backgrounds & Surfaces (Light) ─────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFFFFFFF);      // Pure White
  static const Color surfaceLight = Color(0xFFFFFFFF);          // Pure White
  static const Color surfaceVariantLight = Color(0xFFF1F5F9);   // Very light gray
  static const Color surfaceBlue = Color(0xFFEBF0FF);           // Light blue surface (circle bg)
  static const Color borderLight = Color(0xFFE2E8F0);           // Soft gray border

  // ─── Backgrounds & Surfaces (Dark) ──────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF0B1426);   // Deep Navy
  static const Color surfaceDark = Color(0xFF112244);      // Dark Blue Surface
  static const Color surfaceVariantDark = Color(0xFF1E3A6E); // Mid Navy
  static const Color borderDark = Color(0xFF2A4E9C);

  // ─── Text Colors (Light) ────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF0F172A);         // Alias for near black
  static const Color textSecondary = Color(0xFF6B7280);       // Alias for medium gray
  static const Color textPrimaryLight = Color(0xFF0F172A);    // Near black
  static const Color textSecondaryLight = Color(0xFF6B7280);  // Medium gray

  static const Color textMutedLight = Color(0xFFD1D5DB);      // Light gray (inactive dots)
  static const Color textBlueAccent = Color(0xFF2563EB);       // Blue accent text ("college")

  // ─── Text Colors (Dark) ─────────────────────────────────────────────────────
  static const Color textPrimaryDark = Color(0xFFF0F6FF);   // Near white with blue tint
  static const Color textSecondaryDark = Color(0xFF93A8D4);
  static const Color textMutedDark = Color(0xFF4A6694);

  // ─── Functional Colors ───────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);  // Green
  static const Color warning = Color(0xFFF59E0B);  // Amber
  static const Color error = Color(0xFFEF4444);    // Red
  static const Color info = Color(0xFF2563EB);     // Same as primary

  // ─── Indicator / Dot Colors ─────────────────────────────────────────────────
  static const Color dotActive = Color(0xFF2563EB);    // Active page dot (blue)
  static const Color dotInactive = Color(0xFFD1D5DB);  // Inactive page dot (gray)

  // ─── Ride Category Colors ────────────────────────────────────────────────────
  static const Color bikeLite = Color(0xFF06B6D4);     // Cyan (Scooter/Lite)
  static const Color bikeMoto = Color(0xFF2563EB);     // Blue (Standard Moto)
  static const Color bikeEV = Color(0xFF3B82F6);       // Light Blue (Electric)
  static const Color bikeExpress = Color(0xFF6366F1);  // Indigo (Priority/Express)
}
