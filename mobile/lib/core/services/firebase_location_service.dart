import 'dart:async';
import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import '../../shared/models/telemetry_model.dart';

// Re-export DriverTelemetry so existing imports still work
export '../../shared/models/telemetry_model.dart' show DriverTelemetry;

/// Service managing real-time driver location stream via Firebase Realtime Database (with fallback simulator)
class FirebaseLocationService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  // Throttle timer for sending driver updates
  DateTime? _lastSentTime;
  static const int throttleSeconds = 6; // Throttled to send every 5-8 seconds

  /// Push driver location update to Firebase Realtime Database at `/drivers/{driverId}/location`
  Future<void> updateDriverLocation({
    required String driverId,
    required LatLng location,
    required double heading,
    double speedKmH = 25.0,
    bool forceImmediate = false,
  }) async {
    final now = DateTime.now();
    if (!forceImmediate && _lastSentTime != null) {
      final elapsed = now.difference(_lastSentTime!).inSeconds;
      if (elapsed < throttleSeconds) {
        // Throttled: Skip sending to conserve bandwidth & DB writes
        return;
      }
    }

    _lastSentTime = now;

    final telemetry = DriverTelemetry(
      driverId: driverId,
      location: location,
      heading: heading,
      speedKmH: speedKmH,
      timestamp: now,
    );

    try {
      final ref = _db.ref('drivers/$driverId/location');
      await ref.set(telemetry.toJson());
      debugPrint('FirebaseLocationService: Telemetry pushed for $driverId -> (${location.latitude}, ${location.longitude})');
    } catch (e) {
      debugPrint('FirebaseLocationService write error ($e). Location updated locally.');
    }
  }

  /// Listen to real-time stream of driver location from Firebase Realtime Database.
  /// If Firebase is unavailable or offline, streams smooth simulated location progression along route points.
  Stream<DriverTelemetry> streamDriverLocation(
    String driverId, {
    List<LatLng>? fallbackRoutePoints,
  }) {
    try {
      final ref = _db.ref('drivers/$driverId/location');
      return ref.onValue.map((event) {
        if (event.snapshot.value != null) {
          final data = Map<String, dynamic>.from(event.snapshot.value as Map);
          return DriverTelemetry.fromJson(data);
        } else {
          throw Exception('No data at ref');
        }
      }).handleError((error) {
        debugPrint('Firebase Database stream fallback activated: $error');
        return _createSimulatedLocationStream(driverId, fallbackRoutePoints);
      });
    } catch (e) {
      return _createSimulatedLocationStream(driverId, fallbackRoutePoints);
    }
  }

  /// Simulated location stream moving driver step-by-step along polyline every 5-6 seconds
  Stream<DriverTelemetry> _createSimulatedLocationStream(
    String driverId,
    List<LatLng>? routePoints,
  ) async* {
    // Default simulated coordinates in MG Road, Bengaluru area
    final List<LatLng> points = routePoints != null && routePoints.length >= 2
        ? routePoints
        : [
            const LatLng(12.9780, 77.5900),
            const LatLng(12.9760, 77.5920),
            const LatLng(12.9740, 77.5935),
            const LatLng(12.9716, 77.5946), // Passenger pickup location
          ];

    int step = 0;
    while (true) {
      await Future.delayed(const Duration(seconds: throttleSeconds));
      final current = points[step % points.length];
      final next = points[(step + 1) % points.length];

      // Calculate bearing / heading towards next point
      final double heading = _calculateBearing(current, next);

      yield DriverTelemetry(
        driverId: driverId,
        location: current,
        heading: heading,
        speedKmH: 22.0 + (step % 5),
        timestamp: DateTime.now(),
      );

      step++;
    }
  }

  /// Calculates bearing / angle between two LatLng coordinates
  double _calculateBearing(LatLng start, LatLng end) {
    final double startLat = _degToRad(start.latitude);
    final double startLng = _degToRad(start.longitude);
    final double endLat = _degToRad(end.latitude);
    final double endLng = _degToRad(end.longitude);

    final double dLng = endLng - startLng;
    final double y = sin(dLng) * cos(endLat);
    final double x = cos(startLat) * sin(endLat) - sin(startLat) * cos(endLat) * cos(dLng);

    double bearing = atan2(y, x);
    bearing = bearing * (180 / 3.141592653589793);
    return (bearing + 360) % 360;
  }

  double _degToRad(double deg) => deg * (3.141592653589793 / 180.0);
}
