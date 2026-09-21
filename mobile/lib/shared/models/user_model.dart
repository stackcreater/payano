enum UserRole { rider, driver, admin }

class SavedLocation {
  final String id;
  final String label; // Home, Work, Gym, Favorite
  final String address;
  final double latitude;
  final double longitude;

  SavedLocation({
    required this.id,
    required this.label,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory SavedLocation.fromMap(Map<String, dynamic> map) {
    return SavedLocation(
      id: map['id'] ?? '',
      label: map['label'] ?? 'Saved Place',
      address: map['address'] ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class UserModel {
  final String uid;
  final String username;
  final String phone;
  final String name;
  final String email;
  final String profileImage;
  final UserRole role;
  final double rating;
  final double walletBalance;
  final List<SavedLocation> savedLocations;
  final DateTime createdAt;
  final String verificationStatus;
  final String studentVerificationStatus;
  final bool profileSetupCompleted;
  final String gender;
  final String dob;
  final List<String> emergencyContacts;

  UserModel({
    required this.uid,
    this.username = '',
    required this.phone,
    required this.name,
    required this.email,
    this.profileImage = '',
    this.role = UserRole.rider,
    this.rating = 5.0,
    this.walletBalance = 0.0,
    this.savedLocations = const [],
    this.verificationStatus = 'unverified',
    this.studentVerificationStatus = 'unverified',
    this.profileSetupCompleted = false,
    this.gender = '',
    this.dob = '',
    this.emergencyContacts = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'phone': phone,
      'name': name,
      'email': email,
      'profileImage': profileImage,
      'role': role.name,
      'rating': rating,
      'walletBalance': walletBalance,
      'savedLocations': savedLocations.map((x) => x.toMap()).toList(),
      'verificationStatus': verificationStatus,
      'studentVerificationStatus': studentVerificationStatus,
      'profileSetupCompleted': profileSetupCompleted,
      'gender': gender,
      'dob': dob,
      'emergencyContacts': emergencyContacts,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      phone: map['phone'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      profileImage: map['profileImage'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.rider,
      ),
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      walletBalance: (map['walletBalance'] as num?)?.toDouble() ?? 0.0,
      savedLocations: (map['savedLocations'] as List<dynamic>?)
              ?.map((x) => SavedLocation.fromMap(Map<String, dynamic>.from(x)))
              .toList() ??
          [],
      verificationStatus: map['verificationStatus'] ?? 'unverified',
      studentVerificationStatus: map['studentVerificationStatus'] ?? 'unverified',
      profileSetupCompleted: map['profileSetupCompleted'] ?? false,
      gender: map['gender'] ?? '',
      dob: map['dob'] ?? '',
      emergencyContacts: (map['emergencyContacts'] as List<dynamic>?)
              ?.map((x) => x.toString())
              .toList() ??
          [],
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
