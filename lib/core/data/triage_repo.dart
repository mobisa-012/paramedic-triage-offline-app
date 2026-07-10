import 'package:uuid/uuid.dart';
import 'package:paramedic_triage/core/data/mock_api_client.dart';
import 'package:paramedic_triage/core/data/local_store.dart';
import 'package:paramedic_triage/core/domain/triage_record.dart';

class TriageRepo {
  final LocalStore store;
  final TriageApiClient api;
  final Uuid uuid;
  bool draining = false;

  TriageRepo({
    required this.store,
    required this.api,
    Uuid? uuid,
  }) : uuid = uuid ?? const Uuid();

  List<TriageRecord> getAllRecords() => store.getAllRecords();

  int get pendingSyncCount => store.pendingSync().length;

  Stream<void> watchRecords() => store.watch();

  Future<TriageRecord> submitRecord({
    required String patientName,
    required String condition,
    required int priority,
    required TriageStatus status,
  }) async {
    final record = TriageRecord(
      id: uuid.v4(),
      patientName: patientName,
      condition: condition,
      priority: priority,
      status: status,
      createdAt: DateTime.now(),
      syncStatus: SyncStatus.queued,
    );

    await store.saveRecord(record);
    uploadOne(record);
    return record;
  }

  Future<void> syncPending() async {
    if (draining) return;
    draining = true;
    try {
      for (final record in store.pendingSync()) {
        await uploadOne(record);
      }
    } finally {
      draining = false;
    }
  }

  Future<void> uploadOne(TriageRecord record) async {
    await store.saveRecord(record.copyWith(syncStatus: SyncStatus.syncing));
    try {
      await api.postTriage(record);
      await store.saveRecord(record.copyWith(syncStatus: SyncStatus.synced));
    } catch (_) {
      await store.saveRecord(record.copyWith(syncStatus: SyncStatus.failed));
    }
  }
}