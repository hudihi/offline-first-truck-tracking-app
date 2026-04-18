import 'dart:async';
import 'package:dio/dio.dart';
import '../models/models.dart';
import 'database_service.dart';
import 'connectivity_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final _db = DatabaseService();
  final _connectivity = ConnectivityService();

  // Replace with your real API base URL
  static const String _baseUrl = 'https://api.kagoafrica.com/v1';
  static const int _maxRetries = 3;

  late final Dio _dio;
  StreamSubscription? _connectivitySub;

  final _syncResultController = StreamController<SyncResult>.broadcast();
  Stream<SyncResult> get syncResults => _syncResultController.stream;

  bool _isSyncing = false;

  void init() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'Content-Type': 'application/json',
        'X-App-Version': '1.0.0',
      },
    ));

    // Add retry interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (err, handler) async {
        if (err.type == DioExceptionType.connectionTimeout ||
            err.type == DioExceptionType.receiveTimeout) {
          handler.reject(err);
          return;
        }
        handler.next(err);
      },
    ));

    // Auto-sync when connectivity returns
    _connectivitySub = _connectivity.statusStream.listen((isOnline) {
      if (isOnline) {
        Future.delayed(const Duration(seconds: 2), () => syncPendingRecords());
      }
    });
  }

  /// Upload all pending records to the server
  Future<void> syncPendingRecords() async {
    if (_isSyncing) return;
    if (!_connectivity.isOnline) return;

    _isSyncing = true;
    final pending = await _db.getPendingRecords();

    if (pending.isEmpty) {
      _isSyncing = false;
      return;
    }

    int synced = 0;
    int failed = 0;

    for (final record in pending) {
      if (record.retryCount >= _maxRetries) continue;

      try {
        await _uploadRecord(record);
        await _db.updateRecordStatus(record.id, SyncStatus.synced, syncedAt: DateTime.now());

        // Log the sync event
        await _db.insertTripLog(TripLog(
          tripId: record.tripId,
          eventType: LogEventType.dataSynced,
          detail: '${record.type.label} synced to server',
        ));

        synced++;
      } catch (e) {
        await _db.incrementRetry(record.id);
        if (record.retryCount + 1 >= _maxRetries) {
          await _db.updateRecordStatus(record.id, SyncStatus.failed);
        }
        failed++;
      }
    }

    _syncResultController.add(SyncResult(synced: synced, failed: failed));
    _isSyncing = false;
  }

  Future<void> _uploadRecord(SyncRecord record) async {
    final endpoint = _endpointFor(record.type);

    // In a real app this hits the API; here we simulate a successful upload
    // after a small delay so demo mode works without a backend.
    await Future.delayed(const Duration(milliseconds: 600));

    // Uncomment below when you have a real backend:
    // await _dio.post(endpoint, data: {
    //   'id': record.id,
    //   'trip_id': record.tripId,
    //   'type': record.type.name,
    //   'data': record.data,
    //   'created_at': record.createdAt.toIso8601String(),
    // });
    _ = endpoint; // silence unused variable warning in demo mode
  }

  String _endpointFor(RecordType type) {
    switch (type) {
      case RecordType.weightReceipt: return '/trips/weight-receipts';
      case RecordType.fuelLog:       return '/trips/fuel-logs';
      case RecordType.checkpoint:    return '/trips/checkpoints';
      case RecordType.incident:      return '/trips/incidents';
    }
  }

  /// Save a record locally (used when offline or as a safe fallback)
  Future<SyncRecord> saveRecord({
    required String tripId,
    required RecordType type,
    required Map<String, dynamic> data,
  }) async {
    final record = SyncRecord(tripId: tripId, type: type, data: data);
    await _db.insertSyncRecord(record);

    // Log the save
    await _db.insertTripLog(TripLog(
      tripId: tripId,
      eventType: LogEventType.dataSavedOffline,
      detail: '${type.label} saved locally · pending sync',
    ));

    // If online, try to sync immediately
    if (_connectivity.isOnline) {
      try {
        await _uploadRecord(record);
        await _db.updateRecordStatus(record.id, SyncStatus.synced, syncedAt: DateTime.now());
        await _db.insertTripLog(TripLog(
          tripId: tripId,
          eventType: LogEventType.dataSynced,
          detail: '${type.label} synced immediately',
        ));
        return record.copyWith(status: SyncStatus.synced, syncedAt: DateTime.now());
      } catch (_) {
        // Fall through — will sync via background service
      }
    }

    return record;
  }

  void dispose() {
    _connectivitySub?.cancel();
    _syncResultController.close();
  }
}

class SyncResult {
  final int synced;
  final int failed;
  const SyncResult({required this.synced, required this.failed});
}
