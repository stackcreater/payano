import 'dart:convert';
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../config/app_config.dart';

/// Place prediction result
class PlacePrediction {
  final String description;
  final String placeId;
  final String mainText;
  final String secondaryText;
  final double? latitude;
  final double? longitude;

  PlacePrediction({
    required this.description,
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
    this.latitude,
    this.longitude,
  });
}

/// Result model for calculated routes
class RouteResult {
  final List<LatLng> points;
  final double distanceKm;
  final double durationMinutes;
  final String provider;

  RouteResult({
    required this.points,
    required this.distanceKm,
    required this.durationMinutes,
    this.provider = 'Google Maps',
  });

  factory RouteResult.empty() {
    return RouteResult(
      points: [],
      distanceKm: 0.0,
      durationMinutes: 0.0,
      provider: 'None',
    );
  }
}

/// Service handling routing (Google Directions, OSRM, Valhalla) and Google Places / Geocoding APIs
class MapService {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      headers: {
        'User-Agent': 'PayanoApp/1.0 (Ride-Sharing Platform; contact@payano.app)',
        'Accept': 'application/json',
      },
    ),
  );

  // Curated popular locations centered around Sona College of Technology & Salem
  static final List<PlacePrediction> defaultSalemPlaces = [
    PlacePrediction(
      description: 'Sona College of Technology, Junction Main Road, Salem',
      placeId: 'sona_college_main',
      mainText: 'Sona College of Technology',
      secondaryText: 'Junction Main Road, Salem (Campus Landmark)',
      latitude: 11.6756,
      longitude: 78.1470,
    ),
    PlacePrediction(
      description: 'Salem Junction Railway Station, Suramangalam, Salem',
      placeId: 'salem_junction_railway',
      mainText: 'Salem Junction Railway Station',
      secondaryText: 'Suramangalam, Salem',
      latitude: 11.6648,
      longitude: 78.1460,
    ),
    PlacePrediction(
      description: 'Salem New Bus Stand, Meyyanur, Salem',
      placeId: 'salem_new_bus_stand',
      mainText: 'Salem New Bus Stand',
      secondaryText: 'Meyyanur, Salem',
      latitude: 11.6620,
      longitude: 78.1570,
    ),
    PlacePrediction(
      description: 'Five Roads Junction, Salem Central',
      placeId: 'salem_five_roads',
      mainText: 'Five Roads Junction',
      secondaryText: 'Salem Central',
      latitude: 11.6730,
      longitude: 78.1610,
    ),
    PlacePrediction(
      description: 'AVR Roundana, Junction Main Road, Salem',
      placeId: 'salem_avr_roundana',
      mainText: 'AVR Roundana',
      secondaryText: 'Junction Main Road, Salem',
      latitude: 11.6780,
      longitude: 78.1510,
    ),
    PlacePrediction(
      description: 'Saradha College Road, Fairlands, Salem',
      placeId: 'salem_saradha_college',
      mainText: 'Saradha College Road',
      secondaryText: 'Fairlands, Salem',
      latitude: 11.6830,
      longitude: 78.1580,
    ),
  ];

  // Inline MapLibre style — works on both web and mobile without asset loading issues
  static const String freeMapStyle = '''{
    "version": 8,
    "name": "OSM Raster Tiles",
    "sources": {
      "osm": {
        "type": "raster",
        "tiles": [
          "https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png",
          "https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png",
          "https://b.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png"
        ],
        "tileSize": 256,
        "attribution": "&copy; OpenStreetMap contributors"
      }
    },
    "layers": [
      {
        "id": "osm",
        "type": "raster",
        "source": "osm",
        "paint": { "raster-opacity": 1 }
      }
    ]
  }''';

  /// Search places using Google Maps Places Autocomplete API
  Future<List<PlacePrediction>> searchPlaces(String query, {double? proximityLat, double? proximityLng}) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return defaultSalemPlaces;
    }

    final apiKey = AppConfig.googleMapsApiKey;

    // 1. Try Google Maps Places Autocomplete API directly
    if (apiKey.isNotEmpty) {
      try {
        final lat = proximityLat ?? 11.6756;
        final lng = proximityLng ?? 78.1470;
        final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
            '?input=${Uri.encodeComponent(cleanQuery)}'
            '&location=$lat,$lng&radius=30000'
            '&components=country:in'
            '&key=$apiKey';

        final response = await _dio.get(url);
        if (response.statusCode == 200 && response.data is Map) {
          final predictions = response.data['predictions'] as List?;
          if (predictions != null && predictions.isNotEmpty) {
            return predictions.map((p) {
              final structured = p['structured_formatting'] ?? {};
              return PlacePrediction(
                description: p['description'] ?? cleanQuery,
                placeId: p['place_id'] ?? '',
                mainText: structured['main_text'] ?? p['description'] ?? cleanQuery,
                secondaryText: structured['secondary_text'] ?? '',
              );
            }).toList();
          }
        }
      } catch (e) {
        debugPrint('[MapService] Direct Google Places search failed ($e). Trying backend proxy...');
      }

      // 2. Try Backend Proxy to avoid Web CORS
      try {
        final backendUrl = '${AppConfig.apiBaseUrl}/places/autocomplete?input=${Uri.encodeComponent(cleanQuery)}';
        final response = await _dio.get(backendUrl);
        if (response.statusCode == 200 && response.data is Map) {
          final items = response.data['predictions'] as List?;
          if (items != null && items.isNotEmpty) {
            return items.map((p) {
              return PlacePrediction(
                description: p['description'] ?? cleanQuery,
                placeId: p['place_id'] ?? '',
                mainText: p['main_text'] ?? p['description'] ?? cleanQuery,
                secondaryText: p['secondary_text'] ?? '',
              );
            }).toList();
          }
        }
      } catch (_) {}
    }

    // 3. Fallback: filter curated Salem places & local query match
    final lower = cleanQuery.toLowerCase();
    final matched = defaultSalemPlaces.where((p) {
      return p.description.toLowerCase().contains(lower) ||
          p.mainText.toLowerCase().contains(lower);
    }).toList();

    if (matched.isNotEmpty) {
      return matched;
    }

    // Dynamic result for query
    return [
      PlacePrediction(
        description: '$cleanQuery, Salem, Tamil Nadu',
        placeId: 'loc_${cleanQuery.hashCode}',
        mainText: cleanQuery,
        secondaryText: 'Salem, Tamil Nadu',
        latitude: 11.6756,
        longitude: 78.1470,
      ),
      ...defaultSalemPlaces,
    ];
  }

  /// Resolve exact LatLng for a place ID or address using Google Geocoding API
  Future<LatLng?> getPlaceCoordinates(String placeId, String address) async {
    final apiKey = AppConfig.googleMapsApiKey;

    // Check default places first for instant result
    final found = defaultSalemPlaces.firstWhere(
      (p) => p.placeId == placeId || p.description == address,
      orElse: () => PlacePrediction(description: '', placeId: '', mainText: '', secondaryText: ''),
    );
    if (found.latitude != null && found.longitude != null) {
      return LatLng(found.latitude!, found.longitude!);
    }

    if (apiKey.isNotEmpty) {
      // 1. Try Place Details API by placeId
      if (placeId.isNotEmpty && !placeId.startsWith('loc_')) {
        try {
          final url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&fields=geometry&key=$apiKey';
          final response = await _dio.get(url);
          if (response.statusCode == 200 && response.data is Map) {
            final loc = response.data['result']?['geometry']?['location'];
            if (loc != null) {
              return LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
            }
          }
        } catch (_) {}
      }

      // 2. Try Geocode API by address
      try {
        final url = 'https://maps.googleapis.com/maps/api/geocode/json?address=${Uri.encodeComponent(address)}&key=$apiKey';
        final response = await _dio.get(url);
        if (response.statusCode == 200 && response.data is Map) {
          final results = response.data['results'] as List?;
          if (results != null && results.isNotEmpty) {
            final loc = results[0]['geometry']?['location'];
            if (loc != null) {
              return LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble());
            }
          }
        }
      } catch (_) {}

      // 3. Try Backend proxy
      try {
        final backendUrl = '${AppConfig.apiBaseUrl}/places/geocode?address=${Uri.encodeComponent(address)}';
        final response = await _dio.get(backendUrl);
        if (response.statusCode == 200 && response.data is Map) {
          final lat = response.data['latitude'];
          final lng = response.data['longitude'];
          if (lat != null && lng != null) {
            return LatLng((lat as num).toDouble(), (lng as num).toDouble());
          }
        }
      } catch (_) {}
    }

    return const LatLng(11.6756, 78.1470);
  }

  /// Primary Routing: Google Directions API -> OSRM API -> Valhalla -> Haversine
  Future<RouteResult> calculateRoute({
    required LatLng start,
    required LatLng destination,
  }) async {
    final apiKey = AppConfig.googleMapsApiKey;

    // 1. Try Google Maps Directions API if API key is configured
    if (apiKey.isNotEmpty) {
      try {
        final result = await _calculateGoogleDirectionsRoute(start, destination, apiKey);
        debugPrint('[MapService] ✓ Route calculated via Google Directions: ${result.distanceKm} km, ${result.durationMinutes} min');
        return result;
      } catch (gError) {
        debugPrint('[MapService] Google Directions failed ($gError). Falling back to OSRM...');
      }
    }

    // 2. Try OSRM Public Driving Routing API
    try {
      final result = await _calculateOSRMRoute(start, destination);
      debugPrint('[MapService] ✓ Route calculated via OSRM: ${result.distanceKm} km, ${result.durationMinutes} min');
      return result;
    } catch (osrmError) {
      debugPrint('[MapService] OSRM routing failed ($osrmError). Trying Valhalla...');
      try {
        // 3. Fallback to Valhalla
        final result = await _calculateValhallaRoute(start, destination);
        return result;
      } catch (valhallaError) {
        // 4. Fallback to Haversine direct estimate
        return _generateDirectPolyline(start, destination);
      }
    }
  }

  /// Calculates route using Google Maps Directions API
  Future<RouteResult> _calculateGoogleDirectionsRoute(LatLng start, LatLng end, String apiKey) async {
    final origin = '${start.latitude},${start.longitude}';
    final dest = '${end.latitude},${end.longitude}';
    final url = 'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$dest&mode=driving&key=$apiKey';

    final response = await _dio.get(url);
    if (response.statusCode == 200 && response.data is Map) {
      final routes = response.data['routes'] as List?;
      if (routes != null && routes.isNotEmpty) {
        final leg = routes[0]['legs']?[0];
        final distanceMeters = (leg?['distance']?['value'] as num?)?.toDouble() ?? 0.0;
        final durationSeconds = (leg?['duration']?['value'] as num?)?.toDouble() ?? 0.0;
        final overviewPolyline = routes[0]['overview_polyline']?['points'] as String? ?? '';

        final points = overviewPolyline.isNotEmpty
            ? _decodeGooglePolyline(overviewPolyline)
            : [start, end];

        return RouteResult(
          points: points,
          distanceKm: double.parse((distanceMeters / 1000.0).toStringAsFixed(2)),
          durationMinutes: double.parse((durationSeconds / 60.0).toStringAsFixed(1)),
          provider: 'Google Maps',
        );
      }
    }
    throw Exception('Google Directions response not OK');
  }

  /// Decodes Google standard encoded polyline (5 decimals)
  List<LatLng> _decodeGooglePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  /// Calculates route using OSRM Public Routing API
  Future<RouteResult> _calculateOSRMRoute(LatLng start, LatLng end) async {
    final sLng = start.longitude.toStringAsFixed(6);
    final sLat = start.latitude.toStringAsFixed(6);
    final eLng = end.longitude.toStringAsFixed(6);
    final eLat = end.latitude.toStringAsFixed(6);

    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/$sLng,$sLat;$eLng,$eLat?overview=full&geometries=geojson',
    );

    final response = await _dio.getUri(uri);

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data is String ? jsonDecode(response.data) : response.data;
      final routes = data['routes'] as List?;

      if (routes != null && routes.isNotEmpty) {
        final route = routes[0];
        final double distanceMeters = (route['distance'] as num).toDouble();
        final double durationSeconds = (route['duration'] as num).toDouble();
        final geometry = route['geometry'];

        final List<LatLng> points = [];
        if (geometry != null && geometry['coordinates'] != null) {
          final coords = geometry['coordinates'] as List;
          for (var c in coords) {
            final double lng = (c[0] as num).toDouble();
            final double lat = (c[1] as num).toDouble();
            points.add(LatLng(lat, lng));
          }
        }

        return RouteResult(
          points: points.isNotEmpty ? points : [start, end],
          distanceKm: double.parse((distanceMeters / 1000.0).toStringAsFixed(2)),
          durationMinutes: double.parse((durationSeconds / 60.0).toStringAsFixed(1)),
          provider: 'OSRM',
        );
      }
    }

    throw Exception('OSRM route calculation failed');
  }

  /// Calculates route using Valhalla
  Future<RouteResult> _calculateValhallaRoute(LatLng start, LatLng end) async {
    final url = 'https://valhalla1.openstreetmap.de/route';
    final payload = {
      'locations': [
        {'lat': start.latitude, 'lon': start.longitude},
        {'lat': end.latitude, 'lon': end.longitude},
      ],
      'costing': 'auto',
      'units': 'kilometers',
    };

    final response = await _dio.post(
      url,
      data: jsonEncode(payload),
      options: Options(headers: {'Content-Type': 'application/json'}),
    );

    if (response.statusCode == 200 && response.data != null) {
      final data = response.data is String ? jsonDecode(response.data) : response.data;
      final trip = data['trip'];
      final summary = trip['summary'];
      final double distanceKm = (summary['length'] as num).toDouble();
      final double durationMinutes = ((summary['time'] as num) / 60.0).toDouble();

      final List<LatLng> points = [];
      final legs = trip['legs'] as List?;
      if (legs != null && legs.isNotEmpty) {
        for (var leg in legs) {
          final String shape = leg['shape'] ?? '';
          if (shape.isNotEmpty) {
            points.addAll(_decodeValhallaPolyline(shape));
          }
        }
      }

      return RouteResult(
        points: points.isNotEmpty ? points : [start, end],
        distanceKm: double.parse(distanceKm.toStringAsFixed(2)),
        durationMinutes: double.parse(durationMinutes.toStringAsFixed(1)),
        provider: 'Valhalla',
      );
    }

    throw Exception('Valhalla response code: ${response.statusCode}');
  }

  /// Decodes Valhalla's 6-decimal precision polyline format
  List<LatLng> _decodeValhallaPolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1e6, lng / 1e6));
    }
    return poly;
  }

  /// Direct linear interpolation polyline when offline or APIs fail
  RouteResult _generateDirectPolyline(LatLng start, LatLng end) {
    const steps = 10;
    List<LatLng> points = [];
    for (int i = 0; i <= steps; i++) {
      final double fraction = i / steps;
      final double lat = start.latitude + (end.latitude - start.latitude) * fraction;
      final double lng = start.longitude + (end.longitude - start.longitude) * fraction;
      points.add(LatLng(lat, lng));
    }

    final double distanceKm = _calculateHaversineDistance(start, end);
    final double durationMins = (distanceKm / 25.0) * 60.0;

    return RouteResult(
      points: points,
      distanceKm: double.parse(distanceKm.toStringAsFixed(2)),
      durationMinutes: double.parse(durationMins.clamp(1.0, 999.0).toStringAsFixed(1)),
      provider: 'Direct Estimate',
    );
  }

  double _calculateHaversineDistance(LatLng p1, LatLng p2) {
    const double r = 6371.0;
    final double dLat = _degToRad(p2.latitude - p1.latitude);
    final double dLng = _degToRad(p2.longitude - p1.longitude);
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(p1.latitude)) *
            cos(_degToRad(p2.latitude)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final double c = 2 * asin(sqrt(a));
    return r * c;
  }

  double _degToRad(double deg) => deg * (3.141592653589793 / 180.0);
}
