import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import '../config/app_config.dart';
import '../../shared/models/telemetry_model.dart';

// Re-export shared types for backward compatibility
export '../../shared/models/telemetry_model.dart'
    show DriverTelemetry, IncomingRideRequest, RideStatusEvent, RideWebSocketEvent,
        LocationUpdateEvent, StatusChangeEvent, RideAcceptedEvent;

/// WebSocket-based realtime location service connecting to FastAPI backend.
/// Falls back to simulation if WebSocket is unavailable.
class WebSocketLocationService {
  // ─── Ride channel (passenger tracking + driver location push) ────────────
  WebSocketChannel? _rideChannel;
  StreamController<RideWebSocketEvent>? _rideController;
  Timer? _ridePingTimer;
  Timer? _rideReconnectTimer;
  bool _rideConnected = false;
  String? _activeRideId;
  int _rideReconnectAttempts = 0;

  // ─── Drivers channel (driver home — receive ride requests) ────────────────
  WebSocketChannel? _driversChannel;
  StreamController<IncomingRideRequest>? _driversController;
  Timer? _driversPingTimer;
  bool _driversConnected = false;

  // ─── Throttle ─────────────────────────────────────────────────────────────
  static const int maxReconnectAttempts = 5;
  static const int throttleSeconds = 5;
  DateTime? _lastLocationSentTime;

  // ─── Driver identity for this session ────────────────────────────────────
  String? _activeDriverId;

  // ─── WebSocket base URL ───────────────────────────────────────────────────
  String get _wsBaseUrl {
    final apiUrl = AppConfig.apiBaseUrl;
    if (apiUrl.startsWith('https://')) {
      return apiUrl.replaceFirst('https://', 'wss://');
    } else if (apiUrl.startsWith('http://')) {
      return apiUrl.replaceFirst('http://', 'ws://');
    }
    return 'ws://localhost:8000';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RIDE CHANNEL — Passenger subscribes to receive all ride events
  // ═══════════════════════════════════════════════════════════════════════════

  /// Stream all real-time events for an active ride:
  /// - [LocationUpdateEvent] when the driver moves
  /// - [StatusChangeEvent] when ride status changes (ARRIVED, STARTED, COMPLETED)
  /// - [RideAcceptedEvent] when a driver accepts the ride
  Stream<RideWebSocketEvent> streamRideEvents(
    String rideId, {
    String? driverId,
    List<LatLng>? fallbackRoutePoints,
  }) {
    _activeRideId = rideId;
    _activeDriverId = driverId;

    _rideController?.close();
    _rideController = StreamController<RideWebSocketEvent>.broadcast(
      onCancel: () => _disconnectRideChannel(),
    );

    _connectRideChannel(rideId, fallbackRoutePoints: fallbackRoutePoints);
    return _rideController!.stream;
  }

  Future<void> _connectRideChannel(
    String rideId, {
    List<LatLng>? fallbackRoutePoints,
  }) async {
    try {
      final wsUrl = '$_wsBaseUrl/ws/ride/$rideId';
      debugPrint('WebSocketLocationService: Connecting ride channel -> $wsUrl');

      _rideChannel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        connectTimeout: const Duration(seconds: 6),
      );

      _rideConnected = true;
      _rideReconnectAttempts = 0;
      debugPrint('WebSocketLocationService: Ride channel connected for $rideId');

      // Keep-alive ping every 20s
      _ridePingTimer?.cancel();
      _ridePingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
        _sendToRide({'type': 'ping'});
      });

      _rideChannel!.stream.listen(
        (raw) {
          try {
            final data = jsonDecode(raw as String) as Map<String, dynamic>;
            final event = data['event'] as String?;

            if (event == 'driver_location_updated') {
              final loc = data['location'] as Map<String, dynamic>?;
              if (loc != null) {
                final telemetry = DriverTelemetry(
                  driverId: data['driverId'] as String? ?? _activeDriverId ?? 'drv_001',
                  location: LatLng(
                    (loc['latitude'] as num).toDouble(),
                    (loc['longitude'] as num).toDouble(),
                  ),
                  heading: (loc['heading'] as num?)?.toDouble() ?? 0.0,
                  speedKmH: (loc['speed'] as num?)?.toDouble() ?? 20.0,
                  timestamp: DateTime.now(),
                );
                _addRideEvent(LocationUpdateEvent(telemetry));
              }
            } else if (event == 'ride_status_updated') {
              final statusEvent = RideStatusEvent.fromJson(data);
              _addRideEvent(StatusChangeEvent(statusEvent));
            } else if (event == 'ride_accepted') {
              _addRideEvent(RideAcceptedEvent(
                rideId: data['rideId'] as String? ?? rideId,
                driverId: data['driverId'] as String? ?? '',
              ));
            }
            // Ignore pong
          } catch (e) {
            debugPrint('WebSocketLocationService parse error: $e');
          }
        },
        onError: (e) {
          debugPrint('WebSocketLocationService ride channel error: $e');
          _rideConnected = false;
          _scheduleRideReconnect(rideId, fallbackRoutePoints);
        },
        onDone: () {
          debugPrint('WebSocketLocationService: Ride channel closed');
          _rideConnected = false;
          _scheduleRideReconnect(rideId, fallbackRoutePoints);
        },
      );
    } catch (e) {
      debugPrint('WebSocketLocationService: Ride channel failed ($e). Using simulation.');
      _rideConnected = false;
      _startRideSimulation(fallbackRoutePoints);
    }
  }

  void _scheduleRideReconnect(String rideId, List<LatLng>? fallbackRoutePoints) {
    if (_rideReconnectAttempts >= maxReconnectAttempts) {
      debugPrint('WebSocketLocationService: Max reconnect reached. Falling back to simulation.');
      _startRideSimulation(fallbackRoutePoints);
      return;
    }
    _rideReconnectAttempts++;
    final delay = Duration(seconds: 2 * _rideReconnectAttempts);
    debugPrint('WebSocketLocationService: Reconnecting ride in ${delay.inSeconds}s (attempt $_rideReconnectAttempts)');
    _rideReconnectTimer?.cancel();
    _rideReconnectTimer = Timer(delay, () {
      if (!(_rideController?.isClosed ?? true)) {
        _connectRideChannel(rideId, fallbackRoutePoints: fallbackRoutePoints);
      }
    });
  }

  void _startRideSimulation(List<LatLng>? routePoints) {
    final List<LatLng> points = (routePoints != null && routePoints.length >= 2)
        ? routePoints
        : [
            const LatLng(12.9780, 77.5900),
            const LatLng(12.9760, 77.5920),
            const LatLng(12.9740, 77.5935),
            const LatLng(12.9716, 77.5946),
          ];

    int step = 0;
    Timer.periodic(Duration(seconds: throttleSeconds), (timer) {
      if (_rideController?.isClosed ?? true) {
        timer.cancel();
        return;
      }
      final current = points[step % points.length];
      final next = points[(step + 1) % points.length];
      final heading = _calculateBearing(current, next);
      _addRideEvent(LocationUpdateEvent(DriverTelemetry(
        driverId: _activeDriverId ?? 'drv_sim',
        location: current,
        heading: heading,
        speedKmH: 22.0 + (step % 5).toDouble(),
        timestamp: DateTime.now(),
      )));
      step++;
    });
  }

  void _addRideEvent(RideWebSocketEvent event) {
    if (!(_rideController?.isClosed ?? true)) {
      _rideController!.add(event);
    }
  }

  void _sendToRide(Map<String, dynamic> message) {
    try {
      if (_rideConnected && _rideChannel != null) {
        _rideChannel!.sink.add(jsonEncode(message));
      }
    } catch (e) {
      debugPrint('WebSocketLocationService ride send error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DRIVER LOCATION PUSH — Driver sends their location over ride WebSocket
  // ═══════════════════════════════════════════════════════════════════════════

  /// Send driver GPS location to the ride room (throttled).
  /// Call this from the driver tracking screen every few seconds.
  Future<void> sendDriverLocation({
    required String driverId,
    required LatLng location,
    required double heading,
    double speedKmH = 25.0,
    bool forceImmediate = false,
    String? rideId,
  }) async {
    final now = DateTime.now();
    if (!forceImmediate && _lastLocationSentTime != null) {
      if (now.difference(_lastLocationSentTime!).inSeconds < throttleSeconds) return;
    }
    _lastLocationSentTime = now;

    final message = {
      'type': 'location',
      'driverId': driverId,
      'lat': location.latitude,
      'lng': location.longitude,
      'heading': heading,
      'speed': speedKmH,
    };

    if (_rideConnected) {
      _sendToRide(message);
    } else {
      debugPrint('WebSocketLocationService: Cannot push location — ride channel not connected');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // RIDE STATUS SEND — Driver sends status updates (arrived, started, completed)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Send a ride status change via the ride WebSocket.
  /// [status] should be one of: DRIVER_ARRIVING, DRIVER_ARRIVED, TRIP_STARTED, TRIP_COMPLETED
  void sendRideStatus(String status) {
    _sendToRide({'type': 'status', 'status': status});
    debugPrint('WebSocketLocationService: Sent status $status for ride $_activeRideId');
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DRIVER CHANNEL — Driver connects to receive incoming ride requests
  // ═══════════════════════════════════════════════════════════════════════════

  /// Connect to the /ws/drivers channel and stream incoming ride requests.
  /// Call this when driver goes Online.
  Stream<IncomingRideRequest> connectToDriverChannel(String driverId) {
    _activeDriverId = driverId;

    _driversController?.close();
    _driversController = StreamController<IncomingRideRequest>.broadcast(
      onCancel: () => _disconnectDriversChannel(),
    );

    _connectDriversChannel(driverId);
    return _driversController!.stream;
  }

  Future<void> _connectDriversChannel(String driverId) async {
    try {
      final wsUrl = '$_wsBaseUrl/ws/drivers';
      debugPrint('WebSocketLocationService: Connecting drivers channel -> $wsUrl');

      _driversChannel = IOWebSocketChannel.connect(
        Uri.parse(wsUrl),
        connectTimeout: const Duration(seconds: 6),
      );

      _driversConnected = true;
      debugPrint('WebSocketLocationService: Drivers channel connected for $driverId');

      // Keep-alive ping every 25s
      _driversPingTimer?.cancel();
      _driversPingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        _sendToDrivers({'type': 'ping'});
      });

      _driversChannel!.stream.listen(
        (raw) {
          try {
            final data = jsonDecode(raw as String) as Map<String, dynamic>;
            final event = data['event'] as String?;

            if (event == 'new_ride_request') {
              final request = IncomingRideRequest.fromJson(data);
              if (!(_driversController?.isClosed ?? true)) {
                _driversController!.add(request);
              }
            }
            // Ignore pong
          } catch (e) {
            debugPrint('WebSocketLocationService drivers parse error: $e');
          }
        },
        onError: (e) {
          debugPrint('WebSocketLocationService drivers channel error: $e');
          _driversConnected = false;
          // Retry after 5s
          Timer(const Duration(seconds: 5), () {
            if (!(_driversController?.isClosed ?? true)) {
              _connectDriversChannel(driverId);
            }
          });
        },
        onDone: () {
          debugPrint('WebSocketLocationService: Drivers channel closed');
          _driversConnected = false;
        },
      );
    } catch (e) {
      debugPrint('WebSocketLocationService: Drivers channel failed ($e)');
      _driversConnected = false;
    }
  }

  /// Accept an incoming ride request (sends event to backend)
  void acceptRide({required String rideId, required String driverId}) {
    _sendToDrivers({
      'type': 'accept_ride',
      'rideId': rideId,
      'driverId': driverId,
    });
    debugPrint('WebSocketLocationService: Accepted ride $rideId as driver $driverId');
  }

  void _sendToDrivers(Map<String, dynamic> message) {
    try {
      if (_driversConnected && _driversChannel != null) {
        _driversChannel!.sink.add(jsonEncode(message));
      }
    } catch (e) {
      debugPrint('WebSocketLocationService drivers send error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LEGACY COMPAT — streamDriverLocation for backward compatibility
  // ═══════════════════════════════════════════════════════════════════════════

  /// Backward-compatible method: stream just driver location telemetry
  Stream<DriverTelemetry> streamDriverLocation(
    String driverId, {
    String? rideId,
    List<LatLng>? fallbackRoutePoints,
  }) {
    // Delegate to streamRideEvents and filter LocationUpdateEvents
    return streamRideEvents(
      rideId ?? 'ride_sim',
      driverId: driverId,
      fallbackRoutePoints: fallbackRoutePoints,
    ).where((e) => e is LocationUpdateEvent).map((e) => (e as LocationUpdateEvent).telemetry);
  }

  /// Backward-compatible method: send location update
  Future<void> updateDriverLocation({
    required String driverId,
    required LatLng location,
    required double heading,
    double speedKmH = 25.0,
    bool forceImmediate = false,
    String? rideId,
  }) async {
    await sendDriverLocation(
      driverId: driverId,
      location: location,
      heading: heading,
      speedKmH: speedKmH,
      forceImmediate: forceImmediate,
      rideId: rideId,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CLEANUP
  // ═══════════════════════════════════════════════════════════════════════════

  void _disconnectRideChannel() {
    _ridePingTimer?.cancel();
    _rideReconnectTimer?.cancel();
    try {
      _rideChannel?.sink.close();
    } catch (_) {}
    _rideConnected = false;
    _activeRideId = null;
  }

  void _disconnectDriversChannel() {
    _driversPingTimer?.cancel();
    try {
      _driversChannel?.sink.close();
    } catch (_) {}
    _driversConnected = false;
  }

  void dispose() {
    _rideController?.close();
    _driversController?.close();
    _disconnectRideChannel();
    _disconnectDriversChannel();
  }

  // ─── Geometry helpers ──────────────────────────────────────────────────────

  double _calculateBearing(LatLng start, LatLng end) {
    final startLat = _degToRad(start.latitude);
    final startLng = _degToRad(start.longitude);
    final endLat = _degToRad(end.latitude);
    final endLng = _degToRad(end.longitude);
    final dLng = endLng - startLng;
    final y = sin(dLng) * cos(endLat);
    final x = cos(startLat) * sin(endLat) - sin(startLat) * cos(endLat) * cos(dLng);
    double bearing = atan2(y, x) * (180 / pi);
    return (bearing + 360) % 360;
  }

  double _degToRad(double deg) => deg * (pi / 180.0);
}

// Global singleton for convenience
final websocketLocationService = WebSocketLocationService();
