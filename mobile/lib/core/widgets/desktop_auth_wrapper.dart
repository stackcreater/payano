import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

/// Wraps any auth screen (login, signup, otp) in a centered 440px elevated
/// card on desktop web (>768px). On mobile / narrow viewports, renders child as-is.
class DesktopAuthWrapper extends StatelessWidget {
  final Widget child;
  const DesktopAuthWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (!kIsWeb || w < 768) return child;

    return Scaffold(
      backgroundColor: const Color(0xFFEFF6FF),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 48),
            child: Container(
              width: 440,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.10),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
