import 'package:flutter/material.dart';

import 'package:paramedic_triage/core/domain/triage_record.dart';
import 'package:paramedic_triage/screens/triage_form_screen/widgets/priority_selector.dart';

class RecordCard extends StatelessWidget {
  const RecordCard({super.key, required this.record});

  final TriageRecord record;

  @override
  Widget build(BuildContext context) {
    final color = priorityColors[record.priority]!;
    final critical = record.isCritical;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: critical ? color.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: critical ? color.withOpacity(0.5) : Colors.black12,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: critical ? 8 : 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(11),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _PriorityChip(priority: record.priority),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            record.patientName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _SyncBadge(status: record.syncStatus),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      record.condition,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${record.status.label} · ${_time(record.createdAt)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black.withOpacity(0.45),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _time(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

class _PriorityChip extends StatelessWidget {
  const _PriorityChip({required this.priority});
  final int priority;

  @override
  Widget build(BuildContext context) {
    final color = priorityColors[priority]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'P$priority',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge({required this.status});
  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      SyncStatus.queued => (const Color(0xFFF9A825), Icons.schedule),
      SyncStatus.syncing => (const Color(0xFF1976D2), Icons.sync),
      SyncStatus.synced => (const Color(0xFF2E7D32), Icons.cloud_done),
      SyncStatus.failed => (const Color(0xFFF9A825), Icons.refresh),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
