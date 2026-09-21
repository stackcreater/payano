import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/payano_map_widget.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/models/user_model.dart';
import 'providers/driver_flow_provider.dart';

enum _NavTab { home, rides, earnings, profile }

class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  _NavTab _currentTab = _NavTab.home;
  String _pinInput = '';
  String? _pinError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authServiceProvider).currentUser;
      if (user != null && user.role == UserRole.driver) {
        if (user.studentVerificationStatus != 'verified') {
          context.go('/student-verification');
        } else if (user.verificationStatus != 'verified') {
          context.go('/driver/onboarding');
        }
      }
    });
  }

  MapRouteMode _resolveRouteMode(DriverTripState tripState) {
    switch (tripState) {
      case DriverTripState.navigatingToPickup:
        return MapRouteMode.navigatingToPickup;
      case DriverTripState.arrivedAtPickup:
      case DriverTripState.pinVerification:
        return MapRouteMode.arrivedAtPickup;
      case DriverTripState.inTrip:
        return MapRouteMode.inTrip;
      default:
        return MapRouteMode.idle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final flowState = ref.watch(driverFlowProvider);
    final notifier = ref.read(driverFlowProvider.notifier);

    // If active in a trip sub-state (50 to 55), render the trip layout
    final isTripFlow = flowState.tripState != DriverTripState.offline &&
        flowState.tripState != DriverTripState.onlineSearching;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        bottom: false,
        child: isTripFlow
            ? _buildTripFlowLayout(flowState, notifier)
            : _buildDashboardLayout(flowState, notifier),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ===========================================================================
  // 1. DASHBOARD LAYOUT (Screens 48: Offline & 49: Online)
  // ===========================================================================
  Widget _buildDashboardLayout(DriverFlowState flow, DriverFlowNotifier notifier) {
    final isOnline = flow.tripState == DriverTripState.onlineSearching;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Header (PAYANO Driver + Bell + Avatar)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'P A Y A N O',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.0,
                        color: Color(0xFF1A6DF8),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Driver',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _circleButton(
                      icon: Icons.notifications_none_rounded,
                      onTap: () => context.push('/notifications'),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () => context.push('/driver/profile'),
                      child: _circleButton(
                        icon: Icons.person_outline_rounded,
                        onTap: () => context.push('/driver/profile'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Documents Verified Status Banner
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: GestureDetector(
              onTap: () => context.push('/driver/documents'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: Color(0xFF16A34A), size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Documents Verified • All requirements met',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF15803D),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.edit_document, size: 12, color: Color(0xFF16A34A)),
                          SizedBox(width: 4),
                          Text(
                            'Update Docs',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main Hero Card (Screen 48: Offline / Screen 49: Online)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: isOnline
                ? _buildOnlineHeroCard(flow, notifier)
                : _buildOfflineHeroCard(flow, notifier),
          ),

          const SizedBox(height: 20),

          // Today's Overview Section Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Today's Overview",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/driver/rides'),
                  child: Row(
                    children: const [
                      Text(
                        'View all',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A6DF8),
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF1A6DF8)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 3 Stat Cards in a row (Matching Screenshot 48 & 49)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildOverviewCard(
                    icon: Icons.account_balance_wallet_rounded,
                    title: "Today's Earning",
                    value: '₹${flow.todayEarnings.toStringAsFixed(2)}',
                    subtext: 'Total earnings',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildOverviewCard(
                    icon: Icons.two_wheeler_rounded,
                    title: "Today's Rides",
                    value: '${flow.todayRides}',
                    subtext: 'Completed',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildOverviewCard(
                    icon: Icons.access_time_rounded,
                    title: 'Online Hours',
                    value: flow.onlineHours,
                    subtext: 'Time online',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Map Container (Bounded card with controls inside, exactly as in screenshot 48 & 49)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(8),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    // Vector Map
                    Positioned.fill(
                      child: PayanoMapWidget(
                        routeMode: MapRouteMode.idle,
                        isDark: false,
                        onRecenter: () {},
                      ),
                    ),

                    // Floating Location Pill (Top-Left inside Map)
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.my_location_rounded, size: 16, color: Color(0xFF1A6DF8)),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'Current Location',
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black87),
                                ),
                                Text(
                                  'Salem, Tamil Nadu',
                                  style: TextStyle(fontSize: 9, color: Color(0xFF64748B)),
                                ),
                              ],
                            ),
                            const SizedBox(width: 6),
                            const Icon(Icons.chevron_right_rounded, size: 16, color: Color(0xFF94A3B8)),
                          ],
                        ),
                      ),
                    ),

                    // Map Action Buttons (Bottom-Right INSIDE Map)
                    Positioned(
                      bottom: 14,
                      right: 14,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _mapActionButton(Icons.my_location_rounded, () {}),
                          const SizedBox(height: 8),
                          _mapActionButton(Icons.shield_outlined, () {}),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 48: OFFLINE HERO CARD
  // ===========================================================================
  Widget _buildOfflineHeroCard(DriverFlowState flow, DriverFlowNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: status dot and text + illustration
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        CircleAvatar(radius: 4, backgroundColor: Color(0xFF64748B)),
                        SizedBox(width: 6),
                        Text(
                          'You are currently',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Offline',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.black),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Go online to start\naccepting rides',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.3),
                    ),
                  ],
                ),
              ),
              // Scooter Graphic with soft blue badge
              _buildScooterIllustration(),
            ],
          ),
          const SizedBox(height: 20),

          // Large Go Online Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A6DF8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () => notifier.goOnline(),
              icon: const Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 20),
              label: const Text(
                'GO ONLINE',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // SCREEN 49: ONLINE HERO CARD
  // ===========================================================================
  Widget _buildOnlineHeroCard(DriverFlowState flow, DriverFlowNotifier notifier) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withAlpha(15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: status dot and text + illustration
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        CircleAvatar(radius: 4, backgroundColor: Color(0xFF10B981)),
                        SizedBox(width: 6),
                        Text(
                          'You are currently',
                          style: TextStyle(fontSize: 13, color: Color(0xFF059669), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Online',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Color(0xFF059669)),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'You are visible to riders\nand will receive ride\nrequests',
                      style: TextStyle(fontSize: 13, color: Color(0xFF065F46), height: 1.3),
                    ),
                  ],
                ),
              ),
              _buildScooterIllustration(),
            ],
          ),
          const SizedBox(height: 18),

          // Go Offline Button (Solid blue in Mockup 49)
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A6DF8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () => notifier.goOffline(),
              icon: const Icon(Icons.power_settings_new_rounded, color: Colors.white, size: 20),
              label: const Text(
                'GO OFFLINE',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Radar searching indicator below button
          Row(
            children: const [
              Icon(Icons.explore_outlined, color: Color(0xFF059669), size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Searching for rides...',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF065F46)),
                    ),
                    Text(
                      "We'll notify you when a rider requests a trip.",
                      style: TextStyle(fontSize: 11, color: Color(0xFF047857)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScooterIllustration() {
    return Container(
      width: 110,
      height: 95,
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 6,
            child: Container(
              width: 80,
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xFF93C5FD).withAlpha(60),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const Icon(
            Icons.two_wheeler_rounded,
            size: 58,
            color: Color(0xFF1A6DF8),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtext,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: const Color(0xFF1A6DF8)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black),
          ),
          const SizedBox(height: 2),
          Text(
            subtext,
            style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. ACTIVE TRIP FLOW LAYOUT (Screens 50 to 55)
  // ===========================================================================
  Widget _buildTripFlowLayout(DriverFlowState flow, DriverFlowNotifier notifier) {
    final routeMode = _resolveRouteMode(flow.tripState);

    return Stack(
      children: [
        // Live Vector Map Canvas
        Positioned.fill(
          child: PayanoMapWidget(
            routeMode: routeMode,
            isDark: false,
            onRecenter: () {},
          ),
        ),

        // Top Status Header (PAYANO + Online Pill + Bell + Avatar)
        Positioned(
          top: 8,
          left: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'P A Y A N O',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2.5, color: Color(0xFF1A6DF8)),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Text('Driver', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                                SizedBox(width: 4),
                                Text('Online', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      _circleButton(icon: Icons.notifications_none_rounded, onTap: () {}),
                      const SizedBox(width: 8),
                      _circleButton(icon: Icons.person_outline_rounded, onTap: () => context.push('/driver/profile')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Dynamic Top Banners based on Trip State
              if (flow.tripState == DriverTripState.navigatingToPickup)
                _buildTopNavigatePill(flow.activeRide),

              if (flow.tripState == DriverTripState.arrivedAtPickup || flow.tripState == DriverTripState.pinVerification)
                _buildTopArrivedBanner(),

              if (flow.tripState == DriverTripState.inTrip)
                _buildTopInTripBanner(),

              if (flow.tripState == DriverTripState.rideCompleted)
                _buildTopCompletedBanner(),
            ],
          ),
        ),

        // Bottom Sheets matching reference screenshots 50 to 55
        if (flow.tripState == DriverTripState.rideOffered)
          _buildRideRequestSheet(flow, notifier),

        if (flow.tripState == DriverTripState.navigatingToPickup)
          _buildNavigatingSheet(flow, notifier),

        if (flow.tripState == DriverTripState.arrivedAtPickup)
          _buildArrivedSheet(flow, notifier),

        if (flow.tripState == DriverTripState.pinVerification)
          _buildPinModal(flow, notifier),

        if (flow.tripState == DriverTripState.inTrip)
          _buildInTripSheet(flow, notifier),

        if (flow.tripState == DriverTripState.rideCompleted)
          _buildCompletedSheet(flow, notifier),
      ],
    );
  }

  // ===========================================================================
  // SCREEN 50: RIDE REQUEST (50.Ride Request.png)
  // ===========================================================================
  Widget _buildRideRequestSheet(DriverFlowState flow, DriverFlowNotifier notifier) {
    final ride = flow.activeRide;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 12),

            const Text('New Ride Request', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Rider Row
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFF1F5F9),
                  child: const Icon(Icons.person_outline_rounded, color: Colors.black87, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ride.riderName,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDBEAFE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text('1 Person', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Pickup & Drop Stops
            _buildStopItem(
              dotColor: const Color(0xFF10B981),
              tag: 'Pickup',
              title: ride.pickupName,
              address: ride.pickupAddress,
              distanceText: '${ride.pickupKm} km',
              timeText: '${ride.pickupMin} min',
            ),
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: SizedBox(height: 14, child: VerticalDivider(thickness: 1.5, color: Color(0xFFCBD5E1))),
            ),
            _buildStopItem(
              dotColor: const Color(0xFF1A6DF8),
              tag: 'Drop-off',
              title: ride.dropName,
              address: ride.dropAddress,
              distanceText: '${ride.dropKm} km',
              timeText: '${ride.dropMin} min',
            ),
            const SizedBox(height: 14),

            // Estimated Fare Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Estimated Fare', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        Text('₹${ride.totalFare.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 32, color: const Color(0xFFCBD5E1)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('You will earn', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        Text('₹${ride.driverEarnings.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // DECLINE / ACCEPT Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: Color(0xFF1A6DF8)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => notifier.declineRide(),
                    child: const Text('DECLINE', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A6DF8))),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A6DF8),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () => notifier.acceptRide(),
                    child: const Text('ACCEPT', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SCREEN 51: NAVIGATE TO RIDER (51.Navigate to Rider.png)
  // ===========================================================================
  Widget _buildTopNavigatePill(dynamic ride) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          const Icon(Icons.navigation_rounded, color: Color(0xFF1A6DF8), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Navigate to rider', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                Text('Head to pickup location', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: const [
              Text('3 min • 0.8 km', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF1A6DF8))),
              Text('Estimated time & distance', style: TextStyle(fontSize: 9, color: Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigatingSheet(DriverFlowState flow, DriverFlowNotifier notifier) {
    final ride = flow.activeRide;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 10),

            // Pickup Title and Call/Chat
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pickup', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Text(ride.pickupName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      const Text('Junction Main Road\nSuramangalam, Salem 636005', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                _callChatIcon(Icons.call_rounded, 'Call'),
                const SizedBox(width: 8),
                _callChatIcon(Icons.chat_bubble_rounded, 'Chat'),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Rider Row
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFF1F5F9),
                  child: const Icon(Icons.person_outline_rounded, color: Colors.black87, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(ride.riderName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(8)),
                  child: const Text('1 Person', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Pickup Note
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: Color(0xFF1A6DF8), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pickup Note', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text(ride.pickupNote, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // I've arrived button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A6DF8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => notifier.arrivedAtPickup(),
                child: const Text("I've arrived at Pickup Point", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SCREEN 52: DRIVER ARRIVED (52.Driver Arrived.png)
  // ===========================================================================
  Widget _buildTopArrivedBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: const [
          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("You've arrived!", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text('Wait for the rider and confirm pickup.', style: TextStyle(fontSize: 11, color: Color(0xFF047857))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrivedSheet(DriverFlowState flow, DriverFlowNotifier notifier) {
    final ride = flow.activeRide;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Pickup Note', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      Text(ride.pickupNote, style: const TextStyle(fontSize: 11, color: Colors.black87)),
                    ],
                  ),
                ),
                _callChatIcon(Icons.call_rounded, 'Call'),
                const SizedBox(width: 8),
                _callChatIcon(Icons.chat_bubble_rounded, 'Chat'),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),

            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: const Color(0xFFF1F5F9),
                  child: const Icon(Icons.person_outline_rounded, color: Colors.black87, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(ride.riderName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFFDBEAFE), borderRadius: BorderRadius.circular(8)),
                  child: const Text('1 Person', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF))),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Safety first row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.shield_outlined, color: Color(0xFF1A6DF8), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Safety first', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text("Make sure the rider's name matches.\nAsk for the ride PIN before starting the ride.", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A6DF8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  setState(() {
                    _pinInput = '';
                    _pinError = null;
                  });
                  notifier.openPinModal();
                },
                child: const Text('START RIDE →', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SCREEN 53: PIN VERIFICATION (53.Pin Verification.png)
  // ===========================================================================
  Widget _buildPinModal(DriverFlowState flow, DriverFlowNotifier notifier) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -6))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 14),

            // Header with Shield
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_user_outlined, color: Color(0xFF1A6DF8), size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Verify Ride PIN', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 2),
                      Text('Ask the rider for their 4 - digit ride PIN', style: TextStyle(fontSize: 13, color: Colors.black87)),
                      Text('Enter the PIN to start the ride.', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 4 PIN Boxes
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final digit = i < _pinInput.length ? _pinInput[i] : '';
                return Container(
                  width: 52,
                  height: 60,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: i == _pinInput.length
                          ? const Color(0xFF1A6DF8)
                          : (_pinError != null ? const Color(0xFFEF4444) : const Color(0xFFCBD5E1)),
                      width: i == _pinInput.length ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      digit,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }),
            ),
            if (_pinError != null) ...[
              const SizedBox(height: 8),
              Text(_pinError!, style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: 16),

            // Info Card
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: const [
                  Icon(Icons.info_outline_rounded, color: Color(0xFF1A6DF8), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('The rider will provide a 4 - digit PIN.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                        Text('Do not share this PIN with anyone.', style: TextStyle(fontSize: 10, color: Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Numeric keypad in-sheet
            _buildKeypad(notifier),
            const SizedBox(height: 14),

            // VERIFY & START RIDE Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A6DF8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  if (_pinInput.length == 4) {
                    final ok = notifier.verifyPinAndStartRide(_pinInput);
                    if (!ok) {
                      setState(() => _pinError = 'Incorrect PIN. Please try again.');
                    }
                  } else {
                    setState(() => _pinError = 'Please enter 4 digits.');
                  }
                },
                child: const Text('VERIFY & START RIDE →', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 10),

            TextButton(
              onPressed: () {
                setState(() {
                  _pinInput = '4582';
                  _pinError = null;
                });
                notifier.verifyPinAndStartRide('4582');
              },
              child: const Text("Didn't get a PIN? (Auto-fill 4582)", style: TextStyle(fontSize: 12, color: Color(0xFF1A6DF8), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad(DriverFlowNotifier notifier) {
    return Column(
      children: [
        for (var row in [
          ['1', '2', '3'],
          ['4', '5', '6'],
          ['7', '8', '9'],
          ['C', '0', '⌫']
        ])
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row.map((key) {
                return InkWell(
                  onTap: () {
                    if (key == '⌫') {
                      if (_pinInput.isNotEmpty) {
                        setState(() {
                          _pinInput = _pinInput.substring(0, _pinInput.length - 1);
                          _pinError = null;
                        });
                      }
                    } else if (key == 'C') {
                      setState(() {
                        _pinInput = '';
                        _pinError = null;
                      });
                    } else {
                      if (_pinInput.length < 4) {
                        setState(() {
                          _pinInput += key;
                          _pinError = null;
                        });
                        if (_pinInput.length == 4) {
                          notifier.verifyPinAndStartRide(_pinInput);
                        }
                      }
                    }
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: 70,
                    height: 38,
                    decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                    alignment: Alignment.center,
                    child: Text(key, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  // ===========================================================================
  // SCREEN 54: RIDE IN PROGRESS (54.Ride started - Driver.png)
  // ===========================================================================
  Widget _buildTopInTripBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: const [
          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ride in progress', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text('Heading to your destination', style: TextStyle(fontSize: 11, color: Color(0xFF047857))),
              ],
            ),
          ),
          Icon(Icons.two_wheeler_rounded, color: Color(0xFF1A6DF8), size: 28),
        ],
      ),
    );
  }

  Widget _buildInTripSheet(DriverFlowState flow, DriverFlowNotifier notifier) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(color: Color(0xFF10B981), shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Trip Started', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text('12 min • 4.2 km', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
                const Text('10:24 AM', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () => notifier.endRide(),
                child: const Text('END RIDE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.0, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // SCREEN 55: RIDE COMPLETED SUMMARY (55.Ride Completed - Driver.png)
  // ===========================================================================
  Widget _buildTopCompletedBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: const [
          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ride Completed!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
                Text('Thanks for completing the ride.', style: TextStyle(fontSize: 11, color: Color(0xFF047857))),
              ],
            ),
          ),
          Icon(Icons.two_wheeler_rounded, color: Color(0xFF1A6DF8), size: 28),
        ],
      ),
    );
  }

  Widget _buildCompletedSheet(DriverFlowState flow, DriverFlowNotifier notifier) {
    final ride = flow.activeRide;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 80, 16, 20),
      child: Column(
        children: [
          // Rider & Stops Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFEFF6FF),
                      child: const Icon(Icons.person_outline_rounded, color: Colors.black87, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rider', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        Text(ride.riderName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                _buildStopItem(
                  dotColor: const Color(0xFF10B981),
                  tag: 'Pickup',
                  title: ride.pickupName,
                  address: ride.pickupAddress,
                  distanceText: '0.8 km',
                  timeText: '3 min',
                ),
                const Padding(
                  padding: EdgeInsets.only(left: 4),
                  child: SizedBox(height: 14, child: VerticalDivider(thickness: 1.5, color: Color(0xFFCBD5E1))),
                ),
                _buildStopItem(
                  dotColor: const Color(0xFF1A6DF8),
                  tag: 'Drop-off',
                  title: ride.dropName,
                  address: ride.dropAddress,
                  distanceText: '4.2 km',
                  timeText: '12 min',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Trip Summary Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Trip Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _metricItem('Duration', '12 min'),
                    _metricItem('Distance', '4.2 km'),
                    _metricItem('Avg. Speed', '21 km/h'),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 12),

                const Text('Earnings', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Total Fare', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          SizedBox(height: 2),
                          Text('₹42.00', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: const [
                          Text('You will earn', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          SizedBox(height: 2),
                          Text('₹34.00', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.payments_outlined, size: 20, color: Color(0xFF10B981)),
                        SizedBox(width: 8),
                        Text('Payment Method\nCash', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
                      child: const Text('Paid', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Great Job banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: const [
                Icon(Icons.thumb_up_alt_rounded, color: Color(0xFF1A6DF8), size: 24),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Great job!', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      Text("You've maintained a high rating", style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // DONE Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A6DF8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () => notifier.finishTripAndReturnHome(),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('DONE', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          TextButton(
            onPressed: () => notifier.finishTripAndReturnHome(),
            child: const Text('Back to Home', style: TextStyle(fontSize: 13, color: Color(0xFF1A6DF8), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================
  static Widget _metricItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _callChatIcon(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: Colors.black87),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildStopItem({
    required Color dotColor,
    required String tag,
    required String title,
    required String address,
    required String distanceText,
    required String timeText,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(margin: const EdgeInsets.only(top: 4), width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tag, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: dotColor)),
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              Text(address, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(distanceText, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Text(timeText, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
          ],
        ),
      ],
    );
  }

  Widget _circleButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, color: Colors.black87, size: 20),
      ),
    );
  }

  Widget _mapActionButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: Colors.black.withAlpha(20), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, color: const Color(0xFF1A6DF8), size: 20),
      ),
    );
  }

  // ===========================================================================
  // BOTTOM NAVIGATION BAR
  // ===========================================================================
  Widget _buildBottomNav() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_filled, 'Home', _NavTab.home),
              _navItem(Icons.two_wheeler_outlined, 'Rides', _NavTab.rides),
              _navItem(Icons.account_balance_wallet_outlined, 'Earnings', _NavTab.earnings),
              _navItem(Icons.person_outline_rounded, 'Profile', _NavTab.profile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, _NavTab tab) {
    final isActive = _currentTab == tab;
    return GestureDetector(
      onTap: () {
        if (tab == _NavTab.rides) {
          context.push('/driver/rides');
          return;
        }
        if (tab == _NavTab.earnings) {
          context.push('/driver/earnings');
          return;
        }
        if (tab == _NavTab.profile) {
          context.push('/driver/profile');
          return;
        }
        setState(() => _currentTab = tab);
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 24,
              color: isActive ? const Color(0xFF1A6DF8) : const Color(0xFF64748B),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? const Color(0xFF1A6DF8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
