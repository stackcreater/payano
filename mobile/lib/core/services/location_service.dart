import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../shared/models/driver_model.dart';

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

class LocationService {
  // Sona College of Technology, Salem, Tamil Nadu (Campus epicenter)
  static const double defaultLat = 11.6756;
  static const double defaultLng = 78.1470;
  static const String defaultAddress = 'Sona College of Technology, Junction Main Road, Salem';

  Position? _lastKnownPosition;
  Position? get lastKnownPosition => _lastKnownPosition;

  /// Check and request location permissions on device
  Future<bool> checkAndRequestPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('LocationService: Location services are disabled on device.');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('LocationService: Location permissions are denied.');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('LocationService: Location permissions are permanently denied.');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('LocationService: Permission check exception: $e');
      return false;
    }
  }

  /// Get current device GPS position with timeout & graceful fallback
  Future<Map<String, dynamic>> getCurrentPosition() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (hasPermission) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 8),
          ),
        );
        _lastKnownPosition = position;
        return {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'heading': position.heading,
          'speed': position.speed,
          'timestamp': position.timestamp.toIso8601String(),
          'address': defaultAddress,
        };
      }
    } catch (e) {
      debugPrint('LocationService: getCurrentPosition failed ($e). Using cached/fallback.');
    }

    if (_lastKnownPosition != null) {
      return {
        'latitude': _lastKnownPosition!.latitude,
        'longitude': _lastKnownPosition!.longitude,
        'accuracy': _lastKnownPosition!.accuracy,
        'heading': _lastKnownPosition!.heading,
        'speed': _lastKnownPosition!.speed,
        'timestamp': _lastKnownPosition!.timestamp.toIso8601String(),
        'address': defaultAddress,
      };
    }

    return {
      'latitude': defaultLat,
      'longitude': defaultLng,
      'accuracy': 10.0,
      'heading': 0.0,
      'speed': 0.0,
      'timestamp': DateTime.now().toIso8601String(),
      'address': defaultAddress,
    };
  }

  /// Continuous GPS stream for driver location broadcasting during online/active rides
  Stream<Position> getPositionStream({int distanceFilterMeters = 5}) {
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 5,
    );
    return Geolocator.getPositionStream(locationSettings: locationSettings);
  }

  /// Calculates Haversine distance in kilometers between two GPS coordinates
  double calculateDistanceKm(double startLat, double startLng, double endLat, double endLng) {
    const p = 0.017453292519943295;
    const c = cos;
    final a = 0.5 -
        c((endLat - startLat) * p) / 2 +
        c(startLat * p) * c(endLat * p) * (1 - c((endLng - startLng) * p)) / 2;
    return 12742 * asin(sqrt(a)); // 2 * R; R = 6371 km
  }

  /// Nearby drivers discovery
  List<DriverModel> getNearbyTwoWheelerDrivers(double centerLat, double centerLng) {
    return [];
  }
}
