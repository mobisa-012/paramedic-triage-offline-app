import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paramedic_triage/core/data/triage_repo.dart';
import 'package:paramedic_triage/core/data/mock_api_client.dart';
import 'package:paramedic_triage/core/domain/triage_record.dart';

part 'triage_state.dart';
part 'triage_event.dart';

class TriageBloc extends Bloc<TriageEvent, TriageState> {
  final TriageRepo repo;
  final MockAPIClient mockApiClient;
  late final StreamSubscription<void> storeSubscription;

  TriageBloc({
    required TriageRepo triageRepository,
    required MockAPIClient apiClient,
  }) : repo = triageRepository,
        mockApiClient = apiClient,
        super(const TriageState()) {
    on<TriageSubmitted>(onSubmitted);
    on<TriageStoreChanged>(onStoreChanged);
    on<TriageSyncRequested>(onSyncRequested);
    on<FailureSimulationToggled>(onFailureToggled);
    on<TriageDeleted>(onDeleted);
    on<TriageRestored>(onRestored);

    storeSubscription = repo
        .watchRecords()
        .listen((_) => add(const TriageStoreChanged()));

    add(const TriageStoreChanged());
  }

  Future<void> onSubmitted(
    TriageSubmitted event,
    Emitter<TriageState> emit,
  ) async {
    final record = await repo.submitRecord(
      patientName: event.patientName,
      condition: event.condition,
      priority: event.priority,
      status: event.status,
    );

    emit(state.copyWith(
      records: repo.getAllRecords(),
      pendingCount: repo.pendingSyncCount,
      lastSavedId: record.id,
    ));
  }

  void onStoreChanged(TriageStoreChanged event, Emitter<TriageState> emit) {
    emit(state.copyWith(
      records: repo.getAllRecords(),
      pendingCount: repo.pendingSyncCount,
    ));
  }

  Future<void> onSyncRequested(
    TriageSyncRequested event,
    Emitter<TriageState> emit,
  ) async {
    await repo.syncPending();
  }

  void onFailureToggled(
    FailureSimulationToggled event,
    Emitter<TriageState> emit,
  ) {
    mockApiClient.simulateFailure = event.enabled;
    emit(state.copyWith(simulateFailure: event.enabled));
  }

  Future<void> onDeleted(
    TriageDeleted event,
    Emitter<TriageState> emit,
  ) async {
    await repo.deleteRecord(event.record.id);
  }

  Future<void> onRestored(
    TriageRestored event,
    Emitter<TriageState> emit,
  ) async {
    await repo.restoreRecord(event.record);
  }

  @override
  Future<void> close() {
    storeSubscription.cancel();
    return super.close();
  }
}