import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/services/websocket_location_service.dart';
import '../../../core/services/ride_service.dart';
import '../../../core/services/map_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/payano_avatar.dart';

enum RideStage { headingToPickup, arrivedAtPickup, inTrip, completed }

/// Screen for Drivers to navigate to pickup, manage trip stages, and push
/// real-time location updates to the backend.
class DriverTrackingScreen extends ConsumerStatefulWidget {
  final String rideId;
  final String driverId;
  final String passengerName;
  final String? passengerPhotoUrl;
  final String pickupAddress;
  final String dropoffAddress;
  final LatLng pickupLocation;
  final LatLng dropoffLocation;
  final LatLng initialDriverLocation;

  const DriverTrackingScreen({
    super.key,
    this.rideId = 'ride_101',
    this.driverId = 'drv_driver_01',
    this.passengerName = 'Ananya Sharma',
    this.passengerPhotoUrl,
    this.pickupAddress = 'MG Road Metro Station Exit B, Bengaluru',
    this.dropoffAddress = 'Koramangala 5th Block, Bengaluru',
    this.pickupLocation = const LatLng(12.9716, 77.5946),
    this.dropoffLocation = const LatLng(12.9352, 77.6245),
    this.initialDriverLocation = const LatLng(12.9780, 77.5900),
  });

  @override
  ConsumerState<DriverTrackingScreen> createState() => _DriverTrackingScreenState();
}

class _DriverTrackingScreenState extends ConsumerState<DriverTrackingScreen> {
  // ─── Services ──────────────────────────────────────────────────────────────
  final MapService _mapService = MapService();
  final WebSocketLocationService _wsService = WebSocketLocationService();
  late final RideService _rideService = ref.read(rideServiceProvider);
  late final LocationService _locationService = ref.read(locationServiceProvider);

  // ─── Map State ─────────────────────────────────────────────────────────────
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  // ─── Timers & Streams ──────────────────────────────────────────────────────
  Timer? _locationPushTimer;
  Timer? _routeRecalculateTimer;
  StreamSubscription<Position>? _positionStreamSub;

  // ─── State ─────────────────────────────────────────────────────────────────
  LatLng? _currentDriverLocation;
  double _driverHeading = 0.0;
  RouteResult _currentRoute = RouteResult.empty();
  bool _isLoadingRoute = true;
  bool _isTransitioning = false;
  RideStage _currentStage = RideStage.headingToPickup;

  @override
  void initState() {
    super.initState();
    _currentDriverLocation = widget.initialDriverLocation;
    _initDeviceLocation();
  }

  /// Check GPS permission and initialize with device location if available
  Future<void> _initDeviceLocation() async {
    try {
      final pos = await _locationService.getCurrentPosition();
      final lat = pos['latitude'] as double?;
      final lng = pos['longitude'] as double?;
      if (lat != null && lng != null && mounted) {
        debugPrint('[DriverTracking] Real GPS accessed: lat=$lat, lng=$lng');
        setState(() {
          _currentDriverLocation = LatLng(lat, lng);
        });
        _rebuildMarkers();
        _fetchRoute();
      }
    } catch (e) {
      debugPrint('[DriverTracking] GPS access fallback to initial: $e');
    }
  }

  @override
  void dispose() {
    _locationPushTimer?.cancel();
    _routeRecalculateTimer?.cancel();
    _positionStreamSub?.cancel();
    _mapController?.dispose();
    _wsService.dispose();
    super.dispose();
  }

  // ─── Map Lifecycle ─────────────────────────────────────────────────────────

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _rebuildMarkers();
    _fetchRoute();

    // Connect to ride WebSocket room
    _wsService.streamRideEvents(widget.rideId, driverId: widget.driverId);

    // Start pushing GPS location via WebSocket (every 6 seconds)
    _startLocationPusher();

    // Periodic route recalculation every 25s
    _routeRecalculateTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      _fetchRoute();
    });
  }

  void _rebuildMarkers() {
    final markers = <Marker>{};

    // 1. Passenger pickup marker (Green)
    markers.add(
      Marker(
        markerId: const MarkerId('pickup_marker'),
        position: widget.pickupLocation,
        infoWindow: InfoWindow(
          title: 'Pickup Point',
          snippet: widget.passengerName,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    // 2. Dropoff destination marker (Red)
    markers.add(
      Marker(
        markerId: const MarkerId('dropoff_marker'),
        position: widget.dropoffLocation,
        infoWindow: InfoWindow(
          title: 'Drop-off Destination',
          snippet: widget.dropoffAddress.split(',').first,
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    // 3. Driver live marker (Blue / Azure)
    if (_currentDriverLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('driver_marker'),
          position: _currentDriverLocation!,
          rotation: _driverHeading,
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Payano Pilot',
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

  // ─── Route Calculation ─────────────────────────────────────────────────────

  Future<void> _fetchRoute() async {
    if (_currentDriverLocation == null) return;

    final destination = _currentStage == RideStage.inTrip
        ? widget.dropoffLocation
        : widget.pickupLocation;

    debugPrint('[DriverTracking] Fetching route: Driver(${_currentDriverLocation!.latitude}, ${_currentDriverLocation!.longitude}) -> Target(${destination.latitude}, ${destination.longitude})');

    final result = await _mapService.calculateRoute(
      start: _currentDriverLocation!,
      destination: destination,
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
    final isTrip = _currentStage == RideStage.inTrip;
    final polyColor = isTrip ? const Color(0xFF10B981) : const Color(0xFF2563EB);

    final polyline = Polyline(
      polylineId: const PolylineId('driver_active_polyline'),
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
    points.add(_currentStage == RideStage.inTrip ? widget.dropoffLocation : widget.pickupLocation);

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

  // ─── Real-Time Location Broadcasting ──────────────────────────────────────

  void _startLocationPusher() {
    _locationPushTimer = Timer.periodic(const Duration(seconds: 6), (_) async {
      if (_currentDriverLocation == null) return;
      _wsService.sendDriverLocation(
        rideId: widget.rideId,
        driverId: widget.driverId,
        location: _currentDriverLocation!,
        heading: _driverHeading,
        speedKmH: 28.0,
      );
    });
  }

  void _simulateStepForward() {
    if (_currentRoute.points.isEmpty) return;
    final points = _currentRoute.points;
    if (points.length > 1) {
      final nextPoint = points[1];
      setState(() {
        _currentDriverLocation = nextPoint;
      });
      _rebuildMarkers();
      _mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: nextPoint, zoom: 16.0),
        ),
      );
    }
  }

  // ─── Stage Transitions ────────────────────────────────────────────────────

  Future<void> _handleStageTransition() async {
    setState(() => _isTransitioning = true);
    try {
      if (_currentStage == RideStage.headingToPickup) {
        setState(() => _currentStage = RideStage.arrivedAtPickup);
        _wsService.sendRideStatus('DRIVER_ARRIVED');
      } else if (_currentStage == RideStage.arrivedAtPickup) {
        setState(() => _currentStage = RideStage.inTrip);
        _wsService.sendRideStatus('TRIP_STARTED');
        _fetchRoute();
      } else if (_currentStage == RideStage.inTrip) {
        setState(() => _currentStage = RideStage.completed);
        _wsService.sendRideStatus('TRIP_COMPLETED');
        await _rideService.completeRide(widget.rideId, 45.0);
        if (mounted) context.go('/driver/home');
      } else {
        if (mounted) context.go('/driver/home');
      }
    } catch (e) {
      debugPrint('[DriverTracking] Transition error: $e');
    } finally {
      if (mounted) setState(() => _isTransitioning = false);
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
              target: widget.initialDriverLocation,
              zoom: 14.8,
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

          // 2. Navigation Top Bar
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.navigation, color: Colors.greenAccent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _isLoadingRoute
                            ? 'Calculating route...'
                            : '${_currentRoute.distanceKm} km to ${_currentStage == RideStage.inTrip ? "drop-off" : "pickup"} (${_currentRoute.durationMinutes.round()} min)',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // 3. Simulate GPS Step FAB (demo mode)
          Positioned(
            right: 16,
            bottom: 270,
            child: FloatingActionButton.extended(
              heroTag: 'sim_btn',
              backgroundColor: Colors.amber.shade700,
              foregroundColor: Colors.white,
              onPressed: _simulateStepForward,
              icon: const Icon(Icons.directions_run),
              label: const Text('Simulate Move'),
            ),
          ),

          // 4. Bottom Trip Control Card
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildDriverBottomCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverBottomCard() {
    String buttonText;
    IconData buttonIcon;
    Color buttonColor;

    switch (_currentStage) {
      case RideStage.headingToPickup:
        buttonText = 'Arrived at Pickup';
        buttonIcon = Icons.location_on;
        buttonColor = AppColors.primary;
        break;
      case RideStage.arrivedAtPickup:
        buttonText = 'Start Trip';
        buttonIcon = Icons.play_arrow;
        buttonColor = Colors.green.shade700;
        break;
      case RideStage.inTrip:
        buttonText = 'Complete Trip';
        buttonIcon = Icons.check_circle;
        buttonColor = Colors.purple.shade700;
        break;
      case RideStage.completed:
        buttonText = 'Return to Dashboard';
        buttonIcon = Icons.home;
        buttonColor = Colors.black87;
        break;
    }

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
            const SizedBox(height: 14),

            // Passenger info
            Row(
              children: [
                PayanoAvatar(
                  name: widget.passengerName,
                  imageUrl: widget.passengerPhotoUrl,
                  radius: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.passengerName,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const Text(' 4.9 • ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          Text(
                            _currentStage == RideStage.headingToPickup
                                ? 'Pickup Navigation'
                                : _currentStage == RideStage.arrivedAtPickup
                                    ? 'Waiting for Passenger'
                                    : _currentStage == RideStage.inTrip
                                        ? 'Trip in Progress'
                                        : 'Trip Completed',
                            style: TextStyle(
                              fontSize: 12,
                              color: buttonColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  backgroundColor: Colors.grey.shade100,
                  child: IconButton(
                    icon: const Icon(Icons.call, color: AppColors.primary),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Calling Passenger...')),
                      );
                    },
                  ),
                ),
              ],
            ),
            const Divider(height: 24),

            // Address
            Row(
              children: [
                Icon(
                  _currentStage == RideStage.headingToPickup || _currentStage == RideStage.arrivedAtPickup
                        ? Icons.my_location
                        : Icons.location_on,
                  color: _currentStage == RideStage.headingToPickup ? Colors.green : AppColors.primary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _currentStage == RideStage.headingToPickup || _currentStage == RideStage.arrivedAtPickup
                        ? widget.pickupAddress
                        : widget.dropoffAddress,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // CTA Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isTransitioning ? null : _handleStageTransition,
                icon: _isTransitioning
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Icon(buttonIcon, size: 20),
                label: Text(
                  buttonText,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
