import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
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
  final DraggableScrollableController _sheetController = DraggableScrollableController();

  // Fare Calculation Constants: 3 km is ₹25, then each additional km adds ₹5 (PER_CURRENCY = ₹5)
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

  // Draggable sheet position extent (0.18 to 0.85)
  double _sheetExtent = 0.40;

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
    _sheetController.dispose();
    super.dispose();
  }

  /// Popup toast / notification banner
  void _showNotificationPopup(
    String title,
    String message, {
    Color color = const Color(0xFF108A4E),
    IconData icon = Icons.info_outline,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                  ),
                  Text(
                    message,
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Calculates fare using the exact rule:
  /// First 3 km is ₹25, then each additional km adds ₹5 (PER_CURRENCY = ₹5)
  double calculatePayanoFare(double distanceKm) {
    if (distanceKm <= baseKm) {
      return baseFare;
    }
    final extraKm = distanceKm - baseKm;
    return baseFare + (extraKm * perKmRate);
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

        _showNotificationPopup(
          'Live Location Updated',
          addr,
          color: const Color(0xFF2563EB),
          icon: Icons.my_location_rounded,
        );
      }
    } catch (_) {
      if (mounted) setState(() => _isGpsLoading = false);
    }
  }

  /// Move pickup location when user taps on map or drags the pickup pin
  void _updatePickupLocation(LatLng newLatLng) {
    setState(() {
      _currentLat = newLatLng.latitude;
      _currentLng = newLatLng.longitude;
      _currentAddress = 'Pickup (${newLatLng.latitude.toStringAsFixed(4)}, ${newLatLng.longitude.toStringAsFixed(4)})';
    });

    _showNotificationPopup(
      'Pickup Location Moved',
      'Set to ${newLatLng.latitude.toStringAsFixed(4)}, ${newLatLng.longitude.toStringAsFixed(4)}',
      color: const Color(0xFF108A4E),
      icon: Icons.pin_drop_rounded,
    );

    // Recalculate fare if destination is already selected
    if (_destLat != null && _destLng != null && _selectedDestTitle != null) {
      _selectDestination(
        title: _selectedDestTitle!,
        subtitle: _selectedDestAddress ?? '',
        lat: _destLat!,
        lng: _destLng!,
      );
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

    // Initial distance calculation (with realistic road factor of 1.25x straight line)
    final straightDistKm = ref.read(locationServiceProvider).calculateDistanceKm(
      _currentLat,
      _currentLng,
      lat,
      lng,
    );
    final estimatedRoadKm = straightDistKm * 1.25;
    final fare = calculatePayanoFare(estimatedRoadKm);

    setState(() {
      _selectedDestTitle = title;
      _selectedDestAddress = subtitle;
      _destLat = lat;
      _destLng = lng;
      _calculatedDistanceKm = double.parse(estimatedRoadKm.toStringAsFixed(1));
      _calculatedFare = double.parse(fare.toStringAsFixed(0));
    });

    // Notify user of destination selected & calculated fare
    _showNotificationPopup(
      'Destination: $title',
      'Distance: ${estimatedRoadKm.toStringAsFixed(1)} km  •  Estimated Fare: ₹${fare.toInt()}',
      color: const Color(0xFF108A4E),
      icon: Icons.check_circle_outline_rounded,
    );

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
        80,
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
                        _showNotificationPopup(
                          'Driver Mode Enabled',
                          'Switched to Payano Driver Dashboard.',
                          color: const Color(0xFF2563EB),
                          icon: Icons.two_wheeler_rounded,
                        );
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktopWeb = screenWidth >= 768;

    // Listen to real-time ride status events and show popup notifications
    ref.listen<RideState>(rideNotifierProvider, (previous, next) {
      final prevStatus = previous?.currentRide?.status;
      final currentStatus = next.currentRide?.status;
      if (prevStatus != currentStatus && currentStatus != null) {
        if (currentStatus == RideStatus.searching) {
          _showNotificationPopup(
            'Ride Requested',
            'Searching for nearby verified Payano drivers...',
            color: const Color(0xFF2563EB),
            icon: Icons.radar_rounded,
          );
        } else if (currentStatus == RideStatus.driverArriving) {
          _showNotificationPopup(
            'Driver Matched!',
            '${next.assignedDriver?.name ?? "Driver"} is on the way with ${next.assignedDriver?.vehicle.modelName ?? "Bike"}.',
            color: const Color(0xFF108A4E),
            icon: Icons.two_wheeler_rounded,
          );
        } else if (currentStatus == RideStatus.inTrip) {
          _showNotificationPopup(
            'Trip in Progress',
            'Heading to ${next.destination?.landmark ?? "destination"}.',
            color: const Color(0xFF108A4E),
            icon: Icons.navigation_rounded,
          );
        } else if (currentStatus == RideStatus.completed) {
          _showNotificationPopup(
            'Ride Completed',
            'You arrived safely at your destination!',
            color: const Color(0xFF108A4E),
            icon: Icons.check_circle_outline_rounded,
          );
        }
      }
    });

    // Build markers for GoogleMap
    final markers = <Marker>{};

    // User Movable Pickup Marker (Attached to exact GPS location)
    markers.add(
      Marker(
        markerId: const MarkerId('user_pickup_marker'),
        position: LatLng(_currentLat, _currentLng),
        draggable: true,
        infoWindow: InfoWindow(
          title: '📍 Pickup Point',
          snippet: _currentAddress,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        onDragEnd: (newPosition) => _updatePickupLocation(newPosition),
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
      backgroundColor: Colors.transparent, // Ensures Google Map renders cleanly on Web
      bottomNavigationBar: isDesktopWeb ? null : _buildBottomNavigationBar(isDark),
      body: Stack(
        children: [
          // ── 1. Full Screen Interactive Google Map ────────────────────────
          Positioned.fill(
            child: GoogleMap(
              key: const ValueKey('payano_google_map_view'),
              initialCameraPosition: CameraPosition(
                target: LatLng(_currentLat, _currentLng),
                zoom: 14.8,
              ),
              markers: markers,
              polylines: _polylines,
              myLocationEnabled: !kIsWeb,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              compassEnabled: true,
              mapToolbarEnabled: false,
              onMapCreated: (controller) => _mapController = controller,
              onTap: (latLng) => _updatePickupLocation(latLng),
            ),
          ),

          // ── 2. Top Header Bar (Brand + Driver Mode Switch + Profile) ─────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.10),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.two_wheeler_rounded, size: 22, color: Color(0xFF108A4E)),
                        SizedBox(width: 8),
                        Text('Payano', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                            width: 40,
                            height: 40,
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
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => context.push('/profile'),
                        child: PayanoAvatar(
                          name: user?.name ?? 'User',
                          imageUrl: user?.profileImage,
                          radius: 19,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── 3. Desktop / Web Side Panel & GPS Recenter (Width >= 768px) ───
          if (isDesktopWeb) ...[
            Positioned(
              left: 24,
              top: 76,
              bottom: 24,
              width: 440,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.4 : 0.14),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: _buildPanelContent(isDark, hasDestination, null),
                ),
              ),
            ),
            Positioned(
              right: 28,
              bottom: 32,
              child: Tooltip(
                message: 'Recenter GPS',
                child: GestureDetector(
                  onTap: _fetchLiveLocation,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.20),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _isGpsLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF1E60D5)),
                            )
                          : const Icon(Icons.my_location_rounded, color: Color(0xFF1E60D5), size: 26),
                    ),
                  ),
                ),
              ),
            ),
          ],

          // ── 4. Mobile Floating Current Location Card & GPS Button ────────
          if (!isDesktopWeb)
            Positioned(
              left: 16,
              right: 16,
              bottom: (MediaQuery.of(context).size.height * _sheetExtent).clamp(150.0, MediaQuery.of(context).size.height * 0.85) + 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
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
                            color: Colors.black.withOpacity(0.18),
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
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.14),
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

          // ── 5. Mobile Draggable Bottom Sheet (Width < 768px) ──────────────
          if (!isDesktopWeb)
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (notification) {
                setState(() {
                  _sheetExtent = notification.extent;
                });
                return true;
              },
              child: DraggableScrollableSheet(
                controller: _sheetController,
                initialChildSize: hasDestination ? 0.48 : 0.40,
                minChildSize: 0.18,
                maxChildSize: 0.85,
                snap: true,
                snapSizes: const [0.18, 0.40, 0.48, 0.85],
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.4 : 0.12),
                          blurRadius: 16,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: _buildPanelContent(isDark, hasDestination, scrollController),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Reusable content widget for both Mobile Draggable Sheet & Desktop Web Side Panel
  Widget _buildPanelContent(bool isDark, bool hasDestination, ScrollController? scrollController) {
    return ListView(
      controller: scrollController,
      padding: EdgeInsets.zero,
      children: [
        // Top Handle / Header
        Center(
          child: Container(
            width: 44,
            height: 5,
            margin: const EdgeInsets.only(top: 10, bottom: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),

        // Pickup Address Banner (Especially clear on desktop)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.my_location_rounded, color: Color(0xFF108A4E), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pickup Location',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                      ),
                      Text(
                        _currentAddress,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.gps_fixed_rounded, size: 18, color: Color(0xFF2563EB)),
                  onPressed: _fetchLiveLocation,
                  tooltip: 'Get Live GPS',
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 6),

        // Search Box: "Where do you want to go?"
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GestureDetector(
            onTap: () async {
              await context.push('/location-search');
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
                    color: const Color(0xFFFBBF24).withOpacity(0.28),
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

        const SizedBox(height: 10),

        // Fare Calculation Card
        if (hasDestination)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFA7F3D0), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '₹${_calculatedFare!.toInt()}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF065F46),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Estimated Fare (3 km = ₹25 + ₹5/km)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF108A4E),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        final user = ref.read(authServiceProvider).currentUser;
                        ref.read(rideNotifierProvider.notifier).requestRide(
                          passengerName: user?.name ?? 'Student Passenger',
                          passengerPhone: user?.phone ?? '+919876543210',
                        );
                        context.push('/searching-driver');
                      },
                      child: const Text('Book Ride', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
                const Divider(height: 16, color: Color(0xFFA7F3D0)),
                Row(
                  children: [
                    const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF047857)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Distance: ${_calculatedDistanceKm} km  •  Base: ₹25  •  Addl: PER_CURRENCY = ₹5/km',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Salem Destination Suggestions List
        const Padding(
          padding: EdgeInsets.fromLTRB(18, 12, 18, 6),
          child: Text(
            'Suggested in Salem',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF94A3B8),
              letterSpacing: 0.5,
            ),
          ),
        ),

        ..._recentDestinations.map((item) {
          return Column(
            children: [
              InkWell(
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
                      InkWell(
                        onTap: () {
                          setState(() {
                            item['isFavorite'] = !(item['isFavorite'] == true);
                          });
                          _showNotificationPopup(
                            item['isFavorite'] == true ? 'Saved to Favorites' : 'Removed from Favorites',
                            item['title'] as String,
                            color: item['isFavorite'] == true ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                            icon: item['isFavorite'] == true ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(6),
                          child: Icon(
                            item['isFavorite'] == true ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 20,
                            color: item['isFavorite'] == true ? const Color(0xFFEF4444) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Divider(height: 1, thickness: 0.8, color: Color(0xFFF1F5F9)),
              ),
            ],
          );
        }),
        const SizedBox(height: 20),
      ],
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
