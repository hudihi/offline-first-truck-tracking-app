import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/database_service.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';

class AppProvider extends ChangeNotifier {
  final _db = DatabaseService();
  final _connectivity = ConnectivityService();
  final _sync = SyncService();

  // ── State ────────────────────────────────────────────────────────────────

  Trip? _activeTrip;
  Trip? get activeTrip => _activeTrip;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  List<SyncRecord> _syncRecords = [];
  List<SyncRecord> get syncRecords => _syncRecords;

  List<SyncRecord> get pendingRecords =>
      _syncRecords.where((r) => r.status == SyncStatus.pending || r.status == SyncStatus.failed).toList();

  List<TripLog> _tripLogs = [];
  List<TripLog> get tripLogs => _tripLogs;

  List<DeadZone> _deadZones = [];
  List<DeadZone> get deadZones => _deadZones;

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  String? _lastSyncError;
  String? get lastSyncError => _lastSyncError;

  StreamSubscription? _connectivitySub;
  StreamSubscription? _syncResultSub;

  // ── Init ─────────────────────────────────────────────────────────────────

  Future<void> init() async {
    await _connectivity.init();
    _sync.init();

    _isOnline = await _connectivity.checkConnectivity();
    _activeTrip = await _db.getActiveTrip();

    if (_activeTrip != null) {
      await _refreshAll();
    }

    _connectivitySub = _connectivity.statusStream.listen((online) {
      _isOnline = online;
      notifyListeners();
      if (online) {
        Future.delayed(const Duration(seconds: 1), () async {
          await _refreshAll();
          notifyListeners();
        });
      }
    });

    _syncResultSub = _sync.syncResults.listen((_) async {
      await _refreshAll();
      notifyListeners();
    });
  }

  Future<void> _refreshAll() async {
    if (_activeTrip == null) return;
    final id = _activeTrip!.id;
    _syncRecords = await _db.getRecordsForTrip(id);
    _tripLogs   = await _db.getLogsForTrip(id);
    _deadZones  = await _db.getDeadZonesForTrip(id);
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  /// Save a new data record (weight receipt, fuel log, etc.)
  Future<SyncRecord> saveRecord({
    required RecordType type,
    required Map<String, dynamic> data,
  }) async {
    final tripId = _activeTrip?.id ?? 'unknown';
    final record = await _sync.saveRecord(tripId: tripId, type: type, data: data);
    await _refreshAll();
    notifyListeners();
    return record;
  }

  /// Manually trigger a sync of all pending records
  Future<void> triggerSync() async {
    if (!_isOnline) return;
    _isSyncing = true;
    _lastSyncError = null;
    notifyListeners();

    try {
      await _sync.syncPendingRecords();
    } catch (e) {
      _lastSyncError = e.toString();
    } finally {
      _isSyncing = false;
      await _refreshAll();
      notifyListeners();
    }
  }

  Duration get tripElapsed =>
      _activeTrip != null ? DateTime.now().difference(_activeTrip!.startedAt) : Duration.zero;

  int get totalDeadZoneMinutes => _deadZones.fold(
    0,
    (sum, dz) => sum + (dz.duration?.inMinutes ?? 0),
  );

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _syncResultSub?.cancel();
    _connectivity.dispose();
    _sync.dispose();
    super.dispose();
  }
}
