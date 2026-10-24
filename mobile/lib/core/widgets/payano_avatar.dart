import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Reusable avatar widget that displays user profile photo if available,
/// or a stylish letter initial avatar (e.g. 'S' for Subash, 'K' for Karthi)
/// with smooth gradients and error fallbacks.
class PayanoAvatar extends StatelessWidget {
  final String? name;
  final String? imageUrl;
  final double radius;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final Border? border;

  const PayanoAvatar({
    super.key,
    this.name,
    this.imageUrl,
    this.radius = 24.0,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.border,
  });

  String get _initial {
    final clean = (name ?? '').trim();
    if (clean.isEmpty) return '?';
    return clean.characters.first.toUpperCase();
  }

  // Consistent pleasant color generation based on name
  Color _resolveColor(String name) {
    if (backgroundColor != null) return backgroundColor!;
    if (name.isEmpty) return AppColors.primary;
    const colors = [
      Color(0xFF1A6DF8), // Electric Blue
      Color(0xFF0D9488), // Teal
      Color(0xFF7C3AED), // Violet
      Color(0xFFEA580C), // Orange
      Color(0xFF059669), // Emerald Green
      Color(0xFFDB2777), // Pink
      Color(0xFF4F46E5), // Indigo
      Color(0xFFD97706), // Amber
    ];
    final hash = name.codeUnits.fold(0, (acc, c) => acc + c);
    return colors[hash % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = _resolveColor(name ?? '');
    final effectiveTextColor = textColor ?? Colors.white;
    final size = radius * 2;

    Widget avatarContent;

    if (imageUrl != null && imageUrl!.trim().isNotEmpty) {
      avatarContent = Image.network(
        imageUrl!.trim(),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildInitialBadge(effectiveColor, effectiveTextColor),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildInitialBadge(effectiveColor, effectiveTextColor);
        },
      );
    } else {
      avatarContent = _buildInitialBadge(effectiveColor, effectiveTextColor);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: border ?? Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: avatarContent,
      ),
    );
  }

  Widget _buildInitialBadge(Color bgColor, Color txtColor) {
    return Container(
      color: bgColor,
      alignment: Alignment.center,
      child: Text(
        _initial,
        style: TextStyle(
          color: txtColor,
          fontSize: fontSize ?? (radius * 0.95),
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
