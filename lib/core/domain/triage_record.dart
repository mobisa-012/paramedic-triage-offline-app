import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

enum TriageStatus {
  pending,
  inTransit
}

enum SyncStatus {
  queued,
  syncing,
  synced,
  failed
}

extension TriageStatusLabel on TriageStatus {
  String get label {
    switch (this) {
      case TriageStatus.pending:
        return "Pending";
      case TriageStatus.inTransit:
        return "In Transit";
    }
  }  
}

extension SyncStatusLabel on SyncStatus {
    String get label {
      switch (this) {
        case SyncStatus.queued:
          return "Queued";
        case SyncStatus.syncing:
          return "Syncing..";
        case SyncStatus.synced:
          return "Synced";
        case SyncStatus.failed:
          return "Failed";
      }
    }
  }

  class TriageRecord extends Equatable {
    final String id;
    final String patientName;
    final String condition;
    final int priority;
    final TriageStatus status;
    final SyncStatus syncStatus;
    final DateTime createdAt;

    const TriageRecord({
      required this.id,
      required this.patientName,
      required this.condition,
      required this.priority,
      required this.status,
      required this.syncStatus,
      required this.createdAt,
    });

      bool get isCritical => priority <= 2;

    TriageRecord copyWith({
      SyncStatus? syncStatus,
    }) => TriageRecord(
      id: id,
      patientName: patientName,
      condition: condition,
      priority: priority,
      status: status,
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt,
    );

    Map<String, dynamic> toJson() => {
      "id": id,
      "patientName": patientName,
      "condition": condition,
      "priority": priority,
      "status": status.name,
      "syncStatus": syncStatus.name,
      "createdAt": createdAt.toIso8601String(),
    };

    @override
    List<Object?> get props => [id, patientName, condition, priority, status, syncStatus, createdAt];
  }

  class TriageRecordAdapter extends TypeAdapter<TriageRecord> {
  @override
  final int typeId = 0;

  @override
  TriageRecord read(BinaryReader reader) {
    return TriageRecord(
      id: reader.readString(),
      patientName: reader.readString(),
      condition: reader.readString(),
      priority: reader.readInt(),
      status: TriageStatus.values[reader.readInt()],
      syncStatus: SyncStatus.values[reader.readInt()],
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
    );
  }

  @override
  void write(BinaryWriter writer, TriageRecord obj) {
    writer
      ..writeString(obj.id)
      ..writeString(obj.patientName)
      ..writeString(obj.condition)
      ..writeInt(obj.priority)
      ..writeInt(obj.status.index)
      ..writeInt(obj.syncStatus == SyncStatus.syncing
          ? SyncStatus.queued.index
          : obj.syncStatus.index)
      ..writeInt(obj.createdAt.millisecondsSinceEpoch);
  }
}