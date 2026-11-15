import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/services/auth_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/map_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/payano_avatar.dart';
import '../../../shared/models/driver_model.dart';
import '../../../shared/models/ride_model.dart';
import '../../../shared/models/user_model.dart';
import '../../ride/domain/ride_notifier.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentNavIndex = 0;
  GoogleMapController? _mapController;
  final MapService _mapService = MapService();

  // Fare Calculation Constants (Requested: 3 km is ₹25, each additional km is ₹5, PER_CURRENCY = ₹5)
  static const double baseKm = 3.0;
  static const double baseFare = 25.0;
  static const double perKmRate = 5.0;
  static const String perCurrency = '₹5';

  // Live GPS Coordinates & Real-time Location State (Salem, Tamil Nadu)
  double _currentLat = 11.6643;
  double _currentLng = 78.1460;
  String _currentAddress = 'Suramangalam, Salem, Tamil Nadu 636005, India';
  bool _isGpsLoading = false;
  List<DriverModel> _nearbyDrivers = [];
  StreamSubscription<List<DriverModel>>? _driverSub;

  // Selected Destination State
  String? _selectedDestTitle;
  String? _selectedDestAddress;
  double? _destLat;
  double? _destLng;
  double? _calculatedDistanceKm;
  double? _calculatedFare;
  final Set<Polyline> _polylines = {};

  // Curated Popular Destinations in Salem, Tamil Nadu
  static final List<Map<String, dynamic>> _recentDestinations = [
    {
      'title': 'Sona College of Technology',
      'subtitle': 'Junction Main Road, Salem, Tamil Nadu, India',
      'lat': 11.6756,
      'lng': 78.1470,
      'isFavorite': true,
    },
    {
      'title': 'Salem Junction Railway Station',
      'subtitle': 'Suramangalam Main Road, Salem, Tamil Nadu, India',
      'lat': 11.6648,
      'lng': 78.1460,
      'isFavorite': false,
    },
    {
      'title': 'Salem New Bus Stand',
      'subtitle': 'Meyyanur Bypass Road, Salem, Tamil Nadu, India',
      'lat': 11.6620,
      'lng': 78.1570,
      'isFavorite': false,
    },
    {
      'title': 'Five Roads Junction',
      'subtitle': 'Fairlands, Salem Central, Tamil Nadu, India',
      'lat': 11.6730,
      'lng': 78.1610,
      'isFavorite': false,
    },
    {
      'title': 'AVR Roundana',
      'subtitle': 'Junction Main Road, Salem, Tamil Nadu, India',
      'lat': 11.6780,
      'lng': 78.1510,
      'isFavorite': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authServiceProvider).currentUser;
      if (user != null && user.role == UserRole.rider && user.studentVerificationStatus != 'verified') {
        context.go('/student-verification');
      }
      _fetchLiveLocation();
      _startDriverLocationStream();
    });
  }

  void _startDriverLocationStream() {
    _driverSub?.cancel();
    _driverSub = ref
        .read(locationServiceProvider)
        .streamNearbyOnlineDrivers(_currentLat, _currentLng)
        .listen((drivers) {
      if (mounted) {
        setState(() => _nearbyDrivers = drivers);
      }
    });
  }

  @override
  void dispose() {
    _driverSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  /// Calculates fare using the exact rule:
  /// First 3 km is ₹25, then each additional km is ₹5 (PER_CURRENCY = ₹5)
  double calculatePayanoFare(double distanceKm) {
    if (distanceKm <= baseKm) {
      return baseFare;
    }
    return baseFare + ((distanceKm - baseKm) * perKmRate);
  }

  Future<void> _fetchLiveLocation() async {
    if (!mounted) return;
    setState(() => _isGpsLoading = true);
    try {
      final pos = await ref.read(locationServiceProvider).getCurrentPosition();
      final lat = (pos['latitude'] as num?)?.toDouble() ?? 11.6643;
      final lng = (pos['longitude'] as num?)?.toDouble() ?? 78.1460;
      final addr = pos['address'] as String? ?? 'Suramangalam, Salem, Tamil Nadu, India';

      if (mounted) {
        setState(() {
          _currentLat = lat;
          _currentLng = lng;
          _currentAddress = addr;
          _isGpsLoading = false;
        });

        _startDriverLocationStream();

        ref.read(rideNotifierProvider.notifier).updateLiveLocation(
          latitude: lat,
          longitude: lng,
          address: addr,
        );

        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: LatLng(lat, lng), zoom: 15.0),
          ),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isGpsLoading = false);
    }
  }

  /// Select a destination from the list or search result, calculate route & fare
  Future<void> _selectDestination({
    required String title,
    required String subtitle,
    required double lat,
    required double lng,
  }) async {
    final startLatLng = LatLng(_currentLat, _currentLng);
    final destLatLng = LatLng(lat, lng);

    // Calculate straight line & road distance
    final distKm = ref.read(locationServiceProvider).calculateDistanceKm(
      _currentLat,
      _currentLng,
      lat,
      lng,
    );
    final fare = calculatePayanoFare(distKm);

    setState(() {
      _selectedDestTitle = title;
      _selectedDestAddress = subtitle;
      _destLat = lat;
      _destLng = lng;
      _calculatedDistanceKm = double.parse(distKm.toStringAsFixed(1));
      _calculatedFare = double.parse(fare.toStringAsFixed(0));
    });

    // Update ride notifier with chosen destination
    ref.read(rideNotifierProvider.notifier).setDestination(
      LocationPoint(
        address: '$title, $subtitle',
        latitude: lat,
        longitude: lng,
        landmark: title,
      ),
    );

    // Fetch real Google Maps road route
    try {
      final routeRes = await _mapService.calculateRoute(
        start: startLatLng,
        destination: destLatLng,
      );
      if (mounted && routeRes.points.isNotEmpty) {
        setState(() {
          _polylines
            ..clear()
            ..add(
              Polyline(
                polylineId: const PolylineId('active_road_route'),
                points: routeRes.points,
                color: const Color(0xFF108A4E), // Green road polyline
                width: 5,
                startCap: Cap.roundCap,
                endCap: Cap.roundCap,
              ),
            );
          if (routeRes.distanceKm > 0) {
            _calculatedDistanceKm = routeRes.distanceKm;
            _calculatedFare = double.parse(calculatePayanoFare(routeRes.distanceKm).toStringAsFixed(0));
          }
        });

        // Zoom map to show both pickup and destination
        _fitBounds(startLatLng, destLatLng);
      }
    } catch (_) {}
  }

  void _fitBounds(LatLng p1, LatLng p2) {
    if (_mapController == null) return;
    final minLat = p1.latitude < p2.latitude ? p1.latitude : p2.latitude;
    final maxLat = p1.latitude > p2.latitude ? p1.latitude : p2.latitude;
    final minLng = p1.longitude < p2.longitude ? p1.longitude : p2.longitude;
    final maxLng = p1.longitude > p2.longitude ? p1.longitude : p2.longitude;

    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(
        LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng),
        ),
        70,
      ),
    );
  }

  void _confirmSwitchToDriverMode(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceDark
          : Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFEEF4FF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.two_wheeler_rounded, size: 40, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'Switch to Driver Mode',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Ready to offer rides and earn on campus? Switch to your Driver dashboard to start accepting ride requests.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        ref.read(authServiceProvider).switchRole(UserRole.driver);
                        context.go('/driver/home');
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: const Text('Switch Now', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authServiceProvider).currentUser;

    // Build markers for GoogleMap
    final markers = <Marker>{};

    // User Pickup Marker
    markers.add(
      Marker(
        markerId: const MarkerId('user_pickup_marker'),
        position: LatLng(_currentLat, _currentLng),
        infoWindow: InfoWindow(title: 'Pickup Point', snippet: _currentAddress),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    // Destination Marker if chosen
    if (_destLat != null && _destLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination_marker'),
          position: LatLng(_destLat!, _destLng!),
          infoWindow: InfoWindow(
            title: _selectedDestTitle ?? 'Destination',
            snippet: _selectedDestAddress,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );
    }

    // Nearby online drivers
    for (final driver in _nearbyDrivers) {
      markers.add(
        Marker(
          markerId: MarkerId('driver_${driver.id}'),
          position: LatLng(driver.latitude, driver.longitude),
          infoWindow: InfoWindow(
            title: '${driver.name} (Payano Moto)',
            snippet: '★ ${driver.rating} • ${driver.vehicle.modelName}',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      );
    }

    final hasDestination = _selectedDestTitle != null && _calculatedFare != null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      bottomNavigationBar: _buildBottomNavigationBar(isDark),
      body: Stack(
        children: [
          // ── 1. Full Screen Google Map ────────────────────────────────────
          Positioned.fill(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(_currentLat, _currentLng),
                zoom: 14.8,
              ),
              markers: markers,
              polylines: _polylines,
              myLocationEnabled: false,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: false,
              mapToolbarEnabled: false,
              onMapCreated: (controller) => _mapController = controller,
            ),
          ),

          // ── 2. Top Bar (Brand + Driver Mode Switch + Profile) ─────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.two_wheeler_rounded, size: 20, color: Color(0xFF108A4E)),
                        SizedBox(width: 6),
                        Text('Payano', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ),

                  Row(
                    children: [
                      // Driver Mode Switch Icon Button
                      Tooltip(
                        message: 'Switch to Driver Mode',
                        child: InkWell(
                          onTap: () => _confirmSwitchToDriverMode(context),
                          borderRadius: BorderRadius.circular(24),
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF4FF),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary.withAlpha(80), width: 1.5),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withAlpha(isDark ? 40 : 25),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(Icons.two_wheeler_rounded, size: 20, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: PayanoAvatar(
                          name: user?.name ?? 'User',
                          imageUrl: user?.profileImage,
                          radius: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── 3. Visual Center Pickup Point Pin with Label (Exact Match) ───
          if (!hasDestination)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 150),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF108A4E), // Green
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Text(
                        'Pickup Point',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 12,
                      color: const Color(0xFF108A4E),
                    ),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF108A4E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // ── 4. Floating GPS Target Button & Pickup Address Pill ──────────
          Positioned(
            left: 16,
            right: 16,
            bottom: hasDestination ? 335 : 305,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Floating Circular GPS Button (Right Aligned)
                GestureDetector(
                  onTap: _fetchLiveLocation,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isGpsLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1E60D5)),
                            )
                          : const Icon(Icons.my_location_rounded, color: Color(0xFF1E60D5), size: 22),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Floating Current Pickup Address Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF108A4E), width: 3.5),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _currentAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── 5. Bottom Sheet (Where do you want to go? & Recents) ──────────
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: hasDestination ? 325 : 295,
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag Handle Bar
                  Container(
                    width: 44,
                    height: 4,
                    margin: const EdgeInsets.only(top: 10, bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  // Search Box: "Where do you want to go?"
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: () async {
                        final result = await context.push('/location-search');
                        // Refresh state if destination set in ride notifier
                        final rideDest = ref.read(rideNotifierProvider).destination;
                        if (rideDest != null) {
                          _selectDestination(
                            title: rideDest.landmark ?? rideDest.address.split(',').first,
                            subtitle: rideDest.address,
                            lat: rideDest.latitude,
                            lng: rideDest.longitude,
                          );
                        }
                      },
                      child: Container(
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFBBF24).withOpacity(0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search_rounded, color: Color(0xFF0F172A), size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _selectedDestTitle ?? 'Where do you want to go?',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Fare Estimation Card (Shown when a destination is chosen)
                  if (hasDestination)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFECFDF5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFA7F3D0)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      '₹${_calculatedFare!.toInt()}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF065F46),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFD1FAE5),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${_calculatedDistanceKm} km',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF047857),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'First 3 km: ₹25 • Addl: PER_CURRENCY = ₹5/km',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF047857),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF108A4E),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              final user = ref.read(authServiceProvider).currentUser;
                              ref.read(rideNotifierProvider.notifier).requestRide(
                                passengerName: user?.name ?? 'Student Passenger',
                                passengerPhone: user?.phone ?? '+919876543210',
                              );
                              context.push('/searching-driver');
                            },
                            child: const Text('Book Ride', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),

                  // Destination Suggestions List (Tiruchengode, Erode Railway Station, SSM College)
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: _recentDestinations.length,
                      separatorBuilder: (context, index) => const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Divider(height: 1, thickness: 0.8, color: Color(0xFFF1F5F9)),
                      ),
                      itemBuilder: (context, index) {
                        final item = _recentDestinations[index];
                        return InkWell(
                          onTap: () {
                            _selectDestination(
                              title: item['title'] as String,
                              subtitle: item['subtitle'] as String,
                              lat: item['lat'] as double,
                              lng: item['lng'] as double,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.history_rounded,
                                  color: Color(0xFF64748B),
                                  size: 22,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['title'] as String,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        item['subtitle'] as String,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  item['isFavorite'] == true ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                  size: 20,
                                  color: item['isFavorite'] == true ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
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
        currentIndex: _currentNavIndex.clamp(0, 3),
        onTap: (index) {
          setState(() => _currentNavIndex = index);
          if (index == 0) {
            // Home
          } else if (index == 1) {
            context.push('/history');
          } else if (index == 2) {
            context.push('/notifications');
          } else if (index == 3) {
            context.push('/profile');
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF108A4E),
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
