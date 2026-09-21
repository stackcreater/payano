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

  const PayanoMapWidget({
    super.key,
    this.routeMode = MapRouteMode.idle,
    this.isDark = false,
    this.onRecenter,
  });

  @override
  State<PayanoMapWidget> createState() => _PayanoMapWidgetState();
}

class _PayanoMapWidgetState extends State<PayanoMapWidget> {
  MapLibreMapController? _controller;
  bool _mapReady = false;

  // Salem, TN geo-coordinates
  static const LatLng _salemCenter = LatLng(11.6643, 78.1460);
  static const LatLng _driverPos = LatLng(11.6520, 78.1340); // near Hasthampatti
  static const LatLng _pickupPos = LatLng(11.6756, 78.1470); // Sona College
  static const LatLng _dropPos = LatLng(11.6648, 78.1460);   // Salem Junction

  void _onMapCreated(MapLibreMapController controller) {
    _controller = controller;
    setState(() => _mapReady = true);
    _addMarkersAndRoute();
  }

  void _onStyleLoaded() {
    if (_mapReady) _addMarkersAndRoute();
  }

  Future<void> _addMarkersAndRoute() async {
    final ctrl = _controller;
    if (ctrl == null) return;

    // Driver position marker (blue dot)
    await ctrl.addCircle(CircleOptions(
      geometry: _driverPos,
      circleRadius: 10,
      circleColor: '#2563EB',
      circleStrokeWidth: 3,
      circleStrokeColor: '#FFFFFF',
    ));

    if (widget.routeMode == MapRouteMode.navigatingToPickup ||
        widget.routeMode == MapRouteMode.arrivedAtPickup) {
      // Blue route line from driver → pickup
      await ctrl.addLine(LineOptions(
        geometry: [_driverPos, _pickupPos],
        lineColor: '#2563EB',
        lineWidth: 5,
        lineOpacity: 0.85,
        lineJoin: 'round',
      ));

      // Pickup marker (green circle)
      await ctrl.addCircle(CircleOptions(
        geometry: _pickupPos,
        circleRadius: 10,
        circleColor: '#10B981',
        circleStrokeWidth: 3,
        circleStrokeColor: '#FFFFFF',
      ));
    } else if (widget.routeMode == MapRouteMode.inTrip) {
      // Blue route line from driver → drop
      await ctrl.addLine(LineOptions(
        geometry: [_driverPos, _dropPos],
        lineColor: '#2563EB',
        lineWidth: 5,
        lineOpacity: 0.85,
        lineJoin: 'round',
      ));

      // Drop marker (green circle)
      await ctrl.addCircle(CircleOptions(
        geometry: _dropPos,
        circleRadius: 10,
        circleColor: '#10B981',
        circleStrokeWidth: 3,
        circleStrokeColor: '#FFFFFF',
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return MapLibreMap(
      initialCameraPosition: const CameraPosition(
        target: _salemCenter,
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
