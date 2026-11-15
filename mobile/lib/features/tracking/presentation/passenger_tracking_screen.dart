import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/services/websocket_location_service.dart';
import '../../../core/services/map_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/payano_avatar.dart';

/// Screen for Passengers to track the driver's real-time location, ETA, and ride status
class PassengerTrackingScreen extends ConsumerStatefulWidget {
  final String rideId;
  final String driverId;
  final String driverName;
  final String? driverPhotoUrl;
  final String vehicleInfo;
  final String registrationNo;
  final double driverRating;
  final LatLng passengerLocation;
  final LatLng destinationLocation;
  final LatLng initialDriverLocation;
  final String pickupAddress;
  final String destinationAddress;

  const PassengerTrackingScreen({
    super.key,
    this.rideId = 'ride_101',
    this.driverId = 'drv_driver_01',
    this.driverName = 'Payano Driver',
    this.driverPhotoUrl,
    this.vehicleInfo = 'Payano Moto (Hero Splendor+)',
    this.registrationNo = 'KA-01-ET-8821',
    this.driverRating = 4.9,
    this.passengerLocation = const LatLng(12.9716, 77.5946), // MG Road
    this.destinationLocation = const LatLng(12.9352, 77.6245), // Koramangala
    this.initialDriverLocation = const LatLng(12.9780, 77.5900),
    this.pickupAddress = 'MG Road Metro Station, Bengaluru',
    this.destinationAddress = 'Koramangala 5th Block, Bengaluru',
  });

  @override
  ConsumerState<PassengerTrackingScreen> createState() => _PassengerTrackingScreenState();
}

class _PassengerTrackingScreenState extends ConsumerState<PassengerTrackingScreen>
    with TickerProviderStateMixin {
  // ─── Services ──────────────────────────────────────────────────────────────
  final MapService _mapService = MapService();
  final WebSocketLocationService _wsService = WebSocketLocationService();
  late final LocationService _locationService = ref.read(locationServiceProvider);

  // ─── Map State ─────────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // ─── Subscriptions ─────────────────────────────────────────────────────────
  StreamSubscription<RideWebSocketEvent>? _rideEventSub;
  Timer? _routeRecalculateTimer;

  // ─── State ─────────────────────────────────────────────────────────────────
  LatLng? _currentDriverLocation;
  LatLng? _currentPassengerLocation;
  double _driverHeading = 0.0;
  RouteResult _currentRoute = RouteResult.empty();
  bool _isLoadingRoute = true;
  DateTime? _lastRouteFetchTime;
  String _rideStatus = 'DRIVER_ARRIVING';
  bool _isCompleting = false;

  // ─── Status Animation ─────────────────────────────────────────────────────
  late AnimationController _statusPulseCtrl;
  late Animation<double> _statusPulseAnim;

  @override
  void initState() {
    super.initState();
    _currentDriverLocation = widget.initialDriverLocation;
    _currentPassengerLocation = widget.passengerLocation;

    _statusPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _statusPulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(_statusPulseCtrl);

    _initPassengerLocation();
  }

  /// Automatically requests device GPS permission and fetches passenger's live position
  Future<void> _initPassengerLocation() async {
    try {
      final hasPerm = await _locationService.checkAndRequestPermission();
      if (hasPerm) {
        final pos = await _locationService.getCurrentPosition();
        final lat = pos['latitude'] as double?;
        final lng = pos['longitude'] as double?;
        if (lat != null && lng != null && mounted) {
          debugPrint('[PassengerTracking] Live GPS retrieved for Passenger: $lat, $lng');
          final newPassengerLoc = LatLng(lat, lng);
          setState(() {
            _currentPassengerLocation = newPassengerLoc;
          });
          _rebuildMarkers();
          _fetchRoute();
        }
      }
    } catch (e) {
      debugPrint('[PassengerTracking] Location error: $e');
    }
  }

  @override
  void dispose() {
    _rideEventSub?.cancel();
    _routeRecalculateTimer?.cancel();
    _mapController?.dispose();
    _statusPulseCtrl.dispose();
    _wsService.dispose();
    super.dispose();
  }

  // ─── Map Lifecycle ─────────────────────────────────────────────────────────

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _rebuildMarkers();
    _fetchRoute();
    _startRideEventListener();

    // Periodic route recalculation every 30s (throttled)
    _routeRecalculateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchRoute();
    });
  }

  void _rebuildMarkers() {
    final markers = <Marker>{};

    // 1. Passenger pickup marker (Green)
    final pLoc = _currentPassengerLocation ?? widget.passengerLocation;
    markers.add(
      Marker(
        markerId: const MarkerId('pickup_marker'),
        position: pLoc,
        infoWindow: InfoWindow(
          title: 'Pickup Location',
          snippet: widget.pickupAddress.split(",").first,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    // 2. Dropoff destination marker (Red)
    markers.add(
      Marker(
        markerId: const MarkerId('destination_marker'),
        position: widget.destinationLocation,
        infoWindow: InfoWindow(
          title: 'Drop-off Destination',
          snippet: widget.destinationAddress.split(",").first,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    // 3. Driver moving marker (Blue / Azure)
    if (_currentDriverLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver_marker'),
          position: _currentDriverLocation!,
          rotation: _driverHeading,
          infoWindow: InfoWindow(
            title: 'Driver: ${widget.driverName.split(" ").first}',
            snippet: widget.vehicleInfo,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers
          ..clear()
          ..addAll(markers);
      });
    }
  }

  // ─── Route ─────────────────────────────────────────────────────────────────

  Future<void> _fetchRoute() async {
    if (_currentDriverLocation == null) return;
    final now = DateTime.now();
    if (_lastRouteFetchTime != null &&
        now.difference(_lastRouteFetchTime!).inSeconds < 15) return;
    _lastRouteFetchTime = now;

    final isTripStarted = _rideStatus == 'TRIP_STARTED';
    final targetDestination = isTripStarted
        ? widget.destinationLocation
        : (_currentPassengerLocation ?? widget.passengerLocation);

    debugPrint('[PassengerTracking] Calculating route to ${isTripStarted ? "Drop-off" : "Pickup"}: (${targetDestination.latitude}, ${targetDestination.longitude})');

    final result = await _mapService.calculateRoute(
      start: _currentDriverLocation!,
      destination: targetDestination,
    );
    if (!mounted) return;
    setState(() {
      _currentRoute = result;
      _isLoadingRoute = false;
    });
    _drawOrUpdatePolyline(result.points);
  }

  void _drawOrUpdatePolyline(List<LatLng> points) {
    if (points.isEmpty) return;
    final isTripStarted = _rideStatus == 'TRIP_STARTED';
    final polyColor = isTripStarted ? const Color(0xFF10B981) : const Color(0xFF2563EB);

    final polyline = Polyline(
      polylineId: const PolylineId('ride_active_polyline'),
      points: points,
      color: polyColor,
      width: 5,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
    );

    if (mounted) {
      setState(() {
        _polylines
          ..clear()
          ..add(polyline);
      });
      _fitMapBounds();
    }
  }

  void _fitMapBounds() {
    if (_mapController == null) return;
    final points = <LatLng>[];
    if (_currentDriverLocation != null) points.add(_currentDriverLocation!);
    if (_currentPassengerLocation != null) points.add(_currentPassengerLocation!);
    points.add(widget.destinationLocation);

    if (points.length < 2) return;

    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 70),
    );
  }

  // ─── WebSocket Event Listener ─────────────────────────────────────────────

  void _startRideEventListener() {
    _rideEventSub = _wsService
        .streamRideEvents(
          widget.rideId,
          driverId: widget.driverId,
          fallbackRoutePoints: [widget.initialDriverLocation, widget.passengerLocation],
        )
        .listen((event) {
      switch (event) {
        case LocationUpdateEvent(:final telemetry):
          _onDriverLocationUpdate(telemetry);

        case StatusChangeEvent(:final status):
          _onRideStatusChanged(status.status);

        case RideAcceptedEvent():
          if (!mounted) return;
          setState(() => _rideStatus = 'DRIVER_ARRIVING');
      }
    });
  }

  void _onDriverLocationUpdate(DriverTelemetry telemetry) {
    if (!mounted || _mapController == null) return;
    final newLoc = telemetry.location;
    final newHeading = telemetry.heading;

    setState(() {
      _currentDriverLocation = newLoc;
      _driverHeading = newHeading;
    });

    _rebuildMarkers();

    _mapController!.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: newLoc,
          zoom: 15.2,
          tilt: 30.0,
          bearing: newHeading,
        ),
      ),
    );
  }

  void _onRideStatusChanged(String status) {
    if (!mounted) return;
    setState(() => _rideStatus = status);

    if (status == 'TRIP_STARTED') {
      _rebuildMarkers();
      _fetchRoute();
    }

    // Navigate away when ride is completed
    if ((status == 'TRIP_COMPLETED' || status == 'COMPLETED') && !_isCompleting) {
      _isCompleting = true;
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) context.go('/ride-complete');
      });
    }
  }

  // ─── Status helpers ───────────────────────────────────────────────────────

  String get _statusLabel {
    switch (_rideStatus) {
      case 'DRIVER_ARRIVING':
        return 'Driver is on the way';
      case 'DRIVER_ARRIVED':
        return 'Driver has arrived!';
      case 'TRIP_STARTED':
        return 'Trip in Progress 🛵';
      case 'TRIP_COMPLETED':
      case 'COMPLETED':
        return 'Trip Completed ✓';
      default:
        return 'Connecting to driver...';
    }
  }

  String get _statusSubLabel {
    switch (_rideStatus) {
      case 'DRIVER_ARRIVING':
        return _isLoadingRoute
            ? 'Calculating ETA...'
            : 'Arriving in approx ${_currentRoute.durationMinutes.round()} minutes (${_currentRoute.distanceKm} km away)';
      case 'DRIVER_ARRIVED':
        return 'Please proceed to pickup point';
      case 'TRIP_STARTED':
        return _isLoadingRoute
            ? 'Navigating to destination...'
            : '${_currentRoute.durationMinutes.round()} mins to drop-off (${_currentRoute.distanceKm} km)';
      default:
        return '';
    }
  }

  Color get _statusColor {
    switch (_rideStatus) {
      case 'DRIVER_ARRIVING':
        return const Color(0xFF2563EB);
      case 'DRIVER_ARRIVED':
        return const Color(0xFFF59E0B);
      case 'TRIP_STARTED':
        return const Color(0xFF10B981);
      case 'TRIP_COMPLETED':
      case 'COMPLETED':
        return const Color(0xFF059669);
      default:
        return AppColors.primary;
    }
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. GoogleMap
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.passengerLocation,
              zoom: 14.5,
            ),
            markers: _markers,
            polylines: _polylines,
            onMapCreated: _onMapCreated,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: false,
          ),

          // 2. Top: Back button + Live Status Pill
          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => context.pop(),
                  ),
                ),
                AnimatedBuilder(
                  animation: _statusPulseAnim,
                  builder: (_, __) => Opacity(
                    opacity: _rideStatus == 'DRIVER_ARRIVING' ? _statusPulseAnim.value : 1.0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(FontAwesomeIcons.motorcycle, color: _statusColor, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            _isLoadingRoute && _rideStatus == 'DRIVER_ARRIVING'
                                ? 'Calculating ETA...'
                                : _rideStatus == 'DRIVER_ARRIVING'
                                    ? '${_currentRoute.durationMinutes.round()} min • ${_currentRoute.distanceKm} km'
                                    : _statusLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // 3. Recalculate FAB
          Positioned(
            right: 16,
            bottom: 265,
            child: FloatingActionButton.small(
              heroTag: 'passenger_recalculate',
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              onPressed: _fetchRoute,
              child: const Icon(Icons.my_location),
            ),
          ),

          // 4. Bottom Driver Info Card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildDriverInfoCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Live Status Row
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Row(
                key: ValueKey(_rideStatus),
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _statusColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _rideStatus == 'DRIVER_ARRIVED'
                          ? Icons.location_on
                          : _rideStatus == 'TRIP_STARTED'
                              ? Icons.two_wheeler
                              : Icons.directions_bike,
                      color: _statusColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _statusLabel,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: _statusColor,
                          ),
                        ),
                        if (_statusSubLabel.isNotEmpty)
                          Text(
                            _statusSubLabel,
                            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Pickup & Drop-off Place Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.circle, color: Color(0xFF10B981), size: 10),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.pickupAddress,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(height: 10, child: VerticalDivider(thickness: 1, color: Colors.grey)),
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.location_on, color: Color(0xFFEF4444), size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          widget.destinationAddress,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_currentRoute.distanceKm > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDBEAFE),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${_currentRoute.distanceKm} km',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 24),

            // Driver & Vehicle Row
            Row(
              children: [
                PayanoAvatar(
                  name: widget.driverName,
                  imageUrl: widget.driverPhotoUrl,
                  radius: 26,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            widget.driverName,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 6),
                          Icon(Icons.star, color: Colors.amber.shade700, size: 15),
                          Text(
                            ' ${widget.driverRating}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.vehicleInfo,
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Text(
                    widget.registrationNo,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Calling Driver...')),
                      );
                    },
                    icon: const Icon(Icons.call, size: 18),
                    label: const Text('Call Driver'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Opening Chat...')),
                      );
                    },
                    icon: const Icon(Icons.message, size: 18),
                    label: const Text('Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
