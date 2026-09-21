import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../../../core/services/websocket_location_service.dart';
import '../../../core/services/map_service.dart';
import '../../../core/theme/app_colors.dart';

/// Screen for Passengers to track the driver's real-time location, ETA, and ride status
class PassengerTrackingScreen extends ConsumerStatefulWidget {
  final String rideId;
  final String driverId;
  final String driverName;
  final String vehicleInfo;
  final String registrationNo;
  final double driverRating;
  final LatLng passengerLocation;
  final LatLng initialDriverLocation;

  const PassengerTrackingScreen({
    super.key,
    this.rideId = 'ride_101',
    this.driverId = 'drv_driver_01',
    this.driverName = 'Ramesh Kumar',
    this.vehicleInfo = 'Payano Moto (Hero Splendor+)',
    this.registrationNo = 'KA-01-ET-8821',
    this.driverRating = 4.9,
    this.passengerLocation = const LatLng(12.9716, 77.5946), // MG Road
    this.initialDriverLocation = const LatLng(12.9780, 77.5900),
  });

  @override
  ConsumerState<PassengerTrackingScreen> createState() => _PassengerTrackingScreenState();
}

class _PassengerTrackingScreenState extends ConsumerState<PassengerTrackingScreen>
    with TickerProviderStateMixin {
  // ─── Services ──────────────────────────────────────────────────────────────
  final MapService _mapService = MapService();
  final WebSocketLocationService _wsService = WebSocketLocationService();

  // ─── Map ───────────────────────────────────────────────────────────────────
  MapLibreMapController? _mapController;
  Symbol? _driverSymbol;
  Symbol? _passengerSymbol;
  Line? _routeLine;

  // ─── Subscriptions ─────────────────────────────────────────────────────────
  StreamSubscription<RideWebSocketEvent>? _rideEventSub;
  Timer? _routeRecalculateTimer;

  // ─── State ─────────────────────────────────────────────────────────────────
  LatLng? _currentDriverLocation;
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

    _statusPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _statusPulseAnim = Tween<double>(begin: 0.7, end: 1.0).animate(_statusPulseCtrl);
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

  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
  }

  void _onStyleLoaded() async {
    if (_mapController == null) return;

    // Passenger pickup marker
    _passengerSymbol = await _mapController!.addSymbol(
      SymbolOptions(
        geometry: widget.passengerLocation,
        iconImage: 'marker-15',
        iconSize: 2.0,
        textField: 'Pickup Location',
        textOffset: const Offset(0, 1.8),
        textColor: '#10B981',
        textHaloColor: '#FFFFFF',
        textHaloWidth: 1.5,
      ),
    );

    // Driver moving marker
    _driverSymbol = await _mapController!.addSymbol(
      SymbolOptions(
        geometry: _currentDriverLocation,
        iconImage: 'airport-15',
        iconSize: 2.2,
        iconRotate: _driverHeading,
        textField: 'Driver ${widget.driverName.split(" ").first}',
        textOffset: const Offset(0, -1.8),
        textColor: '#2563EB',
        textHaloColor: '#FFFFFF',
        textHaloWidth: 1.5,
      ),
    );

    // Initial route
    await _fetchRoute();

    // Start WebSocket event subscription
    _startRideEventListener();

    // Periodic route recalculation every 30s (throttled)
    _routeRecalculateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _fetchRoute();
    });
  }

  // ─── Route ─────────────────────────────────────────────────────────────────

  Future<void> _fetchRoute() async {
    if (_currentDriverLocation == null) return;
    final now = DateTime.now();
    if (_lastRouteFetchTime != null &&
        now.difference(_lastRouteFetchTime!).inSeconds < 15) return;
    _lastRouteFetchTime = now;

    final result = await _mapService.calculateRoute(
      start: _currentDriverLocation!,
      destination: widget.passengerLocation,
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

    if (_driverSymbol != null) {
      _mapController!.updateSymbol(
        _driverSymbol!,
        SymbolOptions(geometry: newLoc, iconRotate: newHeading),
      );
    }

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
            : 'Arriving in approx ${_currentRoute.durationMinutes.round()} minutes';
      case 'DRIVER_ARRIVED':
        return 'Please proceed to pickup point';
      case 'TRIP_STARTED':
        return 'Sit back and enjoy the ride';
      default:
        return '';
    }
  }

  Color get _statusColor {
    switch (_rideStatus) {
      case 'DRIVER_ARRIVED':
        return Colors.green.shade700;
      case 'TRIP_STARTED':
        return AppColors.primary;
      case 'TRIP_COMPLETED':
      case 'COMPLETED':
        return Colors.purple.shade600;
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
          // 1. MapLibre Map
          MapLibreMap(
            initialCameraPosition: CameraPosition(
              target: widget.passengerLocation,
              zoom: 14.5,
            ),
            styleString: MapService.freeMapStyle,
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            myLocationEnabled: false,
            trackCameraPosition: true,
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
            const Divider(height: 24),

            // Driver & Vehicle Row
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.primary.withOpacity(0.15),
                  child: Text(
                    widget.driverName.substring(0, 1),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
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
