import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../services/map_service.dart';

enum MapRouteMode {
  idle,
  navigatingToPickup,
  arrivedAtPickup,
  inTrip,
}

class PayanoMapWidget extends StatefulWidget {
  final MapRouteMode routeMode;
  final bool isDark;
  final VoidCallback? onRecenter;
  final LatLng? driverPosition;
  final LatLng? pickupPosition;
  final LatLng? dropPosition;

  const PayanoMapWidget({
    super.key,
    this.routeMode = MapRouteMode.idle,
    this.isDark = false,
    this.onRecenter,
    this.driverPosition,
    this.pickupPosition,
    this.dropPosition,
  });

  @override
  State<PayanoMapWidget> createState() => _PayanoMapWidgetState();
}

class _PayanoMapWidgetState extends State<PayanoMapWidget> {
  final MapService _mapService = MapService();
  MapLibreMapController? _controller;
  bool _mapReady = false;
  Line? _currentLine;
  final List<Circle> _circles = [];

  // Default Salem, TN geo-coordinates
  static const LatLng _salemCenter = LatLng(11.6643, 78.1460);
  static const LatLng _defaultDriverPos = LatLng(11.6520, 78.1340); // Hasthampatti
  static const LatLng _defaultPickupPos = LatLng(11.6756, 78.1470); // Sona College
  static const LatLng _defaultDropPos = LatLng(11.6648, 78.1460);   // Salem Junction

  LatLng get _driverPos => widget.driverPosition ?? _defaultDriverPos;
  LatLng get _pickupPos => widget.pickupPosition ?? _defaultPickupPos;
  LatLng get _dropPos => widget.dropPosition ?? _defaultDropPos;

  @override
  void didUpdateWidget(covariant PayanoMapWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeMode != widget.routeMode ||
        oldWidget.driverPosition != widget.driverPosition ||
        oldWidget.pickupPosition != widget.pickupPosition ||
        oldWidget.dropPosition != widget.dropPosition) {
      if (_mapReady) {
        _addMarkersAndRoute();
      }
    }
  }

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    setState(() => _mapReady = true);
    _addMarkersAndRoute();
  }

  void _onStyleLoaded() {
    if (_mapReady) _addMarkersAndRoute();
  }

  Future<void> _clearPreviousMapObjects() async {
    final ctrl = _controller;
    if (ctrl == null) return;

    if (_currentLine != null) {
      try {
        await ctrl.removeLine(_currentLine!);
      } catch (_) {}
      _currentLine = null;
    }

    for (final circle in _circles) {
      try {
        await ctrl.removeCircle(circle);
      } catch (_) {}
    }
    _circles.clear();
  }

  Future<void> _addMarkersAndRoute() async {
    final ctrl = _controller;
    if (ctrl == null) return;

    await _clearPreviousMapObjects();

    // 1. Driver position marker (Blue circle)
    final driverCircle = await ctrl.addCircle(CircleOptions(
      geometry: _driverPos,
      circleRadius: 10,
      circleColor: '#2563EB',
      circleStrokeWidth: 3,
      circleStrokeColor: '#FFFFFF',
    ));
    _circles.add(driverCircle);

    if (widget.routeMode == MapRouteMode.navigatingToPickup ||
        widget.routeMode == MapRouteMode.arrivedAtPickup) {
      // Calculate real road route: Driver → Pickup
      debugPrint('[PayanoMapWidget] Routing driver to pickup: $_driverPos -> $_pickupPos');
      final route = await _mapService.calculateRoute(
        start: _driverPos,
        destination: _pickupPos,
      );

      _currentLine = await ctrl.addLine(LineOptions(
        geometry: route.points,
        lineColor: '#2563EB',
        lineWidth: 5.5,
        lineOpacity: 0.85,
        lineJoin: 'round',
      ));

      // Pickup marker (Emerald Green circle)
      final pickupCircle = await ctrl.addCircle(CircleOptions(
        geometry: _pickupPos,
        circleRadius: 11,
        circleColor: '#10B981',
        circleStrokeWidth: 3,
        circleStrokeColor: '#FFFFFF',
      ));
      _circles.add(pickupCircle);

    } else if (widget.routeMode == MapRouteMode.inTrip) {
      // Calculate real road route: Driver → Drop-off
      debugPrint('[PayanoMapWidget] Routing driver to dropoff: $_driverPos -> $_dropPos');
      final route = await _mapService.calculateRoute(
        start: _driverPos,
        destination: _dropPos,
      );

      _currentLine = await ctrl.addLine(LineOptions(
        geometry: route.points,
        lineColor: '#10B981',
        lineWidth: 5.5,
        lineOpacity: 0.85,
        lineJoin: 'round',
      ));

      // Drop marker (Red/Primary circle)
      final dropCircle = await ctrl.addCircle(CircleOptions(
        geometry: _dropPos,
        circleRadius: 11,
        circleColor: '#EF4444',
        circleStrokeWidth: 3,
        circleStrokeColor: '#FFFFFF',
      ));
      _circles.add(dropCircle);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      initialCameraPosition: CameraPosition(
        target: widget.driverPosition ?? _salemCenter,
        zoom: 13.5,
      ),
      styleString: MapService.freeMapStyle,
      myLocationEnabled: false,
      trackCameraPosition: false,
      onMapCreated: _onMapCreated,
      onStyleLoadedCallback: _onStyleLoaded,
    );
  }
}
