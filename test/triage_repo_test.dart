import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:paramedic_triage/core/data/local_store.dart';
import 'package:paramedic_triage/core/data/mock_api_client.dart';
import 'package:paramedic_triage/core/data/triage_repo.dart';
import 'package:paramedic_triage/core/domain/triage_record.dart';

/// Deterministic API double: fails exactly when the test says so, and
/// counts calls so retry behaviour can be asserted.
class FakeApiClient implements TriageApiClient {
  bool shouldFail = false;
  int calls = 0;
  final List<String> uploadedIds = [];

  /// Fail only the record with this id (for partial-failure tests).
  String? failOnlyId;

  @override
  Future<void> postTriage(TriageRecord record) async {
    calls++;
    if (shouldFail || record.id == failOnlyId) {
      throw APIException('simulated failure');
    }
    uploadedIds.add(record.id);
  }
}

void main() {
  late Directory tempDir;
  late LocalStore store;
  late FakeApiClient api;
  late TriageRepo repository;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('triage_test');
    Hive.init(tempDir.path);
    store = await LocalStore.open();
    api = FakeApiClient();
    repository = TriageRepo(store: store, api: api);
  });

  tearDown(() async {
    await store.close();
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  Future<TriageRecord> submitSample({String name = 'Jane Achieng'}) =>
      repository.submitRecord(
        patientName: name,
        condition: 'Chest pain, shallow breathing',
        priority: 1,
        status: TriageStatus.pending,
      );

  group('offline-first durability', () {
    test('record is persisted locally even when upload fails', () async {
      api.shouldFail = true;

      final record = await submitSample();
      // Let the fire-and-forget upload attempt finish.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final stored = store.getRecord(record.id);
      expect(stored, isNotNull, reason: 'data must never be lost');
      expect(stored!.patientName, 'Jane Achieng');
      expect(stored.syncStatus, SyncStatus.failed,
          reason: 'failed upload keeps the record in the retry queue');
      expect(repository.pendingSyncCount, 1);
    });

    test('record is marked synced when upload succeeds', () async {
      final record = await submitSample();
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(store.getRecord(record.id)!.syncStatus, SyncStatus.synced);
      expect(api.uploadedIds, [record.id]);
      expect(repository.pendingSyncCount, 0);
    });
  });

  group('sync queue drain', () {
    test('syncPending uploads all queued records oldest-first', () async {
      api.shouldFail = true;
      final first = await submitSample(name: 'First Patient');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final second = await submitSample(name: 'Second Patient');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(repository.pendingSyncCount, 2);

      // "Connectivity restored"
      api.shouldFail = false;
      await repository.syncPending();

      expect(repository.pendingSyncCount, 0);
      expect(api.uploadedIds, [first.id, second.id],
          reason: 'server must receive records in capture order');
      expect(store.getRecord(first.id)!.syncStatus, SyncStatus.synced);
      expect(store.getRecord(second.id)!.syncStatus, SyncStatus.synced);
    });

    test('partial failure: unaffected records sync, failed one stays queued',
        () async {
      api.shouldFail = true;
      final ok = await submitSample(name: 'Will Sync');
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final bad = await submitSample(name: 'Will Fail');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      api.shouldFail = false;
      api.failOnlyId = bad.id;
      await repository.syncPending();

      expect(store.getRecord(ok.id)!.syncStatus, SyncStatus.synced);
      expect(store.getRecord(bad.id)!.syncStatus, SyncStatus.failed);
      expect(repository.pendingSyncCount, 1);

      // Next drain (e.g. app resumed) retries and recovers it.
      api.failOnlyId = null;
      await repository.syncPending();
      expect(store.getRecord(bad.id)!.syncStatus, SyncStatus.synced);
      expect(repository.pendingSyncCount, 0);
    });

    test('concurrent drains do not double-upload (isDraining latch)',
        () async {
      api.shouldFail = true;
      final record = await submitSample();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      api.shouldFail = false;
      api.calls = 0;

      // Simulate the Android burst: connectivity event + app resume
      // firing simultaneously.
      await Future.wait([
        repository.syncPending(),
        repository.syncPending(),
        repository.syncPending(),
      ]);

      expect(api.calls, 1,
          reason: 'the latch must collapse overlapping drains into one');
      expect(store.getRecord(record.id)!.syncStatus, SyncStatus.synced);
    });
  });

  group('validation-adjacent model behaviour', () {
    test('input is trimmed and record carries a device-generated id',
        () async {
      final record = await repository.submitRecord(
        patientName: '  Jane Achieng  ',
        condition: '  Fracture  ',
        priority: 3,
        status: TriageStatus.inTransit,
      );

      expect(record.patientName, 'Jane Achieng');
      expect(record.condition, 'Fracture');
      expect(record.id, isNotEmpty);
      expect(record.isCritical, isFalse);
    });
  });
}
