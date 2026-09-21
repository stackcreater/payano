import 'package:flutter_test/flutter_test.dart';
import 'package:payano_mobile/features/driver/presentation/providers/driver_flow_provider.dart';

void main() {
  group('Payano Driver Flow State Machine Tests', () {
    late DriverFlowNotifier notifier;

    setUp(() {
      notifier = DriverFlowNotifier();
    });

    tearDown(() {
      notifier.dispose();
    });

    test('Initial driver state is offline with initial stats', () {
      final state = notifier.state;
      expect(state.isOnline, false);
      expect(state.tripState, DriverTripState.offline);
      expect(state.todayEarnings, 204.00);
      expect(state.todayRides, 6);
      expect(state.ridesHistory.length, 6);
      expect(state.profile.name, 'Rakshak M P');
    });

    test('goOnline transitions to onlineSearching', () {
      notifier.goOnline();
      final state = notifier.state;
      expect(state.isOnline, true);
      expect(state.tripState, DriverTripState.onlineSearching);
    });

    test('Ride offer lifecycle: trigger, decline', () {
      notifier.goOnline();
      notifier.triggerRideOffer();
      expect(notifier.state.tripState, DriverTripState.rideOffered);
      expect(notifier.state.offerTimerSeconds, 15);

      notifier.declineRide();
      expect(notifier.state.tripState, DriverTripState.onlineSearching);
    });

    test('Full Ride Lifecycle: Accept -> Navigate -> Arrive -> PIN -> In Trip -> End -> Complete -> Finish', () {
      notifier.goOnline();
      notifier.triggerRideOffer();
      expect(notifier.state.tripState, DriverTripState.rideOffered);

      // 1. Accept ride
      notifier.acceptRide();
      expect(notifier.state.tripState, DriverTripState.navigatingToPickup);

      // 2. Mark arrived
      notifier.arrivedAtPickup();
      expect(notifier.state.tripState, DriverTripState.arrivedAtPickup);

      // 3. Open PIN modal
      notifier.openPinModal();
      expect(notifier.state.tripState, DriverTripState.pinVerification);

      // 4. Test wrong PIN
      final wrongResult = notifier.verifyPinAndStartRide('0000');
      expect(wrongResult, false);
      expect(notifier.state.tripState, DriverTripState.pinVerification);

      // 5. Test correct PIN (4582)
      final correctResult = notifier.verifyPinAndStartRide('4582');
      expect(correctResult, true);
      expect(notifier.state.tripState, DriverTripState.inTrip);

      // 6. End Ride
      notifier.endRide();
      expect(notifier.state.tripState, DriverTripState.rideCompleted);

      // 7. Finish Trip and verify data consistency
      final initialEarnings = notifier.state.todayEarnings;
      final initialRides = notifier.state.todayRides;
      final initialHistoryCount = notifier.state.ridesHistory.length;

      notifier.finishTripAndReturnHome();

      final updatedState = notifier.state;
      expect(updatedState.todayEarnings, initialEarnings + 34.00);
      expect(updatedState.todayRides, initialRides + 1);
      expect(updatedState.ridesHistory.length, initialHistoryCount + 1);
      expect(updatedState.ridesHistory.first.riderName, 'Nandhini R');
      expect(updatedState.ridesHistory.first.driverEarnings, 34.00);
      expect(updatedState.profile.ridesCompleted, 121);
      expect(updatedState.tripState, DriverTripState.onlineSearching);
    });

    test('goOffline transitions back to offline', () {
      notifier.goOnline();
      expect(notifier.state.isOnline, true);
      notifier.goOffline();
      expect(notifier.state.isOnline, false);
      expect(notifier.state.tripState, DriverTripState.offline);
    });
  });
}
