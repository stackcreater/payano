import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:payano_mobile/core/services/map_service.dart';
import 'package:payano_mobile/core/widgets/payano_avatar.dart';

void main() {
  group('Payano Routing & MapService Tests', () {
    final mapService = MapService();

    test('calculateRoute returns valid RouteResult between pickup and dropoff', () async {
      // Salem Hasthampatti -> Sona College
      const start = LatLng(11.6520, 78.1340);
      const destination = LatLng(11.6756, 78.1470);

      final route = await mapService.calculateRoute(start: start, destination: destination);

      expect(route.points.isNotEmpty, true);
      expect(route.distanceKm, greaterThan(0.0));
      expect(route.durationMinutes, greaterThan(0.0));
      expect(['OSRM', 'Valhalla', 'Direct Estimate'].contains(route.provider), true);
    });
  });

  group('PayanoAvatar Tests', () {
    testWidgets('Renders first letter initial for Subash (S)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PayanoAvatar(name: 'Subash', radius: 24),
          ),
        ),
      );
      expect(find.text('S'), findsOneWidget);
    });

    testWidgets('Renders first letter initial for Karthi (K)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PayanoAvatar(name: 'Karthi', radius: 24),
          ),
        ),
      );
      expect(find.text('K'), findsOneWidget);
    });
  });
}
