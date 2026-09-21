import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/services/websocket_location_service.dart';
import '../../../core/services/ride_service.dart';
import '../../../core/services/map_service.dart';
import '../../../core/theme/app_colors.dart';

enum RideStage { headingToPickup, arrivedAtPickup, inTrip, completed }

/// Screen for Drivers to navigate to pickup, manage trip stages, and push
/// real-time location updates to the FastAPI WebSocket backend.
class DriverTrackingScreen extends ConsumerStatefulWidget {
  final String rideId;
  final String driverId;
  final String passengerName;
  final String pickupAddress;
  final String dropoffAddress;
  final LatLng pickupLocation;
  final LatLng initialDriverLocation;

  const DriverTrackingScreen({
    super.key,
    this.rideId = 'ride_101',
    this.driverId = 'drv_driver_01',
    this.passengerName = 'Ananya Sharma',
    this.pickupAddress = 'MG Road Metro Station Exit B, Bengaluru',
    this.dropoffAddress = 'Koramangala 5th Block, Bengaluru',
    this.pickupLocation = const LatLng(12.9716, 77.5946),
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

  // ─── Map ───────────────────────────────────────────────────────────────────
  MapLibreMapController? _mapController;
  Symbol? _driverSymbol;
  Symbol? _passengerSymbol;
  Line? _routeLine;

  // ─── Timers ────────────────────────────────────────────────────────────────
  Timer? _locationPushTimer;
  Timer? _routeRecalculateTimer;

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
  }

  @override
  void dispose() {
    _locationPushTimer?.cancel();
    _routeRecalculateTimer?.cancel();
    _mapController?.dispose();
    _wsService.dispose();
    super.dispose();
  }

  // ─── Map Lifecycle ─────────────────────────────────────────────────────────

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
  }

  void _onStyleLoaded() async {
    if (_mapController == null) return;

    // Passenger pickup marker
    _passengerSymbol = await _mapController!.addSymbol(
      SymbolOptions(
        geometry: widget.pickupLocation,
        iconImage: 'marker-15',
        iconSize: 2.2,
        textField: 'Pickup: ${widget.passengerName}',
        textOffset: const Offset(0, 1.8),
        textColor: '#10B981',
        textHaloColor: '#FFFFFF',
        textHaloWidth: 1.5,
      ),
    );

    // Driver live marker
    _driverSymbol = await _mapController!.addSymbol(
      SymbolOptions(
        geometry: _currentDriverLocation,
        iconImage: 'airport-15',
        iconSize: 2.2,
        iconRotate: _driverHeading,
        textField: 'You',
        textOffset: const Offset(0, -1.8),
        textColor: '#2563EB',
        textHaloColor: '#FFFFFF',
        textHaloWidth: 1.5,
      ),
    );

    // Initial route calculation
    await _fetchRoute();

    // Connect to ride WebSocket room (to receive passenger pings if any)
    _wsService.streamRideEvents(widget.rideId, driverId: widget.driverId);

    // Start pushing GPS location via WebSocket (every 6 seconds)
    _startLocationPusher();

    // Periodic route recalculation every 25s
    _routeRecalculateTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      _fetchRoute();
    });
  }

  // ─── Route ─────────────────────────────────────────────────────────────────

  Future<void> _fetchRoute() async {
    if (_currentDriverLocation == null) return;

    final destination = _currentStage == RideStage.headingToPickup ||
            _currentStage == RideStage.arrivedAtPickup
        ? widget.pickupLocation
        : widget.pickupLocation; // TODO: swap to dropoff when in-trip navigation is added

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

  Future<void> _drawOrUpdatePolyline(List<LatLng> points) async {
    if (_mapController == null || points.isEmpty) return;
    if (_routeLine == null) {
      _routeLine = await _mapController!.addLine(
        LineOptions(
          geometry: points,
          lineColor: '#2563EB',
          lineWidth: 5.5,
          lineOpacity: 0.85,
          lineJoin: 'round',
        ),
      );
    } else {
      await _mapController!.updateLine(_routeLine!, LineOptions(geometry: points));
    }
  }

  // ─── Location Push ─────────────────────────────────────────────────────────

  /// Throttled periodic GPS push to FastAPI WebSocket backend
  void _startLocationPusher() {
    _locationPushTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (_currentDriverLocation != null) {
        _wsService.sendDriverLocation(
          driverId: widget.driverId,
          location: _currentDriverLocation!,
          heading: _driverHeading,
          rideId: widget.rideId,
        );
      }
    });
  }

  // ─── Simulation step (demo / testing) ─────────────────────────────────────

  void _simulateStepForward() {
    if (_currentDriverLocation == null) return;
    final target = widget.pickupLocation;
    final newLat = _currentDriverLocation!.latitude +
        (target.latitude - _currentDriverLocation!.latitude) * 0.25;
    final newLng = _currentDriverLocation!.longitude +
        (target.longitude - _currentDriverLocation!.longitude) * 0.25;
    final newLoc = LatLng(newLat, newLng);

    setState(() => _currentDriverLocation = newLoc);

    if (_driverSymbol != null && _mapController != null) {
      _mapController!.updateSymbol(_driverSymbol!, SymbolOptions(geometry: newLoc));
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: newLoc, zoom: 15.5)),
      );
    }

    // Force-push updated location via WebSocket
    _wsService.sendDriverLocation(
      driverId: widget.driverId,
      location: newLoc,
      heading: _driverHeading,
      forceImmediate: true,
      rideId: widget.rideId,
    );

    _fetchRoute();
  }

  // ─── Stage Transition ──────────────────────────────────────────────────────

  Future<void> _handleStageTransition() async {
    if (_isTransitioning) return;
    setState(() => _isTransitioning = true);

    try {
      switch (_currentStage) {
        case RideStage.headingToPickup:
          // Notify backend: driver has arrived at pickup
          _wsService.sendRideStatus('DRIVER_ARRIVED');
          await _rideService.updateRideStatus(widget.rideId, 'DRIVER_ARRIVED');
          setState(() => _currentStage = RideStage.arrivedAtPickup);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Notified passenger: Driver has arrived!'),
                backgroundColor: Colors.green,
              ),
            );
          }
          break;

        case RideStage.arrivedAtPickup:
          // Notify backend: trip has started
          _wsService.sendRideStatus('TRIP_STARTED');
          await _rideService.updateRideStatus(widget.rideId, 'TRIP_STARTED');
          setState(() => _currentStage = RideStage.inTrip);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🛵 Trip Started! Safe riding.'),
                backgroundColor: Colors.blue,
              ),
            );
          }
          break;

        case RideStage.inTrip:
          // Notify backend: trip completed
          _wsService.sendRideStatus('TRIP_COMPLETED');
          await _rideService.updateRideStatus(widget.rideId, 'TRIP_COMPLETED');
          _locationPushTimer?.cancel(); // Stop pushing location
          setState(() => _currentStage = RideStage.completed);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✓ Ride Completed Successfully!'),
                backgroundColor: Colors.purple,
              ),
            );
          }
          break;

        case RideStage.completed:
          if (mounted) context.go('/driver/home');
          break;
      }
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
          // 1. MapLibre Map
          MapLibreMap(
            initialCameraPosition: CameraPosition(
              target: widget.initialDriverLocation,
              zoom: 14.8,
            ),
            styleString: MapService.freeMapStyle,
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            myLocationEnabled: false,
            trackCameraPosition: true,
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
                            ? 'Navigating...'
                            : '${_currentRoute.distanceKm} km to pickup (${_currentRoute.durationMinutes.round()} min)',
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
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withOpacity(0.12),
                  child: Text(
                    widget.passengerName.substring(0, 1),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
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
