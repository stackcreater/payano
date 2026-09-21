import 'package:go_router/go_router.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/signup_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/auth/presentation/profile_setup_screen.dart';
import '../features/auth/presentation/student_verification_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/home/presentation/location_search_screen.dart';
import '../features/ride/presentation/searching_driver_screen.dart';
import '../features/ride/presentation/active_ride_screen.dart';
import '../features/ride/presentation/ride_complete_screen.dart';
import '../features/ride/presentation/ride_details_screen.dart';
import '../features/ride/presentation/payment_processing_screen.dart';
import '../features/ride/presentation/payment_complete_screen.dart';
import '../features/driver/presentation/driver_home_screen.dart';
import '../features/driver/presentation/driver_onboarding_screen.dart';
import '../features/driver/presentation/driver_earnings_screen.dart';
import '../features/driver/presentation/driver_rides_screen.dart';
import '../features/driver/presentation/driver_profile_screen.dart';
import '../features/driver/presentation/driver_documents_screen.dart';
import '../features/driver/presentation/driver_settings_screen.dart';
import '../features/wallet/presentation/wallet_screen.dart';
import '../features/wallet/presentation/payment_method_screen.dart';
import '../features/wallet/presentation/add_card_screen.dart';
import '../features/wallet/presentation/add_upi_screen.dart';
import '../features/history/presentation/ride_history_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/support/presentation/support_screen.dart';
import '../features/admin/presentation/admin_dashboard_screen.dart';
import '../features/notifications/presentation/notifications_screen.dart';
import '../features/tracking/presentation/passenger_tracking_screen.dart';
import '../features/tracking/presentation/driver_tracking_screen.dart';


class AppRouter {
  static final router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final phone = state.extra as String? ?? '+91 98765 43210';
          return OtpScreen(phone: phone);
        },
      ),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/student-verification',
        builder: (context, state) => const StudentVerificationScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/location-search',
        builder: (context, state) => const LocationSearchScreen(),
      ),
      GoRoute(
        path: '/searching-driver',
        builder: (context, state) => const SearchingDriverScreen(),
      ),
      GoRoute(
        path: '/active-ride',
        builder: (context, state) => const ActiveRideScreen(),
      ),
      GoRoute(
        path: '/ride-complete',
        builder: (context, state) => const RideCompleteScreen(),
      ),
      GoRoute(
        path: '/ride-details',
        builder: (context, state) {
          final ride = state.extra;
          return RideDetailsScreen(ride: ride as dynamic);
        },
      ),
      GoRoute(
        path: '/payment-processing',
        builder: (context, state) => const PaymentProcessingScreen(),
      ),
      GoRoute(
        path: '/payment-complete',
        builder: (context, state) => const PaymentCompleteScreen(),
      ),
      GoRoute(
        path: '/driver/home',
        builder: (context, state) => const DriverHomeScreen(),
      ),
      GoRoute(
        path: '/driver/onboarding',
        builder: (context, state) => const DriverOnboardingScreen(),
      ),
      GoRoute(
        path: '/driver/documents',
        builder: (context, state) => const DriverDocumentsScreen(),
      ),
      GoRoute(
        path: '/driver/rides',
        builder: (context, state) => const DriverRidesScreen(),
      ),
      GoRoute(
        path: '/driver/earnings',
        builder: (context, state) => const DriverEarningsScreen(),
      ),
      GoRoute(
        path: '/driver/profile',
        builder: (context, state) => const DriverProfileScreen(),
      ),
      GoRoute(
        path: '/driver/settings',
        builder: (context, state) => const DriverSettingsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const DriverSettingsScreen(),
      ),
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/payment-method',
        builder: (context, state) => const PaymentMethodScreen(),
      ),
      GoRoute(
        path: '/add-card',
        builder: (context, state) => const AddCardScreen(),
      ),
      GoRoute(
        path: '/add-upi',
        builder: (context, state) => const AddUPIScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const RideHistoryScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/support',
        builder: (context, state) => const SupportScreen(isDriver: false),
      ),
      GoRoute(
        path: '/driver/support',
        builder: (context, state) => const SupportScreen(isDriver: true),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/passenger-tracking',
        builder: (context, state) => const PassengerTrackingScreen(),
      ),
      GoRoute(
        path: '/driver-tracking',
        builder: (context, state) => const DriverTrackingScreen(),
      ),
    ],
  );
}

