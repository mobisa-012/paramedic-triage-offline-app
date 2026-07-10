import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:paramedic_triage/screens/triage_form_screen/bloc/triage_bloc.dart';
import 'package:paramedic_triage/core/data/local_store.dart';
import 'package:paramedic_triage/core/data/mock_api_client.dart';
import 'package:paramedic_triage/core/data/triage_repo.dart';
import 'package:paramedic_triage/core/domain/triage_record.dart';

void main() {
  late Directory tempDir;
  late LocalStore store;
  late MockAPIClient api;
  late TriageRepo repository;
  late TriageBloc bloc;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('triage_bloc_test');
    Hive.init(tempDir.path);
    store = await LocalStore.open();
    // Zero latency + forced failure = deterministic "offline" behaviour.
    api = MockAPIClient(delay: Duration.zero, randomFailuresRate: 0)
      ..simulateFailure = true;
    repository = TriageRepo(store: store, api: api);
    bloc = TriageBloc(triageRepository: repository, apiClient: api);
  });

  tearDown(() async {
    await bloc.close();
    await store.close();
    await Hive.deleteFromDisk();
    await tempDir.delete(recursive: true);
  });

  test('TriageSubmitted saves the record and surfaces it in state', () async {
    bloc.add(const TriageSubmitted(
      patientName: 'Jane Achieng',
      condition: 'Severe bleeding',
      priority: 1,
      status: TriageStatus.pending,
    ));

    // Wait for the submit + failed upload attempt to settle.
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(bloc.state.records, hasLength(1));
    final record = bloc.state.records.first;
    expect(record.patientName, 'Jane Achieng');
    expect(record.priority, 1);
    expect(bloc.state.pendingCount, 1,
        reason: 'offline submission must sit visibly in the sync queue');
  });

  test('TriageSyncRequested drains the queue once API recovers', () async {
    bloc.add(const TriageSubmitted(
      patientName: 'John Otieno',
      condition: 'Fractured arm',
      priority: 4,
      status: TriageStatus.inTransit,
    ));
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(bloc.state.pendingCount, 1);

    // "Network restored"
    api.simulateFailure = false;
    bloc.add(const TriageSyncRequested());
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(bloc.state.pendingCount, 0);
    expect(bloc.state.records.first.syncStatus, SyncStatus.synced);
  });

  test('FailureSimulationToggled flips the mock API switch', () async {
    api.simulateFailure = false;
    bloc.add(const FailureSimulationToggled(true));
    await Future<void>.delayed(const Duration(milliseconds: 20));

    expect(api.simulateFailure, isTrue);
    expect(bloc.state.simulateFailure, isTrue);
  });
}
