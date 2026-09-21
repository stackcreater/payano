import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
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
          // 1. Live Map View (MapLibre GL)
          Stack(
            children: [
              MapLibreMap(
                initialCameraPosition: const CameraPosition(
                  target: LatLng(11.6643, 78.1460), // Salem, Tamil Nadu
                  zoom: 14.0,
                ),
                styleString: MapService.freeMapStyle,
                myLocationEnabled: false,
                trackCameraPosition: true,
              ),
              // Overlays (markers)
              Stack(children: [

                // Pickup Marker (Green)
                Positioned(
                  left: 80,
                  top: 200,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(4)),
                        child: const Text('PICKUP', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                      const Icon(Icons.circle, color: AppColors.success, size: 20),
                    ],
                  ),
                ),

                // Driver Location Marker (Live Moving Bike)
                Positioned(
                  left: 170,
                  top: 300,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)],
                    ),
                    child: const Icon(Icons.two_wheeler, color: Colors.black, size: 26),
                  ),
                ),

                // Destination Marker (Red)
                Positioned(
                  right: 80,
                  bottom: 350,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(4)),
                        child: const Text('DESTINATION', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                      ),
                      const Icon(Icons.location_on, color: AppColors.error, size: 28),
                    ],
                  ),
                ),
              ]),    // inner Stack children
            ],        // outer Stack children
          ),          // outer Stack


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
                  // State Demo Controller Switcher (Driver Arrived -> Trip Started -> Complete)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Simulator: ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () => rideNotifier.updateRideStatus(RideStatus.driverArrived),
                          child: const Text('Arrived', style: TextStyle(fontSize: 11)),
                        ),
                        TextButton(
                          onPressed: () => rideNotifier.updateRideStatus(RideStatus.tripStarted),
                          child: const Text('Start Trip', style: TextStyle(fontSize: 11)),
                        ),
                        TextButton(
                          onPressed: () {
                            rideNotifier.updateRideStatus(RideStatus.tripCompleted);
                            context.go('/ride-complete');
                          },
                          child: const Text('Complete', style: TextStyle(fontSize: 11, color: AppColors.success)),
                        ),
                      ],
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
