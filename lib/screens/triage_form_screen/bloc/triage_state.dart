part of 'triage_bloc.dart';

class TriageState extends Equatable {
  final List<TriageRecord> records;
  final int pendingCount;
  final bool simulateFailure;
  final String? lastSavedId;
  
  const TriageState({
    this.records = const [],
    this.pendingCount = 0,
    this.simulateFailure = false,
    this.lastSavedId,
  });

  TriageState copyWith({
    List<TriageRecord>? records,
    int? pendingCount,
    bool? simulateFailure,
    String? lastSavedId,
  }) =>
      TriageState(
        records: records ?? this.records,
        pendingCount: pendingCount ?? this.pendingCount,
        simulateFailure: simulateFailure ?? this.simulateFailure,
        lastSavedId: lastSavedId,
      );

  @override
  List<Object?> get props =>
      [records, pendingCount, simulateFailure, lastSavedId];
}
