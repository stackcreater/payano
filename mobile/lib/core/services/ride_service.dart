import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';

/// Provider for the RideService singleton
final rideServiceProvider = Provider<RideService>((ref) => RideService());

// ─── Response Models ──────────────────────────────────────────────────────────

class CreatedRide {
  final String id;
  final String startOtp;
  final String status;
  final Map<String, dynamic> pickup;
  final Map<String, dynamic> destination;
  final String vehicleType;
  final String passengerId;
  final String passengerName;
  final String passengerPhone;

  CreatedRide({
    required this.id,
    required this.startOtp,
    required this.status,
    required this.pickup,
    required this.destination,
    required this.vehicleType,
    required this.passengerId,
    required this.passengerName,
    required this.passengerPhone,
  });

  factory CreatedRide.fromJson(Map<String, dynamic> json) {
    return CreatedRide(
      id: json['id'] as String? ?? 'ride_${DateTime.now().millisecondsSinceEpoch}',
      startOtp: json['startOtp'] as String? ?? '0000',
      status: json['status'] as String? ?? 'SEARCHING',
      pickup: json['pickup'] as Map<String, dynamic>? ?? {},
      destination: json['destination'] as Map<String, dynamic>? ?? {},
      vehicleType: json['vehicleType'] as String? ?? 'moto',
      passengerId: json['passengerId'] as String? ?? '',
      passengerName: json['passengerName'] as String? ?? '',
      passengerPhone: json['passengerPhone'] as String? ?? '',
    );
  }
}

// ─── RideService ──────────────────────────────────────────────────────────────

class RideService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  String get _baseUrl => AppConfig.apiBaseUrl;

  // ─── Create Ride ──────────────────────────────────────────────────────────

  /// Create a new ride via POST /rides/create
  /// Returns a [CreatedRide] with the rideId and startOtp on success.
  /// On failure (backend unreachable), generates a local ride ID so the app
  /// continues to work in offline/demo mode.
  Future<CreatedRide> createRide({
    required String passengerId,
    required String passengerName,
    required String passengerPhone,
    required double pickupLat,
    required double pickupLng,
    required String pickupAddress,
    required double destinationLat,
    required double destinationLng,
    required String destinationAddress,
    String category = 'moto',
  }) async {
    final payload = {
      'passengerId': passengerId,
      'passengerName': passengerName,
      'passengerPhone': passengerPhone,
      'pickup': {
        'address': pickupAddress,
        'latitude': pickupLat,
        'longitude': pickupLng,
      },
      'destination': {
        'address': destinationAddress,
        'latitude': destinationLat,
        'longitude': destinationLng,
      },
      'category': category,
    };

    try {
      final response = await _dio.post('$_baseUrl/rides/create', data: payload);
      if (response.statusCode == 201 && response.data != null) {
        final rideData = response.data['ride'] as Map<String, dynamic>? ?? response.data;
        debugPrint('RideService: Ride created ${rideData['id']}');
        return CreatedRide.fromJson(rideData);
      }
      throw Exception('Unexpected response: ${response.statusCode}');
    } catch (e) {
      debugPrint('RideService: createRide failed ($e). Using local fallback ride.');
      // Graceful fallback: generate a local ride ID so the app keeps working
      final localId = 'ride_${DateTime.now().millisecondsSinceEpoch}';
      return CreatedRide(
        id: localId,
        startOtp: _generateOtp(),
        status: 'SEARCHING',
        pickup: {'address': pickupAddress, 'latitude': pickupLat, 'longitude': pickupLng},
        destination: {'address': destinationAddress, 'latitude': destinationLat, 'longitude': destinationLng},
        vehicleType: category,
        passengerId: passengerId,
        passengerName: passengerName,
        passengerPhone: passengerPhone,
      );
    }
  }

  // ─── Get Ride ──────────────────────────────────────────────────────────────

  /// Fetch a ride document by ID via GET /rides/{rideId}
  Future<Map<String, dynamic>?> getRide(String rideId) async {
    try {
      final response = await _dio.get('$_baseUrl/rides/$rideId');
      if (response.statusCode == 200 && response.data != null) {
        return response.data['ride'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('RideService: getRide failed ($e)');
      return null;
    }
  }

  // ─── Update Ride Status ───────────────────────────────────────────────────

  /// Update ride status via POST /rides/status
  /// [status] values: SEARCHING, DRIVER_ASSIGNED, DRIVER_ARRIVING, DRIVER_ARRIVED,
  ///                  TRIP_STARTED, TRIP_COMPLETED, CANCELLED
  Future<bool> updateRideStatus(String rideId, String status) async {
    try {
      final response = await _dio.post('$_baseUrl/rides/status', data: {
        'rideId': rideId,
        'status': status,
      });
      final ok = response.statusCode == 200;
      if (ok) debugPrint('RideService: Status updated -> $status for $rideId');
      return ok;
    } catch (e) {
      debugPrint('RideService: updateRideStatus failed ($e)');
      return false;
    }
  }

  // ─── Fare Calculation ─────────────────────────────────────────────────────

  /// Calculate fare via POST /fare/calculate
  Future<Map<String, dynamic>?> calculateFare({
    required String category,
    required double distanceKm,
    required double durationMins,
    double surgeMultiplier = 1.0,
    double promoDiscount = 0.0,
  }) async {
    try {
      final response = await _dio.post('$_baseUrl/fare/calculate', data: {
        'category': category,
        'distanceKm': distanceKm,
        'durationMins': durationMins,
        'surgeMultiplier': surgeMultiplier,
        'promoDiscount': promoDiscount,
      });
      if (response.statusCode == 200) return response.data as Map<String, dynamic>?;
      return null;
    } catch (e) {
      debugPrint('RideService: calculateFare failed ($e)');
      return null;
    }
  }

  // ─── Helper ───────────────────────────────────────────────────────────────

  String _generateOtp() {
    final rng = DateTime.now().millisecondsSinceEpoch % 9000 + 1000;
    return rng.toString();
  }
}
