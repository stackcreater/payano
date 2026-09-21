enum VerificationStatus { pending, verified, rejected }

class VehicleDetails {
  final String vehicleType; // Scooter / Bike / Payano Moto
  final String registrationNumber; // e.g. TN 30 AB 4582
  final String modelName; // e.g. Honda Activa 6G
  final String color; // e.g. Blue
  final String ownership; // e.g. I own this vehicle
  final String helmetType; // Standard ISI Helmet Provided

  VehicleDetails({
    required this.vehicleType,
    required this.registrationNumber,
    required this.modelName,
    required this.color,
    this.ownership = 'I own this vehicle',
    this.helmetType = 'Standard ISI Helmet',
  });

  Map<String, dynamic> toMap() {
    return {
      'vehicleType': vehicleType,
      'registrationNumber': registrationNumber,
      'modelName': modelName,
      'color': color,
      'ownership': ownership,
      'helmetType': helmetType,
    };
  }

  factory VehicleDetails.fromMap(Map<String, dynamic> map) {
    return VehicleDetails(
      vehicleType: map['vehicleType'] ?? 'Scooter',
      registrationNumber: map['registrationNumber'] ?? '',
      modelName: map['modelName'] ?? '',
      color: map['color'] ?? 'Blue',
      ownership: map['ownership'] ?? 'I own this vehicle',
      helmetType: map['helmetType'] ?? 'Standard ISI Helmet',
    );
  }
}

class DriverRegistrationModel {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String email;
  final bool studentVerified;
  final String vehicleType;
  final String makeModel;
  final String registrationNumber;
  final String color;
  final String ownership;
  final Map<String, dynamic> documents;
  final String status;
  final String submittedAt;

  DriverRegistrationModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    required this.email,
    this.studentVerified = true,
    required this.vehicleType,
    required this.makeModel,
    required this.registrationNumber,
    required this.color,
    required this.ownership,
    required this.documents,
    this.status = 'PENDING_VERIFICATION',
    required this.submittedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'phone': phone,
      'email': email,
      'studentVerified': studentVerified,
      'vehicleType': vehicleType,
      'makeModel': makeModel,
      'registrationNumber': registrationNumber,
      'color': color,
      'ownership': ownership,
      'documents': documents,
      'status': status,
      'submittedAt': submittedAt,
    };
  }

  factory DriverRegistrationModel.fromMap(Map<String, dynamic> map) {
    return DriverRegistrationModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      studentVerified: map['studentVerified'] ?? true,
      vehicleType: map['vehicleType'] ?? 'Scooter',
      makeModel: map['makeModel'] ?? '',
      registrationNumber: map['registrationNumber'] ?? '',
      color: map['color'] ?? 'Blue',
      ownership: map['ownership'] ?? 'I own this vehicle',
      documents: Map<String, dynamic>.from(map['documents'] ?? {}),
      status: map['status'] ?? 'PENDING_VERIFICATION',
      submittedAt: map['submittedAt'] ?? '',
    );
  }
}

class DriverModel {
  final String id;
  final String userId;
  final String name;
  final String phone;
  final String profileImage;
  final bool isOnline;
  final bool isAvailable;
  final double latitude;
  final double longitude;
  final double heading;
  final VehicleDetails vehicle;
  final VerificationStatus verificationStatus;
  final double rating;
  final int totalRides;
  final double todayEarnings;

  DriverModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.phone,
    this.profileImage = '',
    this.isOnline = false,
    this.isAvailable = true,
    this.latitude = 12.9716, // Default Bangalore center fallback
    this.longitude = 77.5946,
    this.heading = 0.0,
    required this.vehicle,
    this.verificationStatus = VerificationStatus.pending,
    this.rating = 4.8,
    this.totalRides = 0,
    this.todayEarnings = 0.0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'phone': phone,
      'profileImage': profileImage,
      'isOnline': isOnline,
      'isAvailable': isAvailable,
      'latitude': latitude,
      'longitude': longitude,
      'heading': heading,
      'vehicle': vehicle.toMap(),
      'verificationStatus': verificationStatus.name,
      'rating': rating,
      'totalRides': totalRides,
      'todayEarnings': todayEarnings,
    };
  }

  factory DriverModel.fromMap(Map<String, dynamic> map) {
    return DriverModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      name: map['name'] ?? 'Payano Driver',
      phone: map['phone'] ?? '',
      profileImage: map['profileImage'] ?? '',
      isOnline: map['isOnline'] ?? false,
      isAvailable: map['isAvailable'] ?? true,
      latitude: (map['latitude'] as num?)?.toDouble() ?? 12.9716,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 77.5946,
      heading: (map['heading'] as num?)?.toDouble() ?? 0.0,
      vehicle: VehicleDetails.fromMap(
        Map<String, dynamic>.from(map['vehicle'] ?? {}),
      ),
      verificationStatus: VerificationStatus.values.firstWhere(
        (e) => e.name == map['verificationStatus'],
        orElse: () => VerificationStatus.pending,
      ),
      rating: (map['rating'] as num?)?.toDouble() ?? 4.8,
      totalRides: map['totalRides'] ?? 0,
      todayEarnings: (map['todayEarnings'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
