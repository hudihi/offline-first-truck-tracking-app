import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/models.dart';
import 'database_service.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final _connectivity = Connectivity();
  final _db = DatabaseService();

  final _statusController = StreamController<bool>.broadcast();
  Stream<bool> get statusStream => _statusController.stream;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  StreamSubscription? _subscription;
  DateTime? _offlineSince;
  String? _activeDeadZoneId;

  /// Call once from main.dart
  Future<void> init() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = _isConnected(result);

    _subscription = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
  }

  bool _isConnected(List<ConnectivityResult> results) {
    return results.any((r) =>
      r == ConnectivityResult.wifi ||
      r == ConnectivityResult.mobile ||
      r == ConnectivityResult.ethernet,
    );
  }

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    final online = _isConnected(results);
    if (online == _isOnline) return;

    _isOnline = online;
    _statusController.add(online);

    final trip = await _db.getActiveTrip();
    if (trip == null) return;

    if (!online) {
      // Network lost
      _offlineSince = DateTime.now();

      final zone = DeadZone(
        tripId: trip.id,
        latitude: -6.7924, // In production: use geolocator
        longitude: 39.2083,
        label: 'DZ-${DateTime.now().millisecondsSinceEpoch}',
      );
      await _db.insertDeadZone(zone);
      _activeDeadZoneId = zone.id;

      await _db.insertTripLog(TripLog(
        tripId: trip.id,
        eventType: LogEventType.networkLost,
        detail: 'Network connection lost · offline mode activated',
      ));
    } else {
      // Network restored
      final offlineDuration = _offlineSince != null
          ? DateTime.now().difference(_offlineSince!)
          : const Duration();

      if (_activeDeadZoneId != null) {
        await _db.closeDeadZone(_activeDeadZoneId!, DateTime.now());
        _activeDeadZoneId = null;
      }

      final minutes = offlineDuration.inMinutes;
      final seconds = offlineDuration.inSeconds % 60;
      final durationStr = minutes > 0
          ? '${minutes}m ${seconds}s offline'
          : '${seconds}s offline';

      await _db.insertTripLog(TripLog(
        tripId: trip.id,
        eventType: LogEventType.networkRestored,
        detail: 'Signal recovered · $durationStr',
      ));
      _offlineSince = null;
    }
  }

  Future<bool> checkConnectivity() async {
    final result = await _connectivity.checkConnectivity();
    return _isConnected(result);
  }

  void dispose() {
    _subscription?.cancel();
    _statusController.close();
  }
}
