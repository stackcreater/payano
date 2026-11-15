import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
  GoogleMapController? _controller;
  bool _mapReady = false;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  final Set<Circle> _circles = {};

  // Default Salem, TN geo-coordinates (Sona College area)
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
        _buildMapElements();
      }
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
    _mapReady = true;
    _buildMapElements();
  }

  Future<void> _buildMapElements() async {
    final markers = <Marker>{};
    final polylines = <Polyline>{};
    final circles = <Circle>{};

    // 1. Driver Position Marker & Pulse Circle
    markers.add(
      Marker(
        markerId: const MarkerId('driver_pos'),
        position: _driverPos,
        infoWindow: const InfoWindow(
          title: 'Driver Location',
          snippet: 'Payano Moto Pilot',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
    );

    circles.add(
      Circle(
        circleId: const CircleId('driver_pulse'),
        center: _driverPos,
        radius: 80,
        fillColor: const Color(0xFF2563EB).withAlpha(40),
        strokeColor: const Color(0xFF2563EB),
        strokeWidth: 2,
      ),
    );

    // 2. Routing logic based on trip mode
    if (widget.routeMode == MapRouteMode.navigatingToPickup ||
        widget.routeMode == MapRouteMode.arrivedAtPickup) {
      // Driver -> Pickup
      markers.add(
        Marker(
          markerId: const MarkerId('pickup_pos'),
          position: _pickupPos,
          infoWindow: const InfoWindow(
            title: 'Pickup Location',
            snippet: 'Passenger waiting here',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
      );

      final route = await _mapService.calculateRoute(
        start: _driverPos,
        destination: _pickupPos,
      );

      if (route.points.isNotEmpty) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route_to_pickup'),
            points: route.points,
            color: const Color(0xFF2563EB),
            width: 5,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        );
      }
      _fitBounds([_driverPos, _pickupPos]);
    } else if (widget.routeMode == MapRouteMode.inTrip) {
      // Driver -> Dropoff
      markers.add(
        Marker(
          markerId: const MarkerId('drop_pos'),
          position: _dropPos,
          infoWindow: const InfoWindow(
            title: 'Destination',
            snippet: 'Drop-off Location',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        ),
      );

      final route = await _mapService.calculateRoute(
        start: _driverPos,
        destination: _dropPos,
      );

      if (route.points.isNotEmpty) {
        polylines.add(
          Polyline(
            polylineId: const PolylineId('route_in_trip'),
            points: route.points,
            color: const Color(0xFF10B981),
            width: 5,
            startCap: Cap.roundCap,
            endCap: Cap.roundCap,
          ),
        );
      }
      _fitBounds([_driverPos, _dropPos]);
    } else {
      // Idle mode - center on driver position
      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _driverPos, zoom: 14.5),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers
          ..clear()
          ..addAll(markers);
        _polylines
          ..clear()
          ..addAll(polylines);
        _circles
          ..clear()
          ..addAll(circles);
      });
    }
  }

  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty || _controller == null) return;
    if (points.length == 1) {
      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: points.first, zoom: 15.0),
        ),
      );
      return;
    }

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

    _controller?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 60),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.driverPosition ?? _salemCenter,
            zoom: 14.5,
          ),
          markers: _markers,
          polylines: _polylines,
          circles: _circles,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          compassEnabled: true,
          mapToolbarEnabled: false,
          onMapCreated: _onMapCreated,
        ),
        if (widget.onRecenter != null)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.small(
              heroTag: 'payano_recenter_btn',
              backgroundColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
              foregroundColor: const Color(0xFF2563EB),
              onPressed: () {
                widget.onRecenter!();
                _controller?.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(target: _driverPos, zoom: 15.5),
                  ),
                );
              },
              child: const Icon(Icons.my_location_rounded, size: 20),
            ),
          ),
      ],
    );
  }
}
