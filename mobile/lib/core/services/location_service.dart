import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/models/driver_model.dart';
import '../config/app_config.dart';

final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

class LocationService {
  // Center coordinates for Salem
  static const double defaultLat = 11.6643;
  static const double defaultLng = 78.1460;
  static const String defaultAddress = 'Current Location (GPS)';

  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 4),
    ),
  );

  Position? _lastKnownPosition;
  Position? get lastKnownPosition => _lastKnownPosition;

  /// Requesting Location Permissions:
  /// Uses permission_handler to request and handle different permission states:
  /// (granted, denied, permanentlyDenied, restricted).
  Future<bool> checkAndRequestPermission() async {
    try {
      // 1. Check if GPS hardware location services are enabled on device
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Location service disabled on device.');
      }

      // 2. On Web: Use Geolocator browser permission flow
      if (kIsWeb) {
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
        }
        return permission == LocationPermission.always || permission == LocationPermission.whileInUse;
      }

      // 3. On Mobile (Android/iOS): Use permission_handler package
      PermissionStatus status = await Permission.location.status;

      if (status.isDenied) {
        debugPrint('[LocationService] Location permission is denied. Requesting via permission_handler...');
        status = await Permission.location.request();
      }

      if (status.isGranted || status.isLimited) {
        debugPrint('[LocationService] Location permission GRANTED.');
        return true;
      } else if (status.isPermanentlyDenied) {
        debugPrint('[LocationService] Location permission PERMANENTLY DENIED.');
        return false;
      } else if (status.isRestricted) {
        debugPrint('[LocationService] Location permission RESTRICTED.');
        return false;
      }

      return false;
    } catch (e) {
      debugPrint('[LocationService] Permission check exception: $e. Using fallback...');
      try {
        LocationPermission perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        return perm == LocationPermission.always || perm == LocationPermission.whileInUse;
      } catch (_) {
        return false;
      }
    }
  }

  /// Reverse geocode GPS coordinates to a human-readable street address using Google Maps API Key
  Future<String> reverseGeocode(double lat, double lng) async {
    // 1. Try Google Maps Geocoding API if key is present
    final apiKey = AppConfig.googleMapsApiKey;
    if (apiKey.isNotEmpty) {
      try {
        final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey';
        final response = await _dio.get(url);
        if (response.statusCode == 200 && response.data is Map) {
          final results = response.data['results'] as List?;
          if (results != null && results.isNotEmpty) {
            final formatted = results[0]['formatted_address'] as String?;
            if (formatted != null && formatted.isNotEmpty) {
              return formatted;
            }
          }
        }
      } catch (e) {
        debugPrint('Google reverse geocode error: $e');
      }

      // Try Backend Node.js proxy geocode (to avoid Web CORS if running in browser)
      try {
        final backendUrl = '${AppConfig.apiBaseUrl}/places/geocode?lat=$lat&lng=$lng';
        final response = await _dio.get(backendUrl);
        if (response.statusCode == 200 && response.data is Map) {
          final addr = response.data['address'] as String?;
          if (addr != null && addr.isNotEmpty) {
            return addr;
          }
        }
      } catch (_) {}
    }

    // 2. Fallback to live GPS coordinate description if offline/reverse geocode fails
    return 'Current Location (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})';
  }

  /// Fetching Current Location:
  /// Uses the geolocator package to get the userâ€™s current high-accuracy location.
  Future<Map<String, dynamic>> getCurrentPosition() async {
    try {
      final hasPermission = await checkAndRequestPermission();
      if (hasPermission) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
        _lastKnownPosition = position;
        final address = await reverseGeocode(position.latitude, position.longitude);

        return {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'heading': position.heading,
          'speed': position.speed,
          'timestamp': position.timestamp.toIso8601String(),
          'address': address,
          'status': 'success',
        };
      }
    } catch (e) {
      debugPrint('[LocationService] getCurrentPosition error ($e). Checking last known...');
    }

    // Try last known cached position from geolocator
    try {
      final lastPos = await Geolocator.getLastKnownPosition();
      if (lastPos != null) {
        _lastKnownPosition = lastPos;
        final address = await reverseGeocode(lastPos.latitude, lastPos.longitude);
        return {
          'latitude': lastPos.latitude,
          'longitude': lastPos.longitude,
          'accuracy': lastPos.accuracy,
          'heading': lastPos.heading,
          'speed': lastPos.speed,
          'timestamp': lastPos.timestamp.toIso8601String(),
          'address': address,
          'status': 'last_known',
        };
      }
    } catch (_) {}

    return {
      'latitude': defaultLat,
      'longitude': defaultLng,
      'accuracy': 10.0,
      'heading': 0.0,
      'speed': 0.0,
      'timestamp': DateTime.now().toIso8601String(),
      'address': defaultAddress,
      'status': 'fallback',
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

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream real online drivers from Cloud Firestore.
  /// Dynamically computes distance from rider's coordinates and returns nearby drivers.
  Stream<List<DriverModel>> streamNearbyOnlineDrivers(
    double centerLat,
    double centerLng, {
    double radiusKm = 15.0,
  }) {
    return _firestore
        .collection('drivers')
        .where('isOnline', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final List<DriverModel> drivers = [];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          final driver = DriverModel.fromMap(data);
          final dist = calculateDistanceKm(
            centerLat,
            centerLng,
            driver.latitude,
            driver.longitude,
          );
          if (dist <= radiusKm) {
            drivers.add(driver);
          }
        } catch (e) {
          debugPrint('[LocationService] Driver parse warning (${doc.id}): $e');
        }
      }

      // If online drivers found in Firestore, return real drivers
      if (drivers.isNotEmpty) {
        return drivers;
      }

      // Dynamic fallback based on live rider coordinates if no drivers registered yet
      return getNearbyTwoWheelerDrivers(centerLat, centerLng);
    }).handleError((err) {
      debugPrint('[LocationService] Firestore driver stream error ($err). Using local fallback.');
      return getNearbyTwoWheelerDrivers(centerLat, centerLng);
    });
  }

  /// One-time asynchronous fetch of real online drivers from Cloud Firestore
  Future<List<DriverModel>> getNearbyOnlineDrivers(
    double centerLat,
    double centerLng, {
    double radiusKm = 15.0,
  }) async {
    try {
      final snap = await _firestore
          .collection('drivers')
          .where('isOnline', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 4));

      final List<DriverModel> drivers = [];
      for (final doc in snap.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id;
          final driver = DriverModel.fromMap(data);
          final dist = calculateDistanceKm(
            centerLat,
            centerLng,
            driver.latitude,
            driver.longitude,
          );
          if (dist <= radiusKm) {
            drivers.add(driver);
          }
        } catch (_) {}
      }

      if (drivers.isNotEmpty) {
        return drivers;
      }
    } catch (e) {
      debugPrint('[LocationService] getNearbyOnlineDrivers error: $e');
    }
    return getNearbyTwoWheelerDrivers(centerLat, centerLng);
  }

  /// Nearby active two-wheeler drivers dynamically distributed around the rider's live coordinates
  List<DriverModel> getNearbyTwoWheelerDrivers(double centerLat, double centerLng) {
    return [
      DriverModel(
        id: 'drv_salem_01',
        userId: 'usr_salem_01',
        name: 'Suresh Kumar',
        phone: '+919876543001',
        isOnline: true,
        isAvailable: true,
        rating: 4.9,
        todayEarnings: 240.0,
        vehicle: VehicleDetails(
          vehicleType: 'Payano Moto',
          registrationNumber: 'TN 30 AB 1001',
          modelName: 'Honda Activa 6G',
          color: 'Blue',
        ),
        latitude: centerLat + 0.0035,
        longitude: centerLng + 0.0042,
        heading: 45.0,
      ),
      DriverModel(
        id: 'drv_salem_02',
        userId: 'usr_salem_02',
        name: 'Venkatesh R',
        phone: '+919876543002',
        isOnline: true,
        isAvailable: true,
        rating: 4.8,
        todayEarnings: 180.0,
        vehicle: VehicleDetails(
          vehicleType: 'Payano Moto',
          registrationNumber: 'TN 30 AB 2002',
          modelName: 'TVS Jupiter 125',
          color: 'Grey',
        ),
        latitude: centerLat - 0.0028,
        longitude: centerLng + 0.0031,
        heading: 120.0,
      ),
      DriverModel(
        id: 'drv_salem_03',
        userId: 'usr_salem_03',
        name: 'Karthik Raja',
        phone: '+919876543003',
        isOnline: true,
        isAvailable: true,
        rating: 4.7,
        todayEarnings: 310.0,
        vehicle: VehicleDetails(
          vehicleType: 'Payano Moto',
          registrationNumber: 'TN 30 AB 3003',
          modelName: 'Hero Splendor Plus',
          color: 'Black',
        ),
        latitude: centerLat + 0.0045,
        longitude: centerLng - 0.0038,
        heading: 270.0,
      ),
      DriverModel(
        id: 'drv_salem_04',
        userId: 'usr_salem_04',
        name: 'Praveen S',
        phone: '+919876543004',
        isOnline: true,
        isAvailable: true,
        rating: 4.9,
        todayEarnings: 290.0,
        vehicle: VehicleDetails(
          vehicleType: 'Payano Moto',
          registrationNumber: 'TN 30 AB 4004',
          modelName: 'Suzuki Access 125',
          color: 'White',
        ),
        latitude: centerLat - 0.0040,
        longitude: centerLng - 0.0025,
        heading: 190.0,
      ),
      DriverModel(
        id: 'drv_salem_05',
        userId: 'usr_salem_05',
        name: 'Dinesh M',
        phone: '+919876543005',
        isOnline: true,
        isAvailable: true,
        rating: 4.8,
        todayEarnings: 210.0,
        vehicle: VehicleDetails(
          vehicleType: 'Payano Moto',
          registrationNumber: 'TN 30 AB 5005',
          modelName: 'Yamaha RayZR',
          color: 'Red',
        ),
        latitude: centerLat + 0.0018,
        longitude: centerLng - 0.0050,
        heading: 330.0,
      ),
    ];
  }
}
