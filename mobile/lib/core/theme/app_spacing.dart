import 'package:flutter/material.dart';

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: md, vertical: sm);
}

class AppRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double circular = 999.0;

  static const BorderRadius borderSm = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius borderMd = BorderRadius.all(Radius.circular(md));
  static const BorderRadius borderLg = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius borderXl = BorderRadius.all(Radius.circular(xl));
}

class AppShadows {
  static List<BoxShadow> cardShadow(bool isDark) {
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withAlpha(77),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withAlpha(15),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> bottomSheetShadow = [
    BoxShadow(
      color: Colors.black.withAlpha(50),
      blurRadius: 20,
      offset: const Offset(0, -4),
    ),
  ];
}
