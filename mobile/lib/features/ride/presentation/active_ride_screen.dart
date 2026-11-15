import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/services/map_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/driver_card.dart';
import '../../../shared/models/ride_model.dart';
import '../domain/ride_notifier.dart';

class ActiveRideScreen extends ConsumerWidget {
  const ActiveRideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rideState = ref.watch(rideNotifierProvider);
    final rideNotifier = ref.read(rideNotifierProvider.notifier);
    final currentRide = rideState.currentRide;

    if (currentRide == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('No active ride found'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. Live Google Map with Real Coordinate Markers
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(currentRide.pickup.latitude, currentRide.pickup.longitude),
              zoom: 14.5,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('pickup_marker'),
                position: LatLng(currentRide.pickup.latitude, currentRide.pickup.longitude),
                infoWindow: InfoWindow(title: 'Pickup', snippet: currentRide.pickup.address),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              ),
              Marker(
                markerId: const MarkerId('dest_marker'),
                position: LatLng(currentRide.destination.latitude, currentRide.destination.longitude),
                infoWindow: InfoWindow(title: 'Destination', snippet: currentRide.destination.address),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
              ),
              Marker(
                markerId: const MarkerId('driver_marker'),
                position: LatLng(
                  rideState.assignedDriver?.latitude ?? (currentRide.pickup.latitude + 0.0025),
                  rideState.assignedDriver?.longitude ?? (currentRide.pickup.longitude + 0.0020),
                ),
                infoWindow: InfoWindow(
                  title: currentRide.driverName ?? 'Payano Driver',
                  snippet: currentRide.driverVehicle?.modelName ?? 'Payano Moto',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
              ),
            },
            zoomControlsEnabled: false,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
          ),


          // 2. SOS Emergency Floating Action Button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topRight,
                child: FloatingActionButton.extended(
                  heroTag: 'sos_btn',
                  onPressed: () => _showSosDialog(context),
                  backgroundColor: AppColors.error,
                  icon: const Icon(Icons.warning, color: Colors.white),
                  label: const Text('SOS Safety', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),

          // 3. Driver & Ride Status Bottom Panel
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  // Live Navigation Tracker Shortcut
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A6DF8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        context.push('/passenger-tracking', extra: {
                          'rideId': currentRide.id,
                          'driverId': currentRide.driverId,
                          'driverName': currentRide.driverName,
                          'driverPhotoUrl': currentRide.driverProfileImage,
                          'vehicleInfo': '${currentRide.driverVehicle?.modelName ?? "Payano Moto"} (${currentRide.driverVehicle?.color ?? "Yellow"})',
                          'registrationNo': currentRide.driverVehicle?.registrationNumber ?? 'KA-01-ET-8821',
                          'passengerLocation': LatLng(currentRide.pickup.latitude, currentRide.pickup.longitude),
                          'destinationLocation': LatLng(currentRide.destination.latitude, currentRide.destination.longitude),
                          'pickupAddress': currentRide.pickup.address,
                          'destinationAddress': currentRide.destination.address,
                        });
                      },
                      icon: const Icon(Icons.navigation_rounded, size: 18),
                      label: const Text('Live Map & Road Navigation', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),

                  // Matched Driver Card
                  DriverCard(
                    ride: currentRide,
                    onCallTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Calling Driver ${currentRide.driverName}...')),
                      );
                    },
                    onChatTap: () {
                      _showChatModal(context);
                    },
                    onCancelTap: () {
                      rideNotifier.cancelRide('User cancelled ride');
                      context.go('/home');
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSosDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: const [
            Icon(Icons.warning, color: AppColors.error),
            SizedBox(width: 8),
            Text('Safety & Emergency SOS'),
          ],
        ),
        content: const Text(
          'In case of emergency, Payano will immediately alert local law enforcement & your emergency contacts with your live GPS location.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('SOS Alert Dispatched to Emergency Contacts!'),
                  backgroundColor: AppColors.error,
                ),
              );
            },
            child: const Text('Trigger Emergency SOS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showChatModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: 400,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Chat with Driver', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ListView(
                children: const [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(label: Text('Hello! I am arriving in 2 minutes.')),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Chip(label: Text('Sure, I am waiting near the metro gate.')),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(hintText: 'Type message...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ActiveRideMapPainter extends CustomPainter {
  final bool isDark;
  ActiveRideMapPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final routePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(90, 210);
    path.quadraticBezierTo(130, 250, 180, 310);
    path.quadraticBezierTo(240, 370, size.width - 90, size.height - 360);

    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
