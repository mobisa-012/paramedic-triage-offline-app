import 'package:hive/hive.dart';
import 'package:paramedic_triage/core/domain/triage_record.dart';

class LocalStore {
  LocalStore(this._box);

  static const boxName = "triage_records";
  final Box<TriageRecord> _box;

  static Future<LocalStore> open() async {
    if(!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TriageRecordAdapter());
    }
    final box = await Hive.openBox<TriageRecord>(boxName);
    return LocalStore(box);
  }

  Future<void> saveRecord(TriageRecord record) => _box.put(record.id, record);

  TriageRecord? getRecord(String id) => _box.get(id);

  List<TriageRecord> getAllRecords() {
    final records = _box.values.toList()
      ..sort((a,b) =>b.createdAt.compareTo(a.createdAt));
    return records;
  }

  List<TriageRecord>pendingSync() {
    final pending = _box.values
      .where((r) => 
        r.syncStatus == SyncStatus.queued ||
        r.syncStatus == SyncStatus.failed).toList()
      ..sort((a,b) =>b.createdAt.compareTo(a.createdAt));
    return pending;
  }

  Stream<void> watch() => _box.watch();

  Future<void> close() => _box.close();

}