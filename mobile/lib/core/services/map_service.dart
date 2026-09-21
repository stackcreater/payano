import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';


/// Result model for calculated routes
class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMinutes;
  final String provider;

  RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    this.provider = 'Valhalla',
  });

  factory RouteResult.empty() {
    return RouteResult(
      points: [],
      distanceKm: 0.0,
      durationMinutes: 0.0,
      provider: 'None',
    );
  }
}

/// Service handling routing (Valhalla / OSRM) and Geocoding APIs
class MapService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  // Local OSM raster tile style asset (avoids yellow demotiles fill, no API key needed)
  static const String freeMapStyle = 'assets/map/osm_raster_style.json';

  /// Primary Routing: Valhalla API (https://valhalla1.openstreetmap.de)
  /// Fallback Routing: OSRM API (https://router.project-osrm.org)
  Future<RouteResult> calculateRoute({
    required LatLng start,
    required LatLng destination,
  }) async {
    try {
      // 1. Try Valhalla Public API
      return await _calculateValhallaRoute(start, destination);
    } catch (e) {
      debugPrint('Valhalla routing failed ($e). Falling back to OSRM API...');
      try {
        // 2. Fallback to OSRM Public API
        return await _calculateOSRMRoute(start, destination);
      } catch (osrmError) {
        debugPrint('OSRM routing failed ($osrmError). Generating direct fallback polyline...');
        // 3. Fallback to straight line / linear interpolation polyline if API calls fail
        return _generateDirectPolyline(start, destination);
      }
    }
  }

  /// Calculates route using Valhalla (OSM Public instance)
  Future<RouteResult> _calculateValhallaRoute(LatLng start, LatLng end) async {
    final url = 'https://valhalla1.openstreetmap.de/route';
    final payload = {
      'locations': [
        {'lat': start.latitude, 'lon': start.longitude},
        {'lat': end.latitude, 'lon': end.longitude},
      ],
      'costing': 'auto', // can also use 'motorcycle' for bike rides
      'units': 'kilometers',
    };

    final response = await _dio.post(
      url,
      data: jsonEncode(payload),
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data is String ? jsonDecode(response.data) : response.data;
      final trip = data['trip'];
      final summary = trip['summary'];
      final double distanceKm = (summary['length'] as num).toDouble();
      final double durationMinutes = ((summary['time'] as num) / 60.0).toDouble();

      final List<LatLng> points = [];
      final legs = trip['legs'] as List?;
      if (legs != null && legs.isNotEmpty) {
        for (var leg in legs) {
          final String shape = leg['shape'] ?? '';
          if (shape.isNotEmpty) {
            points.addAll(_decodeValhallaPolyline(shape));
          }
        }
      }

      return RouteResult(
        points: points.isNotEmpty ? points : [start, end],
        distanceKm: double.parse(distanceKm.toStringAsFixed(2)),
        durationMinutes: double.parse(durationMinutes.toStringAsFixed(1)),
        provider: 'Valhalla',
      );
    }

    throw Exception('Valhalla response code: ${response.statusCode}');
  }

  /// Calculates route using OSRM Public Routing API
  Future<RouteResult> _calculateOSRMRoute(LatLng start, LatLng end) async {
    final url =
        'https://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';

    final response = await _dio.get(url);

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data is String ? jsonDecode(response.data) : response.data;
      final routes = data['routes'] as List?;

      if (routes != null && routes.isNotEmpty) {
        final route = routes[0];
        final double distanceMeters = (route['distance'] as num).toDouble();
        final double durationSeconds = (route['duration'] as num).toDouble();
        final geometry = route['geometry'];

        final List<LatLng> points = [];
        if (geometry != null && geometry['coordinates'] != null) {
          final coords = geometry['coordinates'] as List;
          for (var c in coords) {
            final double lng = (c[0] as num).toDouble();
            final double lat = (c[1] as num).toDouble();
            points.add(LatLng(lat, lng));
          }
        }

        return RouteResult(
          points: points.isNotEmpty ? points : [start, end],
          distanceKm: double.parse((distanceMeters / 1000.0).toStringAsFixed(2)),
          durationMinutes: double.parse((durationSeconds / 60.0).toStringAsFixed(1)),
          provider: 'OSRM',
        );
      }
    }

    throw Exception('OSRM route calculation failed');
  }

  /// Decodes Valhalla's 6-decimal precision polyline format
  List<LatLng> _decodeValhallaPolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1e6, lng / 1e6));
    }
    return poly;
  }

  /// Direct linear interpolation polyline when offline or APIs fail
  RouteResult _generateDirectPolyline(LatLng start, LatLng end) {
    const steps = 10;
    List<LatLng> points = [];
    for (int i = 0; i <= steps; i++) {
      final double fraction = i / steps;
      final double lat = start.latitude + (end.latitude - start.latitude) * fraction;
      final double lng = start.longitude + (end.longitude - start.longitude) * fraction;
      points.add(LatLng(lat, lng));
    }

    final double distanceKm = _calculateHaversineDistance(start, end);
    // Estimate 25 km/h avg speed for motorcycle ride
    final double durationMins = (distanceKm / 25.0) * 60.0;

    return RouteResult(
      points: points,
      distanceKm: double.parse(distanceKm.toStringAsFixed(2)),
      durationMinutes: double.parse(durationMins.clamp(1.0, 999.0).toStringAsFixed(1)),
      provider: 'Direct Estimate',
    );
  }

  /// Calculates straight-line distance in KM using Haversine formula
  double _calculateHaversineDistance(LatLng p1, LatLng p2) {
    const double r = 6371.0; // Earth radius in km
    final double dLat = _degToRad(p2.latitude - p1.latitude);
    final double dLng = _degToRad(p2.longitude - p1.longitude);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(p1.latitude)) *
            cos(_degToRad(p2.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final double c = 2 * asin(sqrt(a));
    return r * c;
  }


  double _degToRad(double deg) => deg * (3.141592653589793 / 180.0);
}
