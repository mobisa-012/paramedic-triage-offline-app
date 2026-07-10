part of 'triage_bloc.dart';

sealed class TriageEvent extends Equatable {
  const TriageEvent();
  @override
  List<Object?> get props => [];
}

class TriageSubmitted extends TriageEvent {
  const TriageSubmitted({
    required this.patientName,
    required this.condition,
    required this.priority,
    required this.status,
  });

  final String patientName;
  final String condition;
  final int priority;
  final TriageStatus status;

  @override
  List<Object?> get props => [patientName, condition, priority, status];
}

class TriageStoreChanged extends TriageEvent {
  const TriageStoreChanged();
}

class TriageSyncRequested extends TriageEvent {
  const TriageSyncRequested();
}

class FailureSimulationToggled extends TriageEvent {
  const FailureSimulationToggled(this.enabled);
  final bool enabled;
  @override
  List<Object?> get props => [enabled];
}
