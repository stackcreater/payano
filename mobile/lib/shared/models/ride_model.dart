import 'driver_model.dart';
import 'two_wheeler_category.dart';

enum RideStatus {
  requested,
  searching,
  driverAssigned,
  driverArriving,
  driverArrived,
  tripStarted,
  tripCompleted,
  cancelled,
}

class LocationPoint {
  final String address;
  final double latitude;
  final double longitude;
  final String landmark;

  LocationPoint({
    required this.address,
    required this.latitude,
    required this.longitude,
    this.landmark = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'landmark': landmark,
    };
  }

  factory LocationPoint.fromMap(Map<String, dynamic> map) {
    return LocationPoint(
      address: map['address'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      landmark: map['landmark'] ?? '',
    );
  }
}

class RideModel {
  final String id;
  final String passengerId;
  final String? driverId;
  final String passengerName;
  final String passengerPhone;
  final String? driverName;
  final String? driverPhone;
  final String? driverProfileImage;
  final VehicleDetails? driverVehicle;
  final TwoWheelerType vehicleType;
  final LocationPoint pickup;
  final LocationPoint destination;
  final String routePolyline;
  final double distanceKm;
  final double durationMinutes;
  final double estimatedFare;
  final double finalFare;
  final RideStatus status;
  final String startOtp;
  final String paymentMethod; // Cash, UPI, Wallet, Card
  final bool isPaid;
  final String? cancellationReason;
  final double? ratingGiven;
  final String? reviewText;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  RideModel({
    required this.id,
    required this.passengerId,
    this.driverId,
    required this.passengerName,
    required this.passengerPhone,
    this.driverName,
    this.driverPhone,
    this.driverProfileImage,
    this.driverVehicle,
    required this.vehicleType,
    required this.pickup,
    required this.destination,
    this.routePolyline = '',
    required this.distanceKm,
    required this.durationMinutes,
    required this.estimatedFare,
    required this.finalFare,
    required this.status,
    required this.startOtp,
    this.paymentMethod = 'UPI',
    this.isPaid = false,
    this.cancellationReason,
    this.ratingGiven,
    this.reviewText,
    DateTime? createdAt,
    this.startedAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'passengerId': passengerId,
      'driverId': driverId,
      'passengerName': passengerName,
      'passengerPhone': passengerPhone,
      'driverName': driverName,
      'driverPhone': driverPhone,
      'driverProfileImage': driverProfileImage,
      'driverVehicle': driverVehicle?.toMap(),
      'vehicleType': vehicleType.name,
      'pickup': pickup.toMap(),
      'destination': destination.toMap(),
      'routePolyline': routePolyline,
      'distanceKm': distanceKm,
      'durationMinutes': durationMinutes,
      'estimatedFare': estimatedFare,
      'finalFare': finalFare,
      'status': status.name,
      'startOtp': startOtp,
      'paymentMethod': paymentMethod,
      'isPaid': isPaid,
      'cancellationReason': cancellationReason,
      'ratingGiven': ratingGiven,
      'reviewText': reviewText,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory RideModel.fromMap(Map<String, dynamic> map) {
    return RideModel(
      id: map['id'] ?? '',
      passengerId: map['passengerId'] ?? '',
      driverId: map['driverId'],
      passengerName: map['passengerName'] ?? 'Passenger',
      passengerPhone: map['passengerPhone'] ?? '',
      driverName: map['driverName'],
      driverPhone: map['driverPhone'],
      driverProfileImage: map['driverProfileImage'],
      driverVehicle: map['driverVehicle'] != null
          ? VehicleDetails.fromMap(Map<String, dynamic>.from(map['driverVehicle']))
          : null,
      vehicleType: TwoWheelerType.values.firstWhere(
        (e) => e.name == map['vehicleType'],
        orElse: () => TwoWheelerType.moto,
      ),
      pickup: LocationPoint.fromMap(Map<String, dynamic>.from(map['pickup'] ?? {})),
      destination: LocationPoint.fromMap(Map<String, dynamic>.from(map['destination'] ?? {})),
      routePolyline: map['routePolyline'] ?? '',
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: (map['durationMinutes'] as num?)?.toDouble() ?? 0.0,
      estimatedFare: (map['estimatedFare'] as num?)?.toDouble() ?? 0.0,
      finalFare: (map['finalFare'] as num?)?.toDouble() ?? 0.0,
      status: RideStatus.values.firstWhere(
        (e) => e.name.toLowerCase() == (map['status'] ?? '').toString().replaceAll('_', '').toLowerCase(),
        orElse: () => RideStatus.requested,
      ),
      startOtp: map['startOtp'] ?? '1234',
      paymentMethod: map['paymentMethod'] ?? 'UPI',
      isPaid: map['isPaid'] ?? false,
      cancellationReason: map['cancellationReason'],
      ratingGiven: (map['ratingGiven'] as num?)?.toDouble(),
      reviewText: map['reviewText'],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      startedAt: map['startedAt'] != null ? DateTime.tryParse(map['startedAt']) : null,
      completedAt: map['completedAt'] != null ? DateTime.tryParse(map['completedAt']) : null,
    );
  }
}
