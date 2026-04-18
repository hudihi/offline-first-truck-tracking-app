import 'package:uuid/uuid.dart';

const _uuid = Uuid();

// ─── Sync Status Enum ────────────────────────────────────────────────────────

enum SyncStatus { pending, syncing, synced, failed }

extension SyncStatusX on SyncStatus {
  String get label {
    switch (this) {
      case SyncStatus.pending: return 'PENDING';
      case SyncStatus.syncing: return 'SYNCING';
      case SyncStatus.synced:  return 'SYNCED';
      case SyncStatus.failed:  return 'FAILED';
    }
  }

  static SyncStatus fromString(String s) {
    return SyncStatus.values.firstWhere(
      (e) => e.name == s,
      orElse: () => SyncStatus.pending,
    );
  }
}

// ─── Record Type Enum ────────────────────────────────────────────────────────

enum RecordType { weightReceipt, fuelLog, checkpoint, incident }

extension RecordTypeX on RecordType {
  String get label {
    switch (this) {
      case RecordType.weightReceipt: return 'Weight Receipt';
      case RecordType.fuelLog:       return 'Fuel Log';
      case RecordType.checkpoint:    return 'Checkpoint';
      case RecordType.incident:      return 'Incident Report';
    }
  }

  String get icon {
    switch (this) {
      case RecordType.weightReceipt: return '⚖️';
      case RecordType.fuelLog:       return '⛽';
      case RecordType.checkpoint:    return '✅';
      case RecordType.incident:      return '⚠️';
    }
  }

  static RecordType fromString(String s) {
    return RecordType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => RecordType.weightReceipt,
    );
  }
}

// ─── SyncRecord ──────────────────────────────────────────────────────────────

class SyncRecord {
  final String id;
  final String tripId;
  final RecordType type;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  SyncStatus status;
  DateTime? syncedAt;
  int retryCount;

  SyncRecord({
    String? id,
    required this.tripId,
    required this.type,
    required this.data,
    DateTime? createdAt,
    this.status = SyncStatus.pending,
    this.syncedAt,
    this.retryCount = 0,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'trip_id': tripId,
    'type': type.name,
    'data': data.entries.map((e) => '${e.key}=${e.value}').join('|'),
    'created_at': createdAt.toIso8601String(),
    'status': status.name,
    'synced_at': syncedAt?.toIso8601String(),
    'retry_count': retryCount,
  };

  factory SyncRecord.fromMap(Map<String, dynamic> map) {
    final rawData = map['data'] as String? ?? '';
    final dataMap = <String, dynamic>{};
    if (rawData.isNotEmpty) {
      for (final pair in rawData.split('|')) {
        final idx = pair.indexOf('=');
        if (idx > 0) {
          dataMap[pair.substring(0, idx)] = pair.substring(idx + 1);
        }
      }
    }
    return SyncRecord(
      id: map['id'] as String,
      tripId: map['trip_id'] as String,
      type: RecordTypeX.fromString(map['type'] as String),
      data: dataMap,
      createdAt: DateTime.parse(map['created_at'] as String),
      status: SyncStatusX.fromString(map['status'] as String),
      syncedAt: map['synced_at'] != null ? DateTime.parse(map['synced_at'] as String) : null,
      retryCount: map['retry_count'] as int? ?? 0,
    );
  }

  SyncRecord copyWith({SyncStatus? status, DateTime? syncedAt, int? retryCount}) {
    return SyncRecord(
      id: id,
      tripId: tripId,
      type: type,
      data: data,
      createdAt: createdAt,
      status: status ?? this.status,
      syncedAt: syncedAt ?? this.syncedAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

// ─── TripLog ─────────────────────────────────────────────────────────────────

enum LogEventType {
  tripStarted,
  tripEnded,
  networkLost,
  networkRestored,
  dataSavedOffline,
  dataSynced,
  checkpointReached,
  deadZoneEntered,
  deadZoneExited,
}

extension LogEventTypeX on LogEventType {
  String get label {
    switch (this) {
      case LogEventType.tripStarted:       return 'Trip started';
      case LogEventType.tripEnded:         return 'Trip ended';
      case LogEventType.networkLost:       return 'Network went down';
      case LogEventType.networkRestored:   return 'Signal recovered';
      case LogEventType.dataSavedOffline:  return 'Data saved offline';
      case LogEventType.dataSynced:        return 'Data synced to server';
      case LogEventType.checkpointReached: return 'Checkpoint reached';
      case LogEventType.deadZoneEntered:   return 'Dead zone entered';
      case LogEventType.deadZoneExited:    return 'Dead zone exited';
    }
  }

  String get icon {
    switch (this) {
      case LogEventType.tripStarted:       return '🚛';
      case LogEventType.tripEnded:         return '🏁';
      case LogEventType.networkLost:       return '⚠️';
      case LogEventType.networkRestored:   return '✅';
      case LogEventType.dataSavedOffline:  return '💾';
      case LogEventType.dataSynced:        return '☁️';
      case LogEventType.checkpointReached: return '📍';
      case LogEventType.deadZoneEntered:   return '📵';
      case LogEventType.deadZoneExited:    return '📶';
    }
  }

  static LogEventType fromString(String s) {
    return LogEventType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => LogEventType.tripStarted,
    );
  }
}

class TripLog {
  final String id;
  final String tripId;
  final LogEventType eventType;
  final DateTime timestamp;
  final String detail;
  final double? latitude;
  final double? longitude;

  TripLog({
    String? id,
    required this.tripId,
    required this.eventType,
    DateTime? timestamp,
    required this.detail,
    this.latitude,
    this.longitude,
  })  : id = id ?? _uuid.v4(),
        timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'trip_id': tripId,
    'event_type': eventType.name,
    'timestamp': timestamp.toIso8601String(),
    'detail': detail,
    'latitude': latitude,
    'longitude': longitude,
  };

  factory TripLog.fromMap(Map<String, dynamic> map) => TripLog(
    id: map['id'] as String,
    tripId: map['trip_id'] as String,
    eventType: LogEventTypeX.fromString(map['event_type'] as String),
    timestamp: DateTime.parse(map['timestamp'] as String),
    detail: map['detail'] as String,
    latitude: map['latitude'] as double?,
    longitude: map['longitude'] as double?,
  );
}

// ─── DeadZone ────────────────────────────────────────────────────────────────

class DeadZone {
  final String id;
  final String tripId;
  final double latitude;
  final double longitude;
  final DateTime detectedAt;
  DateTime? recoveredAt;
  String label;

  DeadZone({
    String? id,
    required this.tripId,
    required this.latitude,
    required this.longitude,
    DateTime? detectedAt,
    this.recoveredAt,
    this.label = '',
  })  : id = id ?? _uuid.v4(),
        detectedAt = detectedAt ?? DateTime.now();

  Duration? get duration => recoveredAt != null
      ? recoveredAt!.difference(detectedAt)
      : null;

  Map<String, dynamic> toMap() => {
    'id': id,
    'trip_id': tripId,
    'latitude': latitude,
    'longitude': longitude,
    'detected_at': detectedAt.toIso8601String(),
    'recovered_at': recoveredAt?.toIso8601String(),
    'label': label,
  };

  factory DeadZone.fromMap(Map<String, dynamic> map) => DeadZone(
    id: map['id'] as String,
    tripId: map['trip_id'] as String,
    latitude: map['latitude'] as double,
    longitude: map['longitude'] as double,
    detectedAt: DateTime.parse(map['detected_at'] as String),
    recoveredAt: map['recovered_at'] != null
        ? DateTime.parse(map['recovered_at'] as String)
        : null,
    label: map['label'] as String? ?? '',
  );
}

// ─── Trip ────────────────────────────────────────────────────────────────────

enum TripStatus { active, completed, cancelled }

extension TripStatusX on TripStatus {
  static TripStatus fromString(String s) => TripStatus.values.firstWhere(
    (e) => e.name == s,
    orElse: () => TripStatus.active,
  );
}

class Trip {
  final String id;
  final String driverName;
  final String truckPlate;
  final String origin;
  final String destination;
  final double cargoWeight;
  final DateTime startedAt;
  DateTime? completedAt;
  TripStatus status;

  Trip({
    String? id,
    required this.driverName,
    required this.truckPlate,
    required this.origin,
    required this.destination,
    required this.cargoWeight,
    DateTime? startedAt,
    this.completedAt,
    this.status = TripStatus.active,
  })  : id = id ?? _uuid.v4(),
        startedAt = startedAt ?? DateTime.now();

  Duration get elapsed => (completedAt ?? DateTime.now()).difference(startedAt);

  Map<String, dynamic> toMap() => {
    'id': id,
    'driver_name': driverName,
    'truck_plate': truckPlate,
    'origin': origin,
    'destination': destination,
    'cargo_weight': cargoWeight,
    'started_at': startedAt.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'status': status.name,
  };

  factory Trip.fromMap(Map<String, dynamic> map) => Trip(
    id: map['id'] as String,
    driverName: map['driver_name'] as String,
    truckPlate: map['truck_plate'] as String,
    origin: map['origin'] as String,
    destination: map['destination'] as String,
    cargoWeight: (map['cargo_weight'] as num).toDouble(),
    startedAt: DateTime.parse(map['started_at'] as String),
    completedAt: map['completed_at'] != null
        ? DateTime.parse(map['completed_at'] as String)
        : null,
    status: TripStatusX.fromString(map['status'] as String),
  );
}
