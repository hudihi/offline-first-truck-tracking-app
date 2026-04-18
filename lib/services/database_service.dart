import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'kago_africa.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trips (
        id TEXT PRIMARY KEY,
        driver_name TEXT NOT NULL,
        truck_plate TEXT NOT NULL,
        origin TEXT NOT NULL,
        destination TEXT NOT NULL,
        cargo_weight REAL NOT NULL,
        started_at TEXT NOT NULL,
        completed_at TEXT,
        status TEXT NOT NULL DEFAULT 'active'
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_records (
        id TEXT PRIMARY KEY,
        trip_id TEXT NOT NULL,
        type TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'pending',
        synced_at TEXT,
        retry_count INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY (trip_id) REFERENCES trips(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE trip_logs (
        id TEXT PRIMARY KEY,
        trip_id TEXT NOT NULL,
        event_type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        detail TEXT NOT NULL,
        latitude REAL,
        longitude REAL,
        FOREIGN KEY (trip_id) REFERENCES trips(id)
      )
    ''');

    await db.execute('''
      CREATE TABLE dead_zones (
        id TEXT PRIMARY KEY,
        trip_id TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        detected_at TEXT NOT NULL,
        recovered_at TEXT,
        label TEXT DEFAULT '',
        FOREIGN KEY (trip_id) REFERENCES trips(id)
      )
    ''');

    // Seed demo trip
    await _seedDemoData(db);
  }

  Future<void> _seedDemoData(Database db) async {
    final tripId = 'TRP-2847';

    await db.insert('trips', {
      'id': tripId,
      'driver_name': 'Juma Mwangi',
      'truck_plate': 'KT-349Z',
      'origin': 'Dar es Salaam',
      'destination': 'Mbeya',
      'cargo_weight': 23.4,
      'started_at': DateTime.now().subtract(const Duration(hours: 6, minutes: 20)).toIso8601String(),
      'status': 'active',
    });

    final logs = [
      {
        'id': 'log-001',
        'trip_id': tripId,
        'event_type': 'tripStarted',
        'timestamp': DateTime.now().subtract(const Duration(hours: 6, minutes: 20)).toIso8601String(),
        'detail': 'Dar es Salaam Depot · Driver: Juma Mwangi · Truck KT-349Z',
        'latitude': -6.7924,
        'longitude': 39.2083,
      },
      {
        'id': 'log-002',
        'trip_id': tripId,
        'event_type': 'checkpointReached',
        'timestamp': DateTime.now().subtract(const Duration(hours: 5, minutes: 20)).toIso8601String(),
        'detail': 'Mikumi Gate · synced to server · 23.4T cargo verified',
        'latitude': -7.2374,
        'longitude': 36.9872,
      },
      {
        'id': 'log-003',
        'trip_id': tripId,
        'event_type': 'dataSavedOffline',
        'timestamp': DateTime.now().subtract(const Duration(hours: 4, minutes: 6)).toIso8601String(),
        'detail': 'Chalinze Weighbridge · connection lost · stored locally',
        'latitude': -6.5781,
        'longitude': 38.1234,
      },
      {
        'id': 'log-004',
        'trip_id': tripId,
        'event_type': 'networkLost',
        'timestamp': DateTime.now().subtract(const Duration(hours: 3, minutes: 58)).toIso8601String(),
        'detail': 'DZ-01 · 32 km east of Chalinze · GSM dropped',
        'latitude': -6.5781,
        'longitude': 38.1234,
      },
      {
        'id': 'log-005',
        'trip_id': tripId,
        'event_type': 'networkRestored',
        'timestamp': DateTime.now().subtract(const Duration(hours: 3, minutes: 41)).toIso8601String(),
        'detail': '17 min offline · 4G signal at -68 dBm',
        'latitude': -6.6012,
        'longitude': 38.2134,
      },
      {
        'id': 'log-006',
        'trip_id': tripId,
        'event_type': 'dataSynced',
        'timestamp': DateTime.now().subtract(const Duration(hours: 3, minutes: 41)).toIso8601String(),
        'detail': '1 weight receipt uploaded · server confirmed',
        'latitude': -6.6012,
        'longitude': 38.2134,
      },
      {
        'id': 'log-007',
        'trip_id': tripId,
        'event_type': 'dataSavedOffline',
        'timestamp': DateTime.now().subtract(const Duration(hours: 1, minutes: 35)).toIso8601String(),
        'detail': 'Morogoro Stop · 120L diesel · no signal',
        'latitude': -6.8235,
        'longitude': 37.6605,
      },
      {
        'id': 'log-008',
        'trip_id': tripId,
        'event_type': 'networkLost',
        'timestamp': DateTime.now().subtract(const Duration(hours: 0, minutes: 15)).toIso8601String(),
        'detail': 'DZ-02 · Mikumi Hills · no cellular coverage',
        'latitude': -7.3891,
        'longitude': 36.7823,
      },
      {
        'id': 'log-009',
        'trip_id': tripId,
        'event_type': 'networkRestored',
        'timestamp': DateTime.now().subtract(const Duration(hours: 0, minutes: 14)).toIso8601String(),
        'detail': '1 min outage · Safaricom 4G',
        'latitude': -7.3891,
        'longitude': 36.7823,
      },
    ];

    for (final log in logs) {
      await db.insert('trip_logs', log);
    }

    // Pending sync records
    await db.insert('sync_records', {
      'id': 'rec-001',
      'trip_id': tripId,
      'type': 'weightReceipt',
      'data': 'cargoType=Agricultural produce|grossWeight=23.4|tareWeight=8.2|station=Chalinze Weighbridge',
      'created_at': DateTime.now().subtract(const Duration(hours: 4, minutes: 6)).toIso8601String(),
      'status': 'pending',
      'retry_count': 0,
    });

    await db.insert('sync_records', {
      'id': 'rec-002',
      'trip_id': tripId,
      'type': 'fuelLog',
      'data': 'liters=120|station=Morogoro Stop|cost=180000',
      'created_at': DateTime.now().subtract(const Duration(hours: 1, minutes: 35)).toIso8601String(),
      'status': 'pending',
      'retry_count': 0,
    });

    await db.insert('sync_records', {
      'id': 'rec-003',
      'trip_id': tripId,
      'type': 'checkpoint',
      'data': 'gate=Mikumi Gate|weight=23.4|officerName=Hassan Kimaro',
      'created_at': DateTime.now().subtract(const Duration(hours: 5, minutes: 20)).toIso8601String(),
      'status': 'synced',
      'synced_at': DateTime.now().subtract(const Duration(hours: 5, minutes: 19)).toIso8601String(),
      'retry_count': 0,
    });

    // Dead zones
    await db.insert('dead_zones', {
      'id': 'dz-001',
      'trip_id': tripId,
      'latitude': -6.5781,
      'longitude': 38.1234,
      'detected_at': DateTime.now().subtract(const Duration(hours: 3, minutes: 58)).toIso8601String(),
      'recovered_at': DateTime.now().subtract(const Duration(hours: 3, minutes: 41)).toIso8601String(),
      'label': 'DZ-01',
    });

    await db.insert('dead_zones', {
      'id': 'dz-002',
      'trip_id': tripId,
      'latitude': -7.3891,
      'longitude': 36.7823,
      'detected_at': DateTime.now().subtract(const Duration(hours: 0, minutes: 15)).toIso8601String(),
      'recovered_at': DateTime.now().subtract(const Duration(hours: 0, minutes: 14)).toIso8601String(),
      'label': 'DZ-02',
    });
  }

  // ── Trips ──────────────────────────────────────────────────────────────────

  Future<Trip?> getActiveTrip() async {
    final db = await database;
    final maps = await db.query('trips', where: 'status = ?', whereArgs: ['active'], limit: 1);
    if (maps.isEmpty) return null;
    return Trip.fromMap(maps.first);
  }

  Future<String> insertTrip(Trip trip) async {
    final db = await database;
    await db.insert('trips', trip.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return trip.id;
  }

  Future<void> updateTripStatus(String id, TripStatus status) async {
    final db = await database;
    await db.update('trips', {'status': status.name}, where: 'id = ?', whereArgs: [id]);
  }

  // ── Sync Records ───────────────────────────────────────────────────────────

  Future<String> insertSyncRecord(SyncRecord record) async {
    final db = await database;
    await db.insert('sync_records', record.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    return record.id;
  }

  Future<List<SyncRecord>> getPendingRecords() async {
    final db = await database;
    final maps = await db.query(
      'sync_records',
      where: 'status IN (?, ?)',
      whereArgs: ['pending', 'failed'],
      orderBy: 'created_at ASC',
    );
    return maps.map(SyncRecord.fromMap).toList();
  }

  Future<List<SyncRecord>> getRecordsForTrip(String tripId) async {
    final db = await database;
    final maps = await db.query(
      'sync_records',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'created_at DESC',
    );
    return maps.map(SyncRecord.fromMap).toList();
  }

  Future<void> updateRecordStatus(String id, SyncStatus status, {DateTime? syncedAt}) async {
    final db = await database;
    await db.update(
      'sync_records',
      {
        'status': status.name,
        if (syncedAt != null) 'synced_at': syncedAt.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> incrementRetry(String id) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE sync_records SET retry_count = retry_count + 1 WHERE id = ?',
      [id],
    );
  }

  Future<int> getPendingCount() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as count FROM sync_records WHERE status IN ('pending', 'failed')",
    );
    return result.first['count'] as int;
  }

  // ── Trip Logs ──────────────────────────────────────────────────────────────

  Future<void> insertTripLog(TripLog log) async {
    final db = await database;
    await db.insert('trip_logs', log.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<TripLog>> getLogsForTrip(String tripId) async {
    final db = await database;
    final maps = await db.query(
      'trip_logs',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'timestamp ASC',
    );
    return maps.map(TripLog.fromMap).toList();
  }

  // ── Dead Zones ─────────────────────────────────────────────────────────────

  Future<void> insertDeadZone(DeadZone zone) async {
    final db = await database;
    await db.insert('dead_zones', zone.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> closeDeadZone(String id, DateTime recoveredAt) async {
    final db = await database;
    await db.update(
      'dead_zones',
      {'recovered_at': recoveredAt.toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<DeadZone>> getDeadZonesForTrip(String tripId) async {
    final db = await database;
    final maps = await db.query(
      'dead_zones',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'detected_at ASC',
    );
    return maps.map(DeadZone.fromMap).toList();
  }

  Future<List<DeadZone>> getAllDeadZones() async {
    final db = await database;
    final maps = await db.query('dead_zones', orderBy: 'detected_at DESC');
    return maps.map(DeadZone.fromMap).toList();
  }
}
