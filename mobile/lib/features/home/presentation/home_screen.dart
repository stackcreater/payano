import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../../core/services/map_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/location_service.dart';
import '../../../shared/models/user_model.dart';
import '../../ride/domain/ride_notifier.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentNavIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authServiceProvider).currentUser;
      if (user != null && user.role == UserRole.rider && user.studentVerificationStatus != 'verified') {
        context.go('/student-verification');
      }
    });
  }

  // Selected quick destination chip
  String _selectedDestination = 'Where are you going?';

  final List<String> _popularDestinations = [
    'Sona College of Technology',
    'Salem Junction',
    'New Bus Stand',
    'Five Roads',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authServiceProvider).currentUser;
    final locationService = ref.watch(locationServiceProvider);

    // Nearby bike drivers around Salem / current location
    final nearbyDrivers = locationService.getNearbyTwoWheelerDrivers(11.6643, 78.1460);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      bottomNavigationBar: _buildBottomNavigationBar(isDark),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP APP BAR / GREETING ROW
              _buildTopHeader(context, user, isDark),

              const SizedBox(height: 12),

              // 2. RIDER MODE / BECOME A DRIVER BANNER
              _buildDriverBanner(context, isDark),

              const SizedBox(height: 12),

              // 3. MAP VIEW WITH SALEM 2-WHEELER DRIVERS
              _buildMapView(isDark, nearbyDrivers),

              // 4. FLOATING BOOKING CARD (From / To / Estimated Fare / Find a Ride)
              _buildRideBookingCard(context, isDark),

              const SizedBox(height: 16),

              // 5. POPULAR DESTINATIONS HORIZONTAL CHIPS
              _buildPopularDestinationsSection(isDark),

              const SizedBox(height: 20),

              // 6. RECENT RIDES SECTION
              _buildRecentRidesSection(context, isDark),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 1. Top Header (Greeting, Salem dropdown, Bell, Wallet, Profile)
  // -------------------------------------------------------------
  Widget _buildTopHeader(BuildContext context, dynamic user, bool isDark) {
    final userName = (user?.name != null && user!.name.isNotEmpty) ? user.name.split(' ').first : 'Rakshak';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Greeting & Location
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Good Morning, ',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('👋', style: TextStyle(fontSize: 14)),
                ],
              ),
              const SizedBox(height: 2),
              InkWell(
                onTap: () => context.push('/location-search'),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: AppColors.primary, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Salem, Tamil Nadu',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16,
                      color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Action Icons (Notification, Wallet, Profile)
          Row(
            children: [
              _buildTopIconButton(
                icon: Icons.notifications_none_rounded,
                onTap: () => context.push('/notifications'),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildTopIconButton(
                icon: Icons.account_balance_wallet_outlined,
                onTap: () => context.push('/wallet'),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildTopIconButton(
                icon: Icons.person_outline_rounded,
                onTap: () => context.push('/profile'),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopIconButton({
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 30 : 10),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            size: 19,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // 2. Student Mode / Switch to Driver Mode Banner
  // -------------------------------------------------------------
  Widget _buildDriverBanner(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 25 : 8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF4FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student Mode',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Book rides with verified student drivers',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () {
              ref.read(authServiceProvider).switchRole(UserRole.driver);
              context.go('/driver/home');
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.two_wheeler_rounded, size: 15, color: AppColors.primary),
                  SizedBox(width: 4),
                  Text(
                    'Driver Mode',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(width: 2),
                  Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.primary),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 3. Map View with Live Driver Indicators
  // -------------------------------------------------------------
  Widget _buildMapView(bool isDark, List<dynamic> nearbyDrivers) {
    return _StudentMapSection(isDark: isDark, nearbyDrivers: nearbyDrivers);
  }

  // -------------------------------------------------------------
  // 4. Floating Booking Card (Exact Match to Figma Image)
  // -------------------------------------------------------------
  Widget _buildRideBookingCard(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // From (Current Location)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const SizedBox(height: 4),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 4),
                    ),
                  ),
                  Container(
                    width: 1.5,
                    height: 28,
                    color: const Color(0xFFCBD5E1),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'From',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Current Location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Salem, Tamil Nadu',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () {},
                child: const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 22),
              ),
            ],
          ),

          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 10),

          // To (Where are you going?)
          InkWell(
            onTap: () => context.push('/location-search'),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, color: Color(0xFF94A3B8), size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'To',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _selectedDestination,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _selectedDestination != 'Where are you going?' ? FontWeight.bold : FontWeight.w500,
                          color: _selectedDestination != 'Where are you going?'
                              ? (isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A))
                              : (isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8)),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 16),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 3 Info Badges: Estimated Fare | Pickup in | Ride Type
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF1F6FE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoBadge(
                  icon: Icons.local_offer_outlined,
                  title: 'Estimated Fare',
                  value: '₹30 - ₹45',
                  subtitle: 'Final fare may vary.',
                  isDark: isDark,
                ),
                Container(width: 1, height: 36, color: const Color(0xFFCBD5E1)),
                _buildInfoBadge(
                  icon: Icons.access_time_rounded,
                  title: 'Pickup in',
                  value: '3 - 6 min',
                  subtitle: '4 drivers nearby',
                  isDark: isDark,
                ),
                Container(width: 1, height: 36, color: const Color(0xFFCBD5E1)),
                _buildInfoBadge(
                  icon: Icons.electric_moped_outlined,
                  title: 'Ride Type',
                  value: 'Bike / Scooter',
                  subtitle: 'One rider per trip',
                  isDark: isDark,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Find a Ride Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                if (_selectedDestination == 'Where are you going?') {
                  context.push('/location-search');
                } else {
                  context.push('/searching-driver');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    'Find a Ride',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required bool isDark,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 9,
            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // 5. Popular Destinations Section
  // -------------------------------------------------------------
  Widget _buildPopularDestinationsSection(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Popular Destinations',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: () => context.push('/location-search'),
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _popularDestinations.map((destination) {
                final isSelected = _selectedDestination == destination;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDestination = destination;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withAlpha(20)
                          : (isDark ? AppColors.surfaceDark : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Text(
                      destination,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? AppColors.textPrimaryDark : const Color(0xFF334155)),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 6. Recent Rides Section
  // -------------------------------------------------------------
  Widget _buildRecentRidesSection(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Rides',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: () => context.push('/history'),
                child: const Text(
                  'See all',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 25 : 6),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Yesterday • 6:15 PM',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Completed',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF059669),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sona College of\nTechnology',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pickup',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 2,
                              color: AppColors.primary,
                            ),
                          ),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Home',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Drop - off',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20, color: Color(0xFFF1F5F9)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₹40',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                      ),
                    ),
                    InkWell(
                      onTap: () => context.push('/history'),
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // 7. Bottom Navigation Bar (Home / My Rides / Wallet / Notifications / Profile)
  // -------------------------------------------------------------
  Widget _buildBottomNavigationBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() => _currentNavIndex = index);
          if (index == 0) {
            // Home
          } else if (index == 1) {
            context.push('/history');
          } else if (index == 2) {
            context.push('/wallet');
          } else if (index == 3) {
            context.push('/notifications');
          } else if (index == 4) {
            context.push('/profile');
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.electric_moped_outlined),
            label: 'My Rides',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Wallet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none_rounded),
            label: 'Notifications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// ── Student Home: Real MapLibre map with geo-located driver markers ────────────

class _StudentMapSection extends StatefulWidget {
  final bool isDark;
  final List<dynamic> nearbyDrivers;

  const _StudentMapSection({required this.isDark, required this.nearbyDrivers});

  @override
  State<_StudentMapSection> createState() => _StudentMapSectionState();
}

class _StudentMapSectionState extends State<_StudentMapSection> {
  MapLibreMapController? _controller;

  // Nearby driver positions around Salem (real lat/lng)
  static const List<Map<String, dynamic>> _driverMarkers = [
    {'lat': 11.6780, 'lng': 78.1510, 'label': 'Annampet'},
    {'lat': 11.6648, 'lng': 78.1460, 'label': 'Salem Junction'},
    {'lat': 11.6730, 'lng': 78.1610, 'label': 'Ammapet'},
    {'lat': 11.6480, 'lng': 78.1380, 'label': 'Kondalampatti'},
    {'lat': 11.6620, 'lng': 78.1570, 'label': 'Suramangalam'},
  ];

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    _addDriverMarkers();
  }

  void _onStyleLoaded() {
    _addDriverMarkers();
  }

  Future<void> _addDriverMarkers() async {
    final ctrl = _controller;
    if (ctrl == null) return;

    // User location pulsing marker (blue dot) at Salem center
    await ctrl.addCircle(CircleOptions(
      geometry: const LatLng(11.6643, 78.1460),
      circleRadius: 10,
      circleColor: '#3B82F6',
      circleStrokeWidth: 3,
      circleStrokeColor: '#FFFFFF',
    ));

    // Nearby driver markers (orange/primary dots)
    for (final driver in _driverMarkers) {
      await ctrl.addCircle(CircleOptions(
        geometry: LatLng(driver['lat'] as double, driver['lng'] as double),
        circleRadius: 8,
        circleColor: '#F97316',
        circleStrokeWidth: 2,
        circleStrokeColor: '#FFFFFF',
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      width: double.infinity,
      decoration: const BoxDecoration(color: Color(0xFFE5EEF5)),
      child: Stack(
        children: [
          // Real OSM map
          MapLibreMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(11.6643, 78.1460),
              zoom: 13.5,
            ),
            styleString: MapService.freeMapStyle,
            myLocationEnabled: false,
            trackCameraPosition: false,
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
          ),

          // Floating GPS / Layer Action Controls on Map
          Positioned(
            right: 14,
            bottom: 14,
            child: Column(
              children: [
                _mapControlBtn(Icons.my_location, widget.isDark),
                const SizedBox(height: 8),
                _mapControlBtn(Icons.layers_outlined, widget.isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapControlBtn(IconData icon, bool isDark) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 40 : 15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Icon(icon, size: 18, color: isDark ? Colors.white : const Color(0xFF334155)),
      ),
    );
  }
}
