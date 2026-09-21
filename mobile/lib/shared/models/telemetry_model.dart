/// Shared real-time data models for WebSocket / Firebase telemetry
import 'package:maplibre_gl/maplibre_gl.dart';

// ─── DriverTelemetry ─────────────────────────────────────────────────────────

/// Real-time telemetry snapshot of a driver's position and motion
class DriverTelemetry {
  final String driverId;
  final LatLng location;
  final double heading;
  final double speedKmH;
  final DateTime timestamp;

  DriverTelemetry({
    required this.driverId,
    required this.location,
    required this.heading,
    this.speedKmH = 25.0,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'driverId': driverId,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'heading': heading,
        'speedKmH': speedKmH,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory DriverTelemetry.fromJson(Map<String, dynamic> json) {
    return DriverTelemetry(
      driverId: json['driverId'] as String? ?? 'drv_001',
      location: LatLng(
        (json['latitude'] as num).toDouble(),
        (json['longitude'] as num).toDouble(),
      ),
      heading: (json['heading'] as num?)?.toDouble() ?? 0.0,
      speedKmH: (json['speedKmH'] as num?)?.toDouble() ?? 20.0,
      timestamp: json['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
          : DateTime.now(),
    );
  }
}

// ─── IncomingRideRequest ─────────────────────────────────────────────────────

/// Ride request payload broadcast to available drivers via /ws/drivers
class IncomingRideRequest {
  final String rideId;
  final String passengerName;
  final String passengerPhone;
  final String pickupAddress;
  final String destinationAddress;
  final double pickupLat;
  final double pickupLng;
  final double destLat;
  final double destLng;
  final String vehicleCategory;
  final double estimatedFare;
  final DateTime receivedAt;

  IncomingRideRequest({
    required this.rideId,
    required this.passengerName,
    required this.passengerPhone,
    required this.pickupAddress,
    required this.destinationAddress,
    required this.pickupLat,
    required this.pickupLng,
    required this.destLat,
    required this.destLng,
    required this.vehicleCategory,
    required this.estimatedFare,
    required this.receivedAt,
  });

  LatLng get pickupLatLng => LatLng(pickupLat, pickupLng);
  LatLng get destLatLng => LatLng(destLat, destLng);

  factory IncomingRideRequest.fromJson(Map<String, dynamic> json) {
    final ride = json['ride'] as Map<String, dynamic>? ?? json;
    final pickup = ride['pickup'] as Map<String, dynamic>? ?? {};
    final destination = ride['destination'] as Map<String, dynamic>? ?? {};

    return IncomingRideRequest(
      rideId: ride['id'] as String? ?? 'ride_unknown',
      passengerName: ride['passengerName'] as String? ?? 'Passenger',
      passengerPhone: ride['passengerPhone'] as String? ?? '',
      pickupAddress: pickup['address'] as String? ?? 'Pickup Location',
      destinationAddress: destination['address'] as String? ?? 'Destination',
      pickupLat: (pickup['latitude'] as num?)?.toDouble() ?? 12.9716,
      pickupLng: (pickup['longitude'] as num?)?.toDouble() ?? 77.5946,
      destLat: (destination['latitude'] as num?)?.toDouble() ?? 12.9352,
      destLng: (destination['longitude'] as num?)?.toDouble() ?? 77.6245,
      vehicleCategory: ride['vehicleType'] as String? ?? 'moto',
      estimatedFare: (ride['estimatedFare'] as num?)?.toDouble() ?? 0.0,
      receivedAt: DateTime.now(),
    );
  }
}

// ─── RideStatusEvent ─────────────────────────────────────────────────────────

/// Ride lifecycle status change event received over WebSocket
class RideStatusEvent {
  final String rideId;
  final String status;
  final String? driverId;
  final DateTime updatedAt;

  RideStatusEvent({
    required this.rideId,
    required this.status,
    this.driverId,
    required this.updatedAt,
  });

  factory RideStatusEvent.fromJson(Map<String, dynamic> json) {
    return RideStatusEvent(
      rideId: json['rideId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      driverId: json['driverId'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

// ─── RideWebSocketEvent ───────────────────────────────────────────────────────

/// Union type for all events that can arrive on a ride WebSocket channel
sealed class RideWebSocketEvent {}

class LocationUpdateEvent extends RideWebSocketEvent {
  final DriverTelemetry telemetry;
  LocationUpdateEvent(this.telemetry);
}

class StatusChangeEvent extends RideWebSocketEvent {
  final RideStatusEvent status;
  StatusChangeEvent(this.status);
}

class RideAcceptedEvent extends RideWebSocketEvent {
  final String rideId;
  final String driverId;
  RideAcceptedEvent({required this.rideId, required this.driverId});
}
