import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/ride_model.dart';
import '../../../shared/models/driver_model.dart';
import '../../../shared/models/two_wheeler_category.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/ride_service.dart';

class RideState {
  final LocationPoint? pickup;
  final LocationPoint? destination;
  final TwoWheelerCategory selectedCategory;
  final RideModel? currentRide;
  final DriverModel? assignedDriver;
  final String activePromoCode;
  final double discountAmount;
  final bool isLoading;
  final String? errorMessage;

  RideState({
    this.pickup,
    this.destination,
    required this.selectedCategory,
    this.currentRide,
    this.assignedDriver,
    this.activePromoCode = '',
    this.discountAmount = 0.0,
    this.isLoading = false,
    this.errorMessage,
  });

  RideState copyWith({
    LocationPoint? pickup,
    LocationPoint? destination,
    TwoWheelerCategory? selectedCategory,
    RideModel? currentRide,
    DriverModel? assignedDriver,
    String? activePromoCode,
    double? discountAmount,
    bool? isLoading,
    String? errorMessage,
    bool clearRide = false,
  }) {
    return RideState(
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      currentRide: clearRide ? null : (currentRide ?? this.currentRide),
      assignedDriver: clearRide ? null : (assignedDriver ?? this.assignedDriver),
      activePromoCode: activePromoCode ?? this.activePromoCode,
      discountAmount: discountAmount ?? this.discountAmount,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

final rideNotifierProvider = StateNotifierProvider<RideNotifier, RideState>((ref) {
  final locationService = ref.watch(locationServiceProvider);
  final rideService = ref.watch(rideServiceProvider);
  return RideNotifier(locationService, rideService);
});

class RideNotifier extends StateNotifier<RideState> {
  final LocationService _locationService;
  final RideService _rideService;
  Timer? _matchingTimer;

  RideNotifier(this._locationService, this._rideService)
      : super(
          RideState(
            pickup: LocationPoint(
              address: 'Current Location • MG Road Metro Station, Bengaluru',
              latitude: 12.9716,
              longitude: 77.5946,
            ),
            destination: null,
            selectedCategory: TwoWheelerCategory.categories[1], // Payano Moto default
          ),
        );

  void setPickup(LocationPoint point) {
    state = state.copyWith(pickup: point);
  }

  void setDestination(LocationPoint point) {
    state = state.copyWith(destination: point);
  }

  void selectCategory(TwoWheelerCategory category) {
    state = state.copyWith(selectedCategory: category);
  }

  void applyPromoCode(String code) {
    if (code.toUpperCase() == 'PAYANO50') {
      state = state.copyWith(activePromoCode: 'PAYANO50', discountAmount: 25.0);
    } else if (code.toUpperCase() == 'FIRSTBIKE') {
      state = state.copyWith(activePromoCode: 'FIRSTBIKE', discountAmount: 30.0);
    } else {
      state = state.copyWith(errorMessage: 'Invalid promo code');
    }
  }

  Future<void> requestRide({required String passengerName, required String passengerPhone}) async {
    if (state.pickup == null || state.destination == null) return;

    state = state.copyWith(isLoading: true);

    final distanceKm = _locationService.calculateDistanceKm(
      state.pickup!.latitude,
      state.pickup!.longitude,
      state.destination!.latitude,
      state.destination!.longitude,
    );

    final durationMins = (distanceKm * 2.8).clamp(3.0, 90.0);
    final rawFare = state.selectedCategory.calculateFare(
      distanceKm: distanceKm,
      durationMins: durationMins,
    );

    final finalFare = (rawFare - state.discountAmount).clamp(20.0, 5000.0);

    // Call REST backend POST /rides/create (or fallback to local creation if offline)
    final createdRide = await _rideService.createRide(
      passengerId: 'usr_rider_1',
      passengerName: passengerName,
      passengerPhone: passengerPhone,
      pickupLat: state.pickup!.latitude,
      pickupLng: state.pickup!.longitude,
      pickupAddress: state.pickup!.address,
      destinationLat: state.destination!.latitude,
      destinationLng: state.destination!.longitude,
      destinationAddress: state.destination!.address,
      category: state.selectedCategory.id,
    );

    final newRide = RideModel(
      id: createdRide.id,
      passengerId: createdRide.passengerId.isNotEmpty ? createdRide.passengerId : 'usr_rider_1',
      passengerName: passengerName,
      passengerPhone: passengerPhone,
      vehicleType: state.selectedCategory.type,
      pickup: state.pickup!,
      destination: state.destination!,
      distanceKm: double.parse(distanceKm.toStringAsFixed(1)),
      durationMinutes: double.parse(durationMins.toStringAsFixed(0)),
      estimatedFare: double.parse(finalFare.toStringAsFixed(0)),
      finalFare: double.parse(finalFare.toStringAsFixed(0)),
      status: RideStatus.searching,
      startOtp: createdRide.startOtp,
    );

    state = state.copyWith(
      currentRide: newRide,
      isLoading: false,
    );

    // Trigger Driver Searching Radar & Match Driver in 5 seconds (fallback matching)
    _startDriverMatchingSimulation();
  }

  void _startDriverMatchingSimulation() {
    _matchingTimer?.cancel();
    _matchingTimer = Timer(const Duration(seconds: 4), () {
      if (state.currentRide == null || state.currentRide!.status != RideStatus.searching) return;

      final driver = DriverModel(
        id: 'drv_driver_matched',
        userId: 'usr_driver_matched',
        name: 'Ramesh Kumar',
        phone: '+91 98450 12345',
        profileImage: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        isOnline: true,
        latitude: state.pickup!.latitude + 0.003,
        longitude: state.pickup!.longitude + 0.002,
        vehicle: VehicleDetails(
          vehicleType: 'Payano Moto',
          registrationNumber: 'KA-01-EQ-5432',
          modelName: 'TVS Raider 125',
          color: 'Electric Yellow',
        ),
        rating: 4.9,
        totalRides: 890,
      );

      final updatedRide = RideModel(
        id: state.currentRide!.id,
        passengerId: state.currentRide!.passengerId,
        driverId: driver.id,
        passengerName: state.currentRide!.passengerName,
        passengerPhone: state.currentRide!.passengerPhone,
        driverName: driver.name,
        driverPhone: driver.phone,
        driverProfileImage: driver.profileImage,
        driverVehicle: driver.vehicle,
        vehicleType: state.currentRide!.vehicleType,
        pickup: state.currentRide!.pickup,
        destination: state.currentRide!.destination,
        distanceKm: state.currentRide!.distanceKm,
        durationMinutes: state.currentRide!.durationMinutes,
        estimatedFare: state.currentRide!.estimatedFare,
        finalFare: state.currentRide!.finalFare,
        status: RideStatus.driverArriving,
        startOtp: state.currentRide!.startOtp,
      );

      state = state.copyWith(
        currentRide: updatedRide,
        assignedDriver: driver,
      );
    });
  }

  void updateRideStatus(RideStatus newStatus) {
    if (state.currentRide == null) return;

    final updatedRide = RideModel(
      id: state.currentRide!.id,
      passengerId: state.currentRide!.passengerId,
      driverId: state.currentRide!.driverId,
      passengerName: state.currentRide!.passengerName,
      passengerPhone: state.currentRide!.passengerPhone,
      driverName: state.currentRide!.driverName,
      driverPhone: state.currentRide!.driverPhone,
      driverProfileImage: state.currentRide!.driverProfileImage,
      driverVehicle: state.currentRide!.driverVehicle,
      vehicleType: state.currentRide!.vehicleType,
      pickup: state.currentRide!.pickup,
      destination: state.currentRide!.destination,
      distanceKm: state.currentRide!.distanceKm,
      durationMinutes: state.currentRide!.durationMinutes,
      estimatedFare: state.currentRide!.estimatedFare,
      finalFare: state.currentRide!.finalFare,
      status: newStatus,
      startOtp: state.currentRide!.startOtp,
      paymentMethod: state.currentRide!.paymentMethod,
      isPaid: newStatus == RideStatus.tripCompleted ? true : state.currentRide!.isPaid,
      startedAt: newStatus == RideStatus.tripStarted ? DateTime.now() : state.currentRide!.startedAt,
      completedAt: newStatus == RideStatus.tripCompleted ? DateTime.now() : state.currentRide!.completedAt,
    );

    state = state.copyWith(currentRide: updatedRide);
  }

  void cancelRide(String reason) {
    _matchingTimer?.cancel();
    if (state.currentRide != null) {
      updateRideStatus(RideStatus.cancelled);
    }
    state = state.copyWith(clearRide: true);
  }

  void resetRide() {
    _matchingTimer?.cancel();
    state = state.copyWith(clearRide: true, destination: null);
  }

  @override
  void dispose() {
    _matchingTimer?.cancel();
    super.dispose();
  }
}
