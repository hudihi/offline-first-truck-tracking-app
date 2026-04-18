import 'package:flutter_test/flutter_test.dart';
import 'package:kago_africa/models/models.dart';

void main() {
  group('SyncRecord', () {
    test('serialises and deserialises correctly', () {
      final record = SyncRecord(
        tripId: 'TRP-001',
        type: RecordType.weightReceipt,
        data: {'grossWeight': '23.4', 'station': 'Chalinze'},
      );

      final map = record.toMap();
      final restored = SyncRecord.fromMap(map);

      expect(restored.id, record.id);
      expect(restored.tripId, 'TRP-001');
      expect(restored.type, RecordType.weightReceipt);
      expect(restored.data['grossWeight'], '23.4');
      expect(restored.status, SyncStatus.pending);
    });

    test('copyWith updates status correctly', () {
      final record = SyncRecord(
        tripId: 'TRP-001',
        type: RecordType.fuelLog,
        data: {'liters': '120'},
      );
      final synced = record.copyWith(
        status: SyncStatus.synced,
        syncedAt: DateTime(2024, 1, 15, 9, 0),
      );

      expect(synced.status, SyncStatus.synced);
      expect(synced.syncedAt, DateTime(2024, 1, 15, 9, 0));
      expect(synced.id, record.id); // unchanged
    });
  });

  group('TripLog', () {
    test('serialises and deserialises correctly', () {
      final log = TripLog(
        tripId: 'TRP-001',
        eventType: LogEventType.networkLost,
        detail: 'GSM dropped',
        latitude: -6.78,
        longitude: 39.21,
      );

      final map = log.toMap();
      final restored = TripLog.fromMap(map);

      expect(restored.eventType, LogEventType.networkLost);
      expect(restored.detail, 'GSM dropped');
      expect(restored.latitude, -6.78);
    });
  });

  group('DeadZone', () {
    test('duration is null when not recovered', () {
      final zone = DeadZone(
        tripId: 'TRP-001',
        latitude: -6.5,
        longitude: 38.1,
      );
      expect(zone.duration, isNull);
    });

    test('duration is calculated when recovered', () {
      final detected = DateTime(2024, 1, 15, 8, 22);
      final recovered = DateTime(2024, 1, 15, 8, 39);
      final zone = DeadZone(
        tripId: 'TRP-001',
        latitude: -6.5,
        longitude: 38.1,
        detectedAt: detected,
        recoveredAt: recovered,
      );
      expect(zone.duration!.inMinutes, 17);
    });
  });

  group('Trip', () {
    test('elapsed time is calculated correctly', () {
      final started = DateTime.now().subtract(const Duration(hours: 2, minutes: 30));
      final trip = Trip(
        driverName: 'Juma Mwangi',
        truckPlate: 'KT-349Z',
        origin: 'Dar es Salaam',
        destination: 'Mbeya',
        cargoWeight: 23.4,
        startedAt: started,
      );

      expect(trip.elapsed.inMinutes, greaterThanOrEqualTo(150));
    });
  });
}
