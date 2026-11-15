import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ─── Payano Landing Page ───────────────────────────────────────────────────
// Fully responsive web landing page. On native mobile apps (Android/iOS APK),
// it routes straight to '/splash' -> '/onboarding' -> '/login'.
// On Web (desktop, tablet, or mobile browser), it renders this modern landing.
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

  final _offersKey = GlobalKey();
  final _fleetKey = GlobalKey();
  final _rolesKey = GlobalKey();
  final _trustKey = GlobalKey();

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    }
  }

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

  void _showDownloadModal() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 24),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Payano Mobile',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: _navy,
                            ),
                          ),
                          Text(
                            'Fast Two-Wheeler Rides',
                            style: TextStyle(fontSize: 12, color: _muted),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: _muted),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _skyLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _skyMid),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: const Center(
                        child: Icon(Icons.qr_code_2_rounded, size: 36, color: _blue),
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Instant Ride Booking & Tracking',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _navy),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '4-Digit Start OTP, live GPS Captain telemetry, and fast UPI checkout.',
                            style: TextStyle(fontSize: 11, color: _muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Downloading Payano Android APK...'),
                        backgroundColor: _blue,
                      ),
                    );
                  },
                  icon: const Icon(Icons.android_rounded, size: 20),
                  label: const Text(
                    'Download Android APK',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _navy,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: _border, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Google Play Store listing coming soon!'),
                        backgroundColor: _navy,
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow_rounded, size: 20, color: Color(0xFF10B981)),
                  label: const Text(
                    'Google Play Store',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If running in a native mobile application container (Android / iOS),
    // forward directly to the mobile splash / onboarding flow.
    if (!kIsWeb) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/splash'));
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 960;
    final hPadding = screenWidth < 600 ? 18.0 : (screenWidth < 1100 ? 32.0 : 48.0);

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
                  onDownload: _showDownloadModal,
                  blue: _blue,
                  blueDark: _blueDark,
                  skyLight: _skyLight,
                  skyMid: _skyMid,
                  skyAccent: _skyAccent,
                  navy: _navy,
                  muted: _muted,
                  border: _border,
                  screenWidth: screenWidth,
                  isDesktop: isDesktop,
                  hPadding: hPadding,
                ),
                _WhatWeOfferSection(
                  key: _offersKey,
                  navy: _navy,
                  muted: _muted,
                  blue: _blue,
                  isDesktop: isDesktop,
                  hPadding: hPadding,
                ),
                _FleetStrip(
                  key: _fleetKey,
                  blue: _blue,
                  skyLight: _skyLight,
                  navy: _navy,
                  muted: _muted,
                  isDesktop: isDesktop,
                  hPadding: hPadding,
                ),
                _RoleSection(
                  key: _rolesKey,
                  tabIndex: _tabIndex,
                  onTab: (i) => setState(() => _tabIndex = i),
                  onCTA: _goLogin,
                  blue: _blue,
                  blueDark: _blueDark,
                  skyLight: _skyLight,
                  navy: _navy,
                  muted: _muted,
                  border: _border,
                  isDesktop: isDesktop,
                  hPadding: hPadding,
                ),
                _TrustStrip(
                  key: _trustKey,
                  blue: _blue,
                  skyLight: _skyLight,
                  navy: _navy,
                  muted: _muted,
                  isDesktop: isDesktop,
                  hPadding: hPadding,
                ),
                _Footer(
                  blue: _blue,
                  navy: _navy,
                  muted: _muted,
                  border: _border,
                  hPadding: hPadding,
                ),
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
              onDownload: _showDownloadModal,
              onPricing: () => _scrollTo(_offersKey),
              onAvailability: () => _scrollTo(_fleetKey),
              onSafety: () => _scrollTo(_trustKey),
              onDriveWithUs: () {
                setState(() => _tabIndex = 1);
                _scrollTo(_rolesKey);
              },
              blue: _blue,
              navy: _navy,
              muted: _muted,
              border: _border,
              screenWidth: screenWidth,
              hPadding: hPadding,
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
  final VoidCallback onDownload;
  final VoidCallback onPricing;
  final VoidCallback onAvailability;
  final VoidCallback onSafety;
  final VoidCallback onDriveWithUs;
  final Color blue, navy, muted, border;
  final double screenWidth;
  final double hPadding;

  const _TopNav({
    required this.hasShadow,
    required this.onLogin,
    required this.onDownload,
    required this.onPricing,
    required this.onAvailability,
    required this.onSafety,
    required this.onDriveWithUs,
    required this.blue,
    required this.navy,
    required this.muted,
    required this.border,
    required this.screenWidth,
    required this.hPadding,
  });

  @override
  Widget build(BuildContext context) {
    final showLinks = screenWidth >= 880;

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
        padding: EdgeInsets.symmetric(horizontal: hPadding),
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

            // ── Nav Links (shown on desktop only) ──────────────────────────
            if (showLinks) ...[
              _buildNavLink('What We Offer', onPricing),
              _buildNavLink('Availability', onAvailability),
              _buildNavLink('Safety', onSafety),
              _buildNavLink('Drive with Us', onDriveWithUs),
              const SizedBox(width: 16),
            ],

            // ── Download App Button ───────────────────────────────────────
            GestureDetector(
              onTap: onDownload,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: screenWidth < 500 ? 12 : 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(color: blue.withOpacity(0.35), width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.download_rounded, color: blue, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      screenWidth < 500 ? 'Download' : 'Download Now',
                      style: TextStyle(
                        color: blue,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 10),

            // ── Login / Register CTA Button ────────────────────────────────
            GestureDetector(
              onTap: onLogin,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: screenWidth < 500 ? 14 : 20, vertical: 9),
                decoration: BoxDecoration(
                  color: blue,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(color: blue.withOpacity(0.30), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Text(
                  screenWidth < 500 ? 'Login' : 'Login / Register',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
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

  Widget _buildNavLink(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: muted,
            ),
          ),
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
  final VoidCallback onDownload;
  final Color blue, blueDark, skyLight, skyMid, skyAccent, navy, muted, border;
  final double screenWidth;
  final bool isDesktop;
  final double hPadding;

  const _HeroSection({
    required this.pickupCtrl,
    required this.dropCtrl,
    required this.onBook,
    required this.onDownload,
    required this.blue,
    required this.blueDark,
    required this.skyLight,
    required this.skyMid,
    required this.skyAccent,
    required this.navy,
    required this.muted,
    required this.border,
    required this.screenWidth,
    required this.isDesktop,
    required this.hPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: isDesktop ? 620 : 0),
      child: Stack(
        children: [
          // ── Diagonal sky-blue geometric ribbon ──
          Positioned.fill(
            child: CustomPaint(painter: _DiagonalRibbonPainter(skyLight: skyLight, skyMid: skyMid, skyAccent: skyAccent)),
          ),

          // ── Content container ─────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: isDesktop ? 40 : 28),
            child: isDesktop ? _buildDesktopRow() : _buildMobileColumn(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left Column (55%)
        Expanded(
          flex: 55,
          child: _buildHeroTextContent(),
        ),

        const SizedBox(width: 36),

        // Right Column (45%) — 3D Centerpiece
        Expanded(
          flex: 45,
          child: _buildHero3DVisual(),
        ),
      ],
    );
  }

  Widget _buildMobileColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroTextContent(),
        const SizedBox(height: 36),
        Center(child: _buildHero3DVisual()),
      ],
    );
  }

  Widget _buildHeroTextContent() {
    return Column(
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
        const SizedBox(height: 20),

        // Headline
        Text(
          'Move Smarter\non Two Wheels.',
          style: TextStyle(
            fontSize: screenWidth > 1200 ? 56 : (screenWidth > 600 ? 44 : 36),
            fontWeight: FontWeight.w900,
            color: navy,
            height: 1.10,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 16),

        // Subheadline
        Text(
          "India's distinctive two-wheeler ride-hailing and bike-taxi platform. Quick, secure, and affordable for students and urban riders.",
          style: TextStyle(
            fontSize: screenWidth < 600 ? 15 : 16.5,
            color: muted,
            height: 1.6,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 32),

        // Glassmorphic Booking Dock
        _BookingDock(
          pickupCtrl: pickupCtrl,
          dropCtrl: dropCtrl,
          onBook: onBook,
          blue: blue,
          blueDark: blueDark,
          border: border,
          screenWidth: screenWidth,
        ),
      ],
    );
  }

  Widget _buildHero3DVisual() {
    final double imgSize = isDesktop ? (screenWidth > 1200 ? 440 : 380) : math.min(screenWidth * 0.85, 360);

    return SizedBox(
      height: imgSize + 60,
      width: imgSize + 60,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // ── The Rich 3D Artwork (User Uploaded Image) ────────────────────
          Container(
            width: imgSize,
            height: imgSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: blue.withOpacity(0.20),
                  blurRadius: 36,
                  offset: const Offset(0, 16),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/payano_hero_3d.jpg',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: skyMid,
                    child: Center(
                      child: Icon(Icons.two_wheeler_rounded, size: 80, color: blue),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Pill 1: 4-Digit Start OTP (Top-Left) ─────────────────────────
          Positioned(
            top: 20,
            left: isDesktop ? -15 : 0,
            child: _FeaturePill(
              icon: Icons.lock_rounded,
              label: '4-Digit Start OTP',
              value: '4  8  2  9',
              dark: true,
              blue: blue,
            ),
          ),

          // ── Pill 2: 12 Captains Nearby (Bottom-Right) ─────────────────────
          Positioned(
            bottom: 25,
            right: isDesktop ? -10 : 0,
            child: _FeaturePill(
              icon: Icons.two_wheeler_rounded,
              label: 'Captains Nearby',
              value: '12 Active',
              dark: false,
              blue: blue,
            ),
          ),

          // ── Pill 3: Razorpay Ready (Bottom-Left) ──────────────────────────
          Positioned(
            bottom: 5,
            left: isDesktop ? 15 : 10,
            child: _FeaturePill(
              icon: Icons.payment_rounded,
              label: 'Razorpay Ready',
              value: 'Instant UPI',
              dark: false,
              blue: blue,
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
  final double screenWidth;

  const _BookingDock({
    required this.pickupCtrl,
    required this.dropCtrl,
    required this.onBook,
    required this.blue,
    required this.blueDark,
    required this.border,
    required this.screenWidth,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = screenWidth < 520;

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
      child: isCompact ? _buildCompactVertical() : _buildStandardHorizontal(),
    );
  }

  Widget _buildStandardHorizontal() {
    return IntrinsicHeight(
      child: Row(
        children: [
          // Inputs
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _LocationInput(
                    controller: pickupCtrl,
                    hint: 'Enter Pickup Location',
                    icon: Icons.my_location_rounded,
                    iconColor: const Color(0xFF10B981),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        const SizedBox(width: 18),
                        Expanded(child: Container(height: 1, color: const Color(0xFFE2E8F0))),
                        const SizedBox(width: 10),
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                            border: Border.all(color: border),
                          ),
                          child: const Icon(Icons.swap_vert_rounded, size: 13, color: Color(0xFF64748B)),
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

          // Book Ride CTA Button
          GestureDetector(
            onTap: onBook,
            child: Container(
              width: 124,
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
                  Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 30),
                  SizedBox(height: 8),
                  Text(
                    'Book\nRide',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
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
    );
  }

  Widget _buildCompactVertical() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _LocationInput(
            controller: pickupCtrl,
            hint: 'Enter Pickup Location',
            icon: Icons.my_location_rounded,
            iconColor: const Color(0xFF10B981),
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 10),
          _LocationInput(
            controller: dropCtrl,
            hint: 'Enter Drop Location',
            icon: Icons.location_on_rounded,
            iconColor: const Color(0xFF2563EB),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: onBook,
              icon: const Icon(Icons.two_wheeler_rounded, size: 20),
              label: const Text('Book Ride Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
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
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 17),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextField(
            controller: controller,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13.5),
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

// ── Feature Pills floating around the 3D graphic ───────────────────────────
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: dark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(dark ? 0.25 : 0.10), blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: dark ? blue.withOpacity(0.20) : blue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: blue, size: 16),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: secondary, fontWeight: FontWeight.w500)),
              Text(value, style: TextStyle(fontSize: 12.5, color: primary, fontWeight: FontWeight.w700)),
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
// WHAT WE OFFER SECTION (Rapido-Inspired 3-Card Feature Showcase)
// ════════════════════════════════════════════════════════════════════════════
class _WhatWeOfferSection extends StatelessWidget {
  final Color navy, muted, blue;
  final bool isDesktop;
  final double hPadding;

  const _WhatWeOfferSection({
    required this.navy,
    required this.muted,
    required this.blue,
    required this.isDesktop,
    required this.hPadding,
  });

  static const _offers = [
    {
      'title': 'Quick Pickup',
      'desc':
          'Pickups within minutes that help you save time on every ride. A Payano captain is always nearby when you need to get moving.',
      'assetPath': 'assets/images/payano_hero_3d.jpg',
      'icon': Icons.flash_on_rounded,
      'badge': 'Under 3 Mins',
    },
    {
      'title': 'Best Fares',
      'desc':
          'Affordable prices designed for everyday student and city rides. 3 km for ₹25 flat and ₹5/km thereafter—travel more, spend less without compromising on comfort.',
      'assetPath': 'assets/images/payano_splash_logo.png',
      'icon': Icons.currency_rupee_rounded,
      'badge': '₹25 Flat Base',
    },
    {
      'title': 'Never Too Far',
      'desc':
          'Present across Salem campuses, transit hubs, and city express routes. Wherever you go, find a Payano ride close by.',
      'assetPath': 'assets/images/student_verification.jpg',
      'icon': Icons.map_rounded,
      'badge': 'Campus & City',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: isDesktop ? 64 : 44),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Headline: "What we offer" with gold underline
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What we offer',
                style: TextStyle(
                  fontSize: isDesktop ? 38 : 28,
                  fontWeight: FontWeight.w900,
                  color: navy,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 54,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B), // Vibrant Gold accent bar
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),

          // 3 Feature Cards
          if (isDesktop)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _offers.map((offer) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: _OfferCard(offer: offer, navy: navy, muted: muted, blue: blue),
                  ),
                );
              }).toList(),
            )
          else
            Column(
              children: _offers.map((offer) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: _OfferCard(offer: offer, navy: navy, muted: muted, blue: blue),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;
  final Color navy, muted, blue;

  const _OfferCard({
    required this.offer,
    required this.navy,
    required this.muted,
    required this.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image Container with smooth rounded corners and badge
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.asset(
                  offer['assetPath'] as String,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (ctx, err, stack) {
                    return Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFFEFF6FF), Color(0xFFDBEAFE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Icon(offer['icon'] as IconData, size: 54, color: blue),
                      ),
                    );
                  },
                ),
              ),

              // Floating subtle badge on image top-right
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.65),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(offer['icon'] as IconData, color: const Color(0xFFF59E0B), size: 13),
                      const SizedBox(width: 5),
                      Text(
                        offer['badge'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // Title
        Text(
          offer['title'] as String,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: navy,
            letterSpacing: -0.3,
          ),
        ),

        const SizedBox(height: 8),

        // Description
        Text(
          offer['desc'] as String,
          style: TextStyle(
            fontSize: 14,
            color: muted,
            height: 1.55,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// FLEET AVAILABILITY STRIP (Responsive)
// ════════════════════════════════════════════════════════════════════════════
class _FleetStrip extends StatelessWidget {
  final Color blue, skyLight, navy, muted;
  final bool isDesktop;
  final double hPadding;

  const _FleetStrip({
    required this.blue,
    required this.skyLight,
    required this.navy,
    required this.muted,
    required this.isDesktop,
    required this.hPadding,
  });

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
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 56),
      child: Column(
        children: [
          _SectionLabel(label: 'Live Fleet Availability', blue: blue),
          const SizedBox(height: 8),
          Text(
            'Real-time captain coverage across Salem and campus zones',
            style: TextStyle(fontSize: 16, color: muted, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          if (isDesktop)
            Row(
              children: _zones.map((z) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: _ZoneCard(zone: z, blue: blue, skyLight: skyLight, navy: navy, muted: muted),
                  ),
                );
              }).toList(),
            )
          else
            Column(
              children: _zones.map((z) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _ZoneCard(zone: z, blue: blue, skyLight: skyLight, navy: navy, muted: muted),
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
      padding: const EdgeInsets.all(24),
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
                width: 46,
                height: 46,
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
          const SizedBox(height: 18),
          Text(zone['title'] as String, style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700, color: navy)),
          const SizedBox(height: 8),
          Text(zone['captains'] as String, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: blue)),
          const SizedBox(height: 4),
          Text(zone['pickup'] as String, style: TextStyle(fontSize: 13, color: muted)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ROLE SECTION (Responsive Tabbed Passenger & Captain Flows)
// ════════════════════════════════════════════════════════════════════════════
class _RoleSection extends StatelessWidget {
  final int tabIndex;
  final ValueChanged<int> onTab;
  final VoidCallback onCTA;
  final Color blue, blueDark, skyLight, navy, muted, border;
  final bool isDesktop;
  final double hPadding;

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
    required this.isDesktop,
    required this.hPadding,
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
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 64),
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
          const SizedBox(height: 28),

          // Tab Switcher
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
          const SizedBox(height: 48),

          // 3 Steps
          if (isDesktop)
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
                        const Padding(
                          padding: EdgeInsets.only(top: 32),
                          child: Icon(Icons.arrow_forward_rounded, color: Color(0xFFCBD5E1), size: 24),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                );
              }).toList(),
            )
          else
            Column(
              children: steps.map((s) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _StepCard(step: s, blue: blue, navy: navy, muted: muted, skyLight: skyLight),
                );
              }).toList(),
            ),
          const SizedBox(height: 40),

          // CTA Button
          GestureDetector(
            onTap: onCTA,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
              decoration: BoxDecoration(
                color: blue,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: blue.withOpacity(0.30), blurRadius: 20, offset: const Offset(0, 6))],
              ),
              child: Text(
                ctaLabel,
                style: const TextStyle(color: Colors.white, fontSize: 15.5, fontWeight: FontWeight.w700),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
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
            fontSize: 13.5,
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: blue.withOpacity(0.10), borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Text(
                step['num']!,
                style: TextStyle(color: blue, fontSize: 15, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(step['title']!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: navy)),
          const SizedBox(height: 8),
          Text(step['desc']!, style: TextStyle(fontSize: 13, color: muted, height: 1.6)),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// TRUST & TECH STRIP (Responsive)
// ════════════════════════════════════════════════════════════════════════════
class _TrustStrip extends StatelessWidget {
  final Color blue, skyLight, navy, muted;
  final bool isDesktop;
  final double hPadding;

  const _TrustStrip({
    required this.blue,
    required this.skyLight,
    required this.navy,
    required this.muted,
    required this.isDesktop,
    required this.hPadding,
  });

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
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 60),
      child: Column(
        children: [
          const Text(
            'Built for Trust. Engineered for Speed.',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 44),
          if (isDesktop)
            Row(
              children: _trust.map((t) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: _buildTrustItem(t),
                  ),
                );
              }).toList(),
            )
          else
            Wrap(
              spacing: 20,
              runSpacing: 24,
              children: _trust.map((t) {
                return SizedBox(
                  width: (MediaQuery.of(context).size.width - (hPadding * 2) - 20) / 2 > 160
                      ? (MediaQuery.of(context).size.width - (hPadding * 2) - 20) / 2
                      : double.infinity,
                  child: _buildTrustItem(t),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildTrustItem(Map<String, dynamic> t) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.40), width: 1.5),
          ),
          child: Icon(t['icon'] as IconData, color: const Color(0xFF60A5FA), size: 26),
        ),
        const SizedBox(height: 14),
        Text(t['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(
          t['desc'] as String,
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5, height: 1.55),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// FOOTER (Responsive)
// ════════════════════════════════════════════════════════════════════════════
class _Footer extends StatelessWidget {
  final Color blue, navy, muted, border;
  final double hPadding;

  const _Footer({
    required this.blue,
    required this.navy,
    required this.muted,
    required this.border,
    required this.hPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 32),
      child: Column(
        children: [
          Divider(color: border, height: 1),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 20,
            runSpacing: 16,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(color: blue, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text('PAYANO', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: blue, letterSpacing: 2)),
                  const SizedBox(width: 14),
                  Text('© 2026 Payano Mobility Pvt. Ltd.', style: TextStyle(fontSize: 12, color: muted)),
                ],
              ),
              Wrap(
                spacing: 20,
                children: ['Terms of Use', 'Privacy Policy', 'API Docs', 'Download App'].map((l) {
                  return GestureDetector(
                    onTap: () {},
                    child: Text(l, style: TextStyle(fontSize: 12.5, color: muted, decoration: TextDecoration.underline)),
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
