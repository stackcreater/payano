import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DriverTripState {
  offline,
  onlineSearching,
  rideOffered,
  navigatingToPickup,
  arrivedAtPickup,
  pinVerification,
  inTrip,
  rideCompleted,
}

class DriverRideRecord {
  final String id;
  final String riderName;
  final String riderPhoto;
  final String pickupName;
  final String pickupAddress;
  final String dropName;
  final String dropAddress;
  final String startTime;
  final String endTime;
  final double distanceKm;
  final int durationMin;
  final double totalFare;
  final double driverEarnings;
  final String status; // Completed, Cancelled
  final String dateText;

  const DriverRideRecord({
    required this.id,
    required this.riderName,
    required this.riderPhoto,
    required this.pickupName,
    required this.pickupAddress,
    required this.dropName,
    required this.dropAddress,
    required this.startTime,
    required this.endTime,
    required this.distanceKm,
    required this.durationMin,
    required this.totalFare,
    required this.driverEarnings,
    this.status = 'Completed',
    required this.dateText,
  });
}

class DriverActiveRide {
  final String id;
  final String riderName;
  final String riderPhoto;
  final int passengerCount;
  final String pickupName;
  final String pickupAddress;
  final String dropName;
  final String dropAddress;
  final double pickupKm;
  final int pickupMin;
  final double dropKm;
  final int dropMin;
  final double totalFare;
  final double driverEarnings;
  final String pin;
  final String pickupNote;
  final int speedKmh;

  const DriverActiveRide({
    required this.id,
    required this.riderName,
    required this.riderPhoto,
    required this.passengerCount,
    required this.pickupName,
    required this.pickupAddress,
    required this.dropName,
    required this.dropAddress,
    required this.pickupKm,
    required this.pickupMin,
    required this.dropKm,
    required this.dropMin,
    required this.totalFare,
    required this.driverEarnings,
    required this.pin,
    required this.pickupNote,
    this.speedKmh = 21,
  });
}

class DriverProfileData {
  final String name;
  final String driverId;
  final double rating;
  final int ridesCompleted;
  final String collegeName;
  final String vehicleModel;
  final String vehicleRegNo;
  final String vehicleColor;
  final double monthlyEarnings;
  final int monthlyRides;
  final String monthlyOnlineTime;

  const DriverProfileData({
    required this.name,
    required this.driverId,
    required this.rating,
    required this.ridesCompleted,
    required this.collegeName,
    required this.vehicleModel,
    required this.vehicleRegNo,
    required this.vehicleColor,
    required this.monthlyEarnings,
    required this.monthlyRides,
    required this.monthlyOnlineTime,
  });

  DriverProfileData copyWith({
    String? name,
    String? driverId,
    double? rating,
    int? ridesCompleted,
    String? collegeName,
    String? vehicleModel,
    String? vehicleRegNo,
    String? vehicleColor,
    double? monthlyEarnings,
    int? monthlyRides,
    String? monthlyOnlineTime,
  }) {
    return DriverProfileData(
      name: name ?? this.name,
      driverId: driverId ?? this.driverId,
      rating: rating ?? this.rating,
      ridesCompleted: ridesCompleted ?? this.ridesCompleted,
      collegeName: collegeName ?? this.collegeName,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleRegNo: vehicleRegNo ?? this.vehicleRegNo,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      monthlyEarnings: monthlyEarnings ?? this.monthlyEarnings,
      monthlyRides: monthlyRides ?? this.monthlyRides,
      monthlyOnlineTime: monthlyOnlineTime ?? this.monthlyOnlineTime,
    );
  }
}

class DriverFlowState {
  final DriverTripState tripState;
  final bool isOnline;
  final int offerTimerSeconds;
  final double todayEarnings;
  final int todayRides;
  final String onlineHours;
  final DriverActiveRide activeRide;
  final List<DriverRideRecord> ridesHistory;
  final DriverProfileData profile;

  const DriverFlowState({
    required this.tripState,
    required this.isOnline,
    required this.offerTimerSeconds,
    required this.todayEarnings,
    required this.todayRides,
    required this.onlineHours,
    required this.activeRide,
    required this.ridesHistory,
    required this.profile,
  });

  DriverFlowState copyWith({
    DriverTripState? tripState,
    bool? isOnline,
    int? offerTimerSeconds,
    double? todayEarnings,
    int? todayRides,
    String? onlineHours,
    DriverActiveRide? activeRide,
    List<DriverRideRecord>? ridesHistory,
    DriverProfileData? profile,
  }) {
    return DriverFlowState(
      tripState: tripState ?? this.tripState,
      isOnline: isOnline ?? this.isOnline,
      offerTimerSeconds: offerTimerSeconds ?? this.offerTimerSeconds,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      todayRides: todayRides ?? this.todayRides,
      onlineHours: onlineHours ?? this.onlineHours,
      activeRide: activeRide ?? this.activeRide,
      ridesHistory: ridesHistory ?? this.ridesHistory,
      profile: profile ?? this.profile,
    );
  }
}

class DriverFlowNotifier extends StateNotifier<DriverFlowState> {
  Timer? _countdownTimer;

  DriverFlowNotifier()
      : super(
          DriverFlowState(
            tripState: DriverTripState.offline,
            isOnline: false,
            offerTimerSeconds: 15,
            todayEarnings: 204.00,
            todayRides: 6,
            onlineHours: '2h 15m',
            activeRide: const DriverActiveRide(
              id: 'ride_101',
              riderName: 'Nandhini R',
              riderPhoto: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
              passengerCount: 1,
              pickupName: 'Sona College of Technology',
              pickupAddress: 'Junction Main Road\nSuramangalam, Salem 636005',
              dropName: 'Salem Junction',
              dropAddress: 'Salem, Tamil Nadu 636001',
              pickupKm: 0.8,
              pickupMin: 3,
              dropKm: 4.2,
              dropMin: 12,
              totalFare: 42.00,
              driverEarnings: 34.00,
              pin: '4582',
              pickupNote: "I'll be waiting near the main gate. Please call when you reach.",
              speedKmh: 21,
            ),
            ridesHistory: const [
              DriverRideRecord(
                id: 'R001',
                riderName: 'Nandhini R',
                riderPhoto: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
                pickupName: 'Sona College of Technology',
                pickupAddress: 'Junction Main Road, Suramangalam',
                dropName: 'Salem Junction',
                dropAddress: 'Salem, Tamil Nadu 636001',
                startTime: '10:24 AM',
                endTime: '10:36 AM',
                distanceKm: 4.2,
                durationMin: 12,
                totalFare: 42.00,
                driverEarnings: 34.00,
                dateText: 'Today, 12 Aug 2026',
              ),
              DriverRideRecord(
                id: 'R002',
                riderName: 'Karthik S',
                riderPhoto: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
                pickupName: 'Sona College of Technology',
                pickupAddress: 'Main Gate',
                dropName: 'Salem New Bus Stand',
                dropAddress: 'Meyyanur, Salem',
                startTime: '09:05 AM',
                endTime: '09:14 AM',
                distanceKm: 2.7,
                durationMin: 9,
                totalFare: 28.00,
                driverEarnings: 22.00,
                dateText: 'Today, 12 Aug 2026',
              ),
              DriverRideRecord(
                id: 'R003',
                riderName: 'Pooja V',
                riderPhoto: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=400',
                pickupName: 'Sona College of Technology',
                pickupAddress: 'Hostel Block C',
                dropName: 'Hasthampatti',
                dropAddress: 'Hasthampatti Circle, Salem',
                startTime: '08:15 AM',
                endTime: '08:28 AM',
                distanceKm: 3.6,
                durationMin: 13,
                totalFare: 30.00,
                driverEarnings: 24.00,
                dateText: 'Today, 12 Aug 2026',
              ),
              DriverRideRecord(
                id: 'R004',
                riderName: 'Arjun K',
                riderPhoto: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=400',
                pickupName: 'Five Roads',
                pickupAddress: 'Junction Junction',
                dropName: 'Sona College of Technology',
                dropAddress: 'Campus Portico',
                startTime: '07:30 AM',
                endTime: '07:41 AM',
                distanceKm: 2.9,
                durationMin: 11,
                totalFare: 31.00,
                driverEarnings: 25.00,
                dateText: 'Today, 12 Aug 2026',
              ),
              DriverRideRecord(
                id: 'R005',
                riderName: 'Divya M',
                riderPhoto: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400',
                pickupName: 'Sona College of Technology',
                pickupAddress: 'ECE Department',
                dropName: 'Salem Junction',
                dropAddress: 'Platform 1 Gate',
                startTime: '06:45 AM',
                endTime: '06:55 AM',
                distanceKm: 4.2,
                durationMin: 12,
                totalFare: 33.00,
                driverEarnings: 26.00,
                dateText: 'Today, 12 Aug 2026',
              ),
              DriverRideRecord(
                id: 'R006',
                riderName: 'Vignesh P',
                riderPhoto: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400',
                pickupName: 'Ammapet',
                pickupAddress: 'Main Bazaar',
                dropName: 'Sona College of Technology',
                dropAddress: 'Main Gate',
                startTime: '06:05 AM',
                endTime: '06:15 AM',
                distanceKm: 2.4,
                durationMin: 10,
                totalFare: 40.00,
                driverEarnings: 32.00,
                dateText: 'Today, 12 Aug 2026',
              ),
            ],
            profile: const DriverProfileData(
              name: 'Rakshak M P',
              driverId: 'PAY12345',
              rating: 4.8,
              ridesCompleted: 120,
              collegeName: 'Sona College of Technology',
              vehicleModel: 'Honda Activa 6G',
              vehicleRegNo: 'TN 30 AB 4582',
              vehicleColor: 'Blue',
              monthlyEarnings: 2184.00,
              monthlyRides: 48,
              monthlyOnlineTime: '36h 20m',
            ),
          ),
        );

  void goOnline() {
    state = state.copyWith(
      isOnline: true,
      tripState: DriverTripState.onlineSearching,
    );
    // Simulate auto ride offer after 3.5s for seamless interactive experience
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted && state.isOnline && state.tripState == DriverTripState.onlineSearching) {
        triggerRideOffer();
      }
    });
  }

  void goOffline() {
    _countdownTimer?.cancel();
    state = state.copyWith(
      isOnline: false,
      tripState: DriverTripState.offline,
    );
  }

  void triggerRideOffer() {
    _countdownTimer?.cancel();
    state = state.copyWith(
      tripState: DriverTripState.rideOffered,
      offerTimerSeconds: 15,
    );
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.offerTimerSeconds > 1) {
        state = state.copyWith(offerTimerSeconds: state.offerTimerSeconds - 1);
      } else {
        declineRide();
      }
    });
  }

  void acceptRide() {
    _countdownTimer?.cancel();
    state = state.copyWith(
      tripState: DriverTripState.navigatingToPickup,
    );
  }

  void declineRide() {
    _countdownTimer?.cancel();
    state = state.copyWith(
      tripState: DriverTripState.onlineSearching,
    );
  }

  void arrivedAtPickup() {
    state = state.copyWith(
      tripState: DriverTripState.arrivedAtPickup,
    );
  }

  void openPinModal() {
    state = state.copyWith(
      tripState: DriverTripState.pinVerification,
    );
  }

  void closePinModal() {
    state = state.copyWith(
      tripState: DriverTripState.arrivedAtPickup,
    );
  }

  bool verifyPinAndStartRide(String enteredPin) {
    if (enteredPin.trim() == state.activeRide.pin) {
      state = state.copyWith(
        tripState: DriverTripState.inTrip,
      );
      return true;
    }
    return false;
  }

  void endRide() {
    state = state.copyWith(
      tripState: DriverTripState.rideCompleted,
    );
  }

  void finishTripAndReturnHome() {
    final earned = state.activeRide.driverEarnings;
    final newTodayEarnings = state.todayEarnings + earned;
    final newTodayRides = state.todayRides + 1;

    final newRideRecord = DriverRideRecord(
      id: 'R${DateTime.now().millisecondsSinceEpoch % 10000}',
      riderName: state.activeRide.riderName,
      riderPhoto: state.activeRide.riderPhoto,
      pickupName: state.activeRide.pickupName,
      pickupAddress: state.activeRide.pickupAddress.replaceAll('\n', ', '),
      dropName: state.activeRide.dropName,
      dropAddress: state.activeRide.dropAddress,
      startTime: '10:24 AM',
      endTime: '10:36 AM',
      distanceKm: state.activeRide.dropKm,
      durationMin: state.activeRide.dropMin,
      totalFare: state.activeRide.totalFare,
      driverEarnings: state.activeRide.driverEarnings,
      dateText: 'Today, 12 Aug 2026',
    );

    final updatedHistory = [newRideRecord, ...state.ridesHistory];
    final updatedProfile = state.profile.copyWith(
      ridesCompleted: state.profile.ridesCompleted + 1,
      monthlyRides: state.profile.monthlyRides + 1,
      monthlyEarnings: state.profile.monthlyEarnings + earned,
    );

    state = state.copyWith(
      todayEarnings: newTodayEarnings,
      todayRides: newTodayRides,
      ridesHistory: updatedHistory,
      profile: updatedProfile,
      tripState: DriverTripState.onlineSearching,
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}

final driverFlowProvider = StateNotifierProvider<DriverFlowNotifier, DriverFlowState>((ref) {
  return DriverFlowNotifier();
});
