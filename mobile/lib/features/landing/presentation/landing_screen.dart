import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ─── Payano Landing Page ───────────────────────────────────────────────────
// Shown at '/' on desktop web browsers only. Mobile users go through the
// existing splash → onboarding → login flow unchanged.
// ──────────────────────────────────────────────────────────────────────────

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  final ScrollController _scroll = ScrollController();
  final _pickupCtrl = TextEditingController();
  final _dropCtrl = TextEditingController();
  int _tabIndex = 0; // 0 = Passenger, 1 = Captain
  bool _navShadow = false;

  // ── Brand Colors ────────────────────────────────────────────────────────
  static const _navy = Color(0xFF0F172A);
  static const _slate = Color(0xFF1E293B);
  static const _blue = Color(0xFF2563EB);
  static const _blueDark = Color(0xFF1D4ED8);
  static const _skyLight = Color(0xFFEFF6FF);
  static const _skyMid = Color(0xFFDBEAFE);
  static const _skyAccent = Color(0xFF93C5FD);
  static const _muted = Color(0xFF64748B);
  static const _border = Color(0xFFE2E8F0);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final hasShadow = _scroll.offset > 10;
      if (hasShadow != _navShadow) setState(() => _navShadow = hasShadow);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _pickupCtrl.dispose();
    _dropCtrl.dispose();
    super.dispose();
  }

  void _goLogin() => context.go('/login');

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    // Landing page is designed for desktop/web. On mobile, forward to splash.
    if (!kIsWeb || w < 600) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/splash'));
      return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Scrollable content ──────────────────────────────────────────
          SingleChildScrollView(
            controller: _scroll,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 72), // nav spacer
                _HeroSection(
                  pickupCtrl: _pickupCtrl,
                  dropCtrl: _dropCtrl,
                  onBook: _goLogin,
                  blue: _blue,
                  blueDark: _blueDark,
                  skyLight: _skyLight,
                  skyMid: _skyMid,
                  skyAccent: _skyAccent,
                  navy: _navy,
                  muted: _muted,
                  border: _border,
                  screenWidth: w,
                ),
                _FleetStrip(blue: _blue, skyLight: _skyLight, navy: _navy, muted: _muted),
                _RoleSection(
                  tabIndex: _tabIndex,
                  onTab: (i) => setState(() => _tabIndex = i),
                  onCTA: _goLogin,
                  blue: _blue,
                  blueDark: _blueDark,
                  skyLight: _skyLight,
                  navy: _navy,
                  muted: _muted,
                  border: _border,
                ),
                _TrustStrip(blue: _blue, skyLight: _skyLight, navy: _navy, muted: _muted),
                _Footer(blue: _blue, navy: _navy, muted: _muted, border: _border),
              ],
            ),
          ),

          // ── Fixed top nav ───────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopNav(
              hasShadow: _navShadow,
              onLogin: _goLogin,
              blue: _blue,
              navy: _navy,
              muted: _muted,
              border: _border,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// TOP NAV
// ════════════════════════════════════════════════════════════════════════════
class _TopNav extends StatelessWidget {
  final bool hasShadow;
  final VoidCallback onLogin;
  final Color blue, navy, muted, border;

  const _TopNav({
    required this.hasShadow,
    required this.onLogin,
    required this.blue,
    required this.navy,
    required this.muted,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      height: 68,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: hasShadow
            ? [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 16, offset: const Offset(0, 2))]
            : [],
        border: Border(bottom: BorderSide(color: hasShadow ? border : Colors.transparent, width: 1)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Row(
          children: [
            // ── Logo ──────────────────────────────────────────────────────
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: blue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'PAYANO',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: blue,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // ── Nav Links ──────────────────────────────────────────────────
            ...[
              'Availability',
              'Safety',
              'Drive with Us',
              'Pricing',
            ].map(
              (label) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: muted,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 24),

            // ── CTA Button ─────────────────────────────────────────────────
            GestureDetector(
              onTap: onLogin,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                decoration: BoxDecoration(
                  color: blue,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: blue.withOpacity(0.30), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: const Text(
                  'Login / Register',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// HERO SECTION
// ════════════════════════════════════════════════════════════════════════════
class _HeroSection extends StatelessWidget {
  final TextEditingController pickupCtrl, dropCtrl;
  final VoidCallback onBook;
  final Color blue, blueDark, skyLight, skyMid, skyAccent, navy, muted, border;
  final double screenWidth;

  const _HeroSection({
    required this.pickupCtrl,
    required this.dropCtrl,
    required this.onBook,
    required this.blue,
    required this.blueDark,
    required this.skyLight,
    required this.skyMid,
    required this.skyAccent,
    required this.navy,
    required this.muted,
    required this.border,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 600,
      child: Stack(
        children: [
          // ── Diagonal sky-blue geometric ribbon (right column background) ──
          Positioned.fill(
            child: CustomPaint(painter: _DiagonalRibbonPainter(skyLight: skyLight, skyMid: skyMid, skyAccent: skyAccent)),
          ),

          // ── Content row ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Left Column (55%) ──────────────────────────────────────
                Expanded(
                  flex: 55,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status pill
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: blue.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(color: blue.withOpacity(0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.bolt_rounded, color: blue, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Live Campus & City Fleet',
                              style: TextStyle(
                                color: blue,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Headline
                      Text(
                        'Move Smarter\non Two Wheels.',
                        style: TextStyle(
                          fontSize: screenWidth > 1200 ? 60 : 48,
                          fontWeight: FontWeight.w900,
                          color: navy,
                          height: 1.08,
                          letterSpacing: -1.5,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Subheadline
                      Text(
                        "India's distinctive two-wheeler ride-hailing and bike-taxi\nplatform. Quick, secure, and affordable.",
                        style: TextStyle(
                          fontSize: 17,
                          color: muted,
                          height: 1.65,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // ── Glassmorphic Booking Dock ────────────────────────
                      _BookingDock(
                        pickupCtrl: pickupCtrl,
                        dropCtrl: dropCtrl,
                        onBook: onBook,
                        blue: blue,
                        blueDark: blueDark,
                        border: border,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 32),

                // ── Right Column (45%) — Visual ────────────────────────────
                Expanded(
                  flex: 45,
                  child: SizedBox(
                    height: 540,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Scooter illustration
                        Positioned.fill(
                          child: Center(
                            child: _ScooterIllustration(blue: blue, skyMid: skyMid),
                          ),
                        ),

                        // Pill 1 — 4-Digit OTP (top-left)
                        Positioned(
                          top: 90,
                          left: -20,
                          child: _FeaturePill(
                            icon: Icons.lock_rounded,
                            label: '4-Digit Start OTP',
                            value: '4  8  2  9',
                            dark: true,
                            blue: blue,
                          ),
                        ),

                        // Pill 2 — Captains Nearby (bottom-right)
                        Positioned(
                          bottom: 110,
                          right: 0,
                          child: _FeaturePill(
                            icon: Icons.two_wheeler_rounded,
                            label: 'Captains Nearby',
                            value: '12 Active',
                            dark: false,
                            blue: blue,
                          ),
                        ),

                        // Pill 3 — Razorpay (bottom-center)
                        Positioned(
                          bottom: 55,
                          left: 20,
                          child: _FeaturePill(
                            icon: Icons.payment_rounded,
                            label: 'Razorpay Ready',
                            value: 'UPI · Wallet · Card',
                            dark: false,
                            blue: blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Booking Dock ────────────────────────────────────────────────────────────
class _BookingDock extends StatelessWidget {
  final TextEditingController pickupCtrl, dropCtrl;
  final VoidCallback onBook;
  final Color blue, blueDark, border;

  const _BookingDock({
    required this.pickupCtrl,
    required this.dropCtrl,
    required this.onBook,
    required this.blue,
    required this.blueDark,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [
          BoxShadow(color: blue.withOpacity(0.12), blurRadius: 32, offset: const Offset(0, 8)),
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 2)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // ── Inputs ──────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _LocationInput(
                      controller: pickupCtrl,
                      hint: 'Enter Pickup Location',
                      icon: Icons.my_location_rounded,
                      iconColor: const Color(0xFF10B981),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          const SizedBox(width: 18),
                          Expanded(child: Container(height: 1, color: const Color(0xFFE2E8F0))),
                          const SizedBox(width: 10),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                              border: Border.all(color: border),
                            ),
                            child: const Icon(Icons.swap_vert_rounded, size: 14, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(child: Container(height: 1, color: const Color(0xFFE2E8F0))),
                          const SizedBox(width: 18),
                        ],
                      ),
                    ),
                    _LocationInput(
                      controller: dropCtrl,
                      hint: 'Enter Drop Location',
                      icon: Icons.location_on_rounded,
                      iconColor: const Color(0xFF2563EB),
                    ),
                  ],
                ),
              ),
            ),

            // ── Book Ride CTA ───────────────────────────────────────────
            GestureDetector(
              onTap: onBook,
              child: Container(
                width: 120,
                decoration: BoxDecoration(
                  color: blue,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 32),
                    SizedBox(height: 10),
                    Text(
                      'Book\nRide',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final Color iconColor;

  const _LocationInput({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Scooter SVG Illustration ────────────────────────────────────────────────
class _ScooterIllustration extends StatelessWidget {
  final Color blue, skyMid;
  const _ScooterIllustration({required this.blue, required this.skyMid});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      height: 320,
      child: CustomPaint(painter: _ScooterPainter(blue: blue, skyMid: skyMid)),
    );
  }
}

class _ScooterPainter extends CustomPainter {
  final Color blue, skyMid;
  const _ScooterPainter({required this.blue, required this.skyMid});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bodyPaint = Paint()..color = blue;
    final whitePaint = Paint()..color = Colors.white;
    final lightBlue = Paint()..color = skyMid;
    final darkPaint = Paint()..color = const Color(0xFF1E293B);
    final accentPaint = Paint()..color = const Color(0xFF93C5FD);
    final shadowPaint = Paint()
      ..color = blue.withOpacity(0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);

    // Shadow
    canvas.drawOval(Rect.fromCenter(center: Offset(w * 0.48, h * 0.88), width: w * 0.72, height: h * 0.08), shadowPaint);

    // Rear wheel
    canvas.drawCircle(Offset(w * 0.22, h * 0.76), 48, darkPaint);
    canvas.drawCircle(Offset(w * 0.22, h * 0.76), 36, lightBlue);
    canvas.drawCircle(Offset(w * 0.22, h * 0.76), 14, darkPaint);

    // Front wheel
    canvas.drawCircle(Offset(w * 0.76, h * 0.76), 44, darkPaint);
    canvas.drawCircle(Offset(w * 0.76, h * 0.76), 32, lightBlue);
    canvas.drawCircle(Offset(w * 0.76, h * 0.76), 12, darkPaint);

    // Body frame
    final bodyPath = Path()
      ..moveTo(w * 0.25, h * 0.70)
      ..lineTo(w * 0.20, h * 0.52)
      ..lineTo(w * 0.36, h * 0.42)
      ..lineTo(w * 0.62, h * 0.38)
      ..lineTo(w * 0.74, h * 0.52)
      ..lineTo(w * 0.74, h * 0.70)
      ..close();
    canvas.drawPath(bodyPath, bodyPaint);

    // Seat
    final seatPath = Path()
      ..moveTo(w * 0.36, h * 0.42)
      ..lineTo(w * 0.56, h * 0.36)
      ..lineTo(w * 0.60, h * 0.40)
      ..lineTo(w * 0.40, h * 0.46)
      ..close();
    canvas.drawPath(seatPath, whitePaint);

    // Handlebar area (front)
    final handlePath = Path()
      ..moveTo(w * 0.62, h * 0.38)
      ..lineTo(w * 0.68, h * 0.28)
      ..lineTo(w * 0.74, h * 0.30)
      ..lineTo(w * 0.74, h * 0.52)
      ..close();
    canvas.drawPath(handlePath, accentPaint);

    // Windscreen
    final windPath = Path()
      ..moveTo(w * 0.56, h * 0.36)
      ..lineTo(w * 0.62, h * 0.26)
      ..lineTo(w * 0.70, h * 0.28)
      ..lineTo(w * 0.68, h * 0.34)
      ..close();
    canvas.drawPath(windPath, whitePaint..color = Colors.white.withOpacity(0.80));

    // Headlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(w * 0.72, h * 0.46), width: 20, height: 14), const Radius.circular(4)),
      whitePaint..color = Colors.white,
    );

    // Brand text on body
    final tp = TextPainter(
      text: TextSpan(
        text: 'payano',
        style: TextStyle(color: Colors.white.withOpacity(0.80), fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.2),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(w * 0.36, h * 0.56));

    // Kickstand
    final kickPath = Path()
      ..moveTo(w * 0.42, h * 0.70)
      ..lineTo(w * 0.44, h * 0.78)
      ..lineTo(w * 0.48, h * 0.78)
      ..lineTo(w * 0.46, h * 0.70);
    canvas.drawPath(kickPath, darkPaint);

    // Exhaust pipe
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.22, h * 0.68, w * 0.06, 6), const Radius.circular(3)),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(_ScooterPainter old) => false;
}

// ── Feature Pills floating around scooter ───────────────────────────────────
class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool dark;
  final Color blue;

  const _FeaturePill({
    required this.icon,
    required this.label,
    required this.value,
    required this.dark,
    required this.blue,
  });

  @override
  Widget build(BuildContext context) {
    final bg = dark ? const Color(0xFF1E293B) : Colors.white;
    final primary = dark ? Colors.white : const Color(0xFF0F172A);
    final secondary = dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(dark ? 0.25 : 0.10), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: dark ? blue.withOpacity(0.20) : blue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: blue, size: 18),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(fontSize: 11, color: secondary, fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(fontSize: 14, color: primary, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Diagonal ribbon painter ─────────────────────────────────────────────────
class _DiagonalRibbonPainter extends CustomPainter {
  final Color skyLight, skyMid, skyAccent;
  const _DiagonalRibbonPainter({required this.skyLight, required this.skyMid, required this.skyAccent});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [skyAccent.withOpacity(0.55), skyMid.withOpacity(0.60), skyLight.withOpacity(0.20), Colors.transparent],
        stops: const [0.0, 0.3, 0.60, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path()
      ..moveTo(size.width * 0.42, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.28, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_DiagonalRibbonPainter old) => false;
}

// ════════════════════════════════════════════════════════════════════════════
// FLEET AVAILABILITY STRIP
// ════════════════════════════════════════════════════════════════════════════
class _FleetStrip extends StatelessWidget {
  final Color blue, skyLight, navy, muted;
  const _FleetStrip({required this.blue, required this.skyLight, required this.navy, required this.muted});

  static const _zones = [
    {
      'icon': Icons.school_rounded,
      'title': 'Campus & Tech Parks',
      'captains': '34 Captains',
      'pickup': 'Avg 3 min pickup',
      'tag': 'Most Active',
    },
    {
      'icon': Icons.train_rounded,
      'title': 'Metro & Transit Hubs',
      'captains': '21 Captains',
      'pickup': 'Avg 4 min pickup',
      'tag': 'Live',
    },
    {
      'icon': Icons.route_rounded,
      'title': 'City Express Routes',
      'captains': '18 Captains',
      'pickup': 'Avg 5 min pickup',
      'tag': 'Live',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 56),
      child: Column(
        children: [
          _SectionLabel(label: 'Live Fleet Availability', blue: blue),
          const SizedBox(height: 8),
          Text(
            'Real-time captain coverage across Salem and campus zones',
            style: TextStyle(fontSize: 16, color: muted, height: 1.5),
          ),
          const SizedBox(height: 40),
          Row(
            children: _zones.map((z) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: _ZoneCard(zone: z, blue: blue, skyLight: skyLight, navy: navy, muted: muted),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ZoneCard extends StatelessWidget {
  final Map<String, dynamic> zone;
  final Color blue, skyLight, navy, muted;
  const _ZoneCard({required this.zone, required this.blue, required this.skyLight, required this.navy, required this.muted});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: skyLight, borderRadius: BorderRadius.circular(14)),
                child: Icon(zone['icon'] as IconData, color: blue, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF16A34A), shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text(zone['tag'] as String, style: const TextStyle(color: Color(0xFF15803D), fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(zone['title'] as String, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: navy)),
          const SizedBox(height: 8),
          Text(zone['captains'] as String, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: blue)),
          const SizedBox(height: 4),
          Text(zone['pickup'] as String, style: TextStyle(fontSize: 13, color: muted)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ROLE SECTION — Passenger / Captain Tabs
// ════════════════════════════════════════════════════════════════════════════
class _RoleSection extends StatelessWidget {
  final int tabIndex;
  final ValueChanged<int> onTab;
  final VoidCallback onCTA;
  final Color blue, blueDark, skyLight, navy, muted, border;

  const _RoleSection({
    required this.tabIndex,
    required this.onTab,
    required this.onCTA,
    required this.blue,
    required this.blueDark,
    required this.skyLight,
    required this.navy,
    required this.muted,
    required this.border,
  });

  static const _passengerSteps = [
    {'num': '01', 'title': 'Create Your Account', 'desc': 'Sign up with your phone number and complete student or city rider verification in under 2 minutes.'},
    {'num': '02', 'title': 'Set Pickup & Drop', 'desc': 'Pin your exact pickup on the live map, choose from Salem quick destinations, and get an instant fare estimate.'},
    {'num': '03', 'title': 'Ride & Pay Safely', 'desc': 'Your Captain arrives with a 4-digit Start OTP. Pay via Razorpay UPI, card, or in-app wallet after a safe ride.'},
  ];

  static const _captainSteps = [
    {'num': '01', 'title': 'Register as Captain', 'desc': 'Sign up, choose the Driver-Partner role, and upload your licence, bike RC, and insurance documents.'},
    {'num': '02', 'title': 'Get Verified & Go Online', 'desc': 'Our team verifies your documents within 24 hours. Go online and start receiving ride requests near you.'},
    {'num': '03', 'title': 'Accept Rides & Earn Daily', 'desc': 'Pick up passengers, confirm with 4-digit OTP, complete trips, and withdraw earnings directly to your bank.'},
  ];

  @override
  Widget build(BuildContext context) {
    final steps = tabIndex == 0 ? _passengerSteps : _captainSteps;
    final ctaLabel = tabIndex == 0 ? 'Book Your First Ride →' : 'Start Earning Today →';

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 72),
      child: Column(
        children: [
          _SectionLabel(label: tabIndex == 0 ? 'Ride as a Passenger' : 'Earn as a Captain', blue: blue),
          const SizedBox(height: 8),
          Text(
            tabIndex == 0
                ? 'Get moving across Salem in minutes with verified Payano Captains.'
                : 'Join the Payano Captain fleet and earn flexibly on your schedule.',
            style: TextStyle(fontSize: 16, color: muted, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // ── Tab switcher ─────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.all(4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TabBtn(label: 'Ride as a Passenger', active: tabIndex == 0, onTap: () => onTab(0), blue: blue),
                _TabBtn(label: 'Earn as a Captain', active: tabIndex == 1, onTap: () => onTab(1), blue: blue),
              ],
            ),
          ),
          const SizedBox(height: 56),

          // ── 3 steps ───────────────────────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: steps.asMap().entries.map((e) {
              final i = e.key;
              final s = e.value;
              return Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _StepCard(step: s, blue: blue, navy: navy, muted: muted, skyLight: skyLight)),
                    if (i < steps.length - 1) ...[
                      const SizedBox(width: 8),
                      Padding(
                        padding: const EdgeInsets.only(top: 32),
                        child: Icon(Icons.arrow_forward_rounded, color: const Color(0xFFCBD5E1), size: 24),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 48),

          // ── CTA ───────────────────────────────────────────────────────────
          GestureDetector(
            onTap: onCTA,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
              decoration: BoxDecoration(
                color: blue,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: blue.withOpacity(0.30), blurRadius: 20, offset: const Offset(0, 6))],
              ),
              child: Text(
                ctaLabel,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color blue;
  const _TabBtn({required this.label, required this.active, required this.onTap, required this.blue});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 8, offset: const Offset(0, 2))]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? blue : const Color(0xFF64748B),
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  final Map<String, String> step;
  final Color blue, navy, muted, skyLight;
  const _StepCard({required this.step, required this.blue, required this.navy, required this.muted, required this.skyLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: blue.withOpacity(0.10), borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Text(
                step['num']!,
                style: TextStyle(color: blue, fontSize: 15, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(step['title']!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: navy)),
          const SizedBox(height: 10),
          Text(step['desc']!, style: TextStyle(fontSize: 13.5, color: muted, height: 1.65)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// TRUST & TECH STRIP
// ════════════════════════════════════════════════════════════════════════════
class _TrustStrip extends StatelessWidget {
  final Color blue, skyLight, navy, muted;
  const _TrustStrip({required this.blue, required this.skyLight, required this.navy, required this.muted});

  static const _trust = [
    {'icon': Icons.lock_rounded, 'title': '4-Digit Start OTP', 'desc': 'Cryptographic ride authorization before every trip starts.'},
    {'icon': Icons.location_on_rounded, 'title': 'Live GPS Telemetry', 'desc': 'Real-time captain tracking via Firebase & Google Maps.'},
    {'icon': Icons.payment_rounded, 'title': 'Razorpay & Wallet', 'desc': 'UPI, debit/credit card, and in-app wallet — all supported.'},
    {'icon': Icons.sos_rounded, 'title': '24/7 SOS Safety', 'desc': 'One-tap emergency alert sends your live location to contacts.'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F172A),
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 64),
      child: Column(
        children: [
          Text(
            'Built for Trust. Engineered for Speed.',
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Row(
            children: _trust.map((t) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.40), width: 1.5),
                        ),
                        child: Icon(t['icon'] as IconData, color: const Color(0xFF60A5FA), size: 28),
                      ),
                      const SizedBox(height: 16),
                      Text(t['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Text(
                        t['desc'] as String,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 13, height: 1.6),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// FOOTER
// ════════════════════════════════════════════════════════════════════════════
class _Footer extends StatelessWidget {
  final Color blue, navy, muted, border;
  const _Footer({required this.blue, required this.navy, required this.muted, required this.border});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 36),
      child: Column(
        children: [
          Divider(color: border, height: 1),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text('PAYANO', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: blue, letterSpacing: 2)),
                  const SizedBox(width: 16),
                  Text('© 2026 Payano Mobility Pvt. Ltd.', style: TextStyle(fontSize: 12, color: muted)),
                ],
              ),
              Wrap(
                spacing: 24,
                children: ['Terms of Use', 'Privacy Policy', 'API Docs', 'Download App'].map((l) {
                  return GestureDetector(
                    onTap: () {},
                    child: Text(l, style: TextStyle(fontSize: 13, color: muted, decoration: TextDecoration.underline)),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Section Label chip ──────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final Color blue;
  const _SectionLabel({required this.label, required this.blue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: blue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: blue.withOpacity(0.20)),
      ),
      child: Text(label, style: TextStyle(color: blue, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
    );
  }
}

