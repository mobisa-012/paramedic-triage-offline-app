import 'package:flutter/material.dart';

import 'package:paramedic_triage/core/domain/triage_record.dart';
import 'package:paramedic_triage/screens/triage_form_screen/widgets/priority_selector.dart';

class RecordDetailScreen extends StatelessWidget {
  const RecordDetailScreen({super.key, required this.record});

  final TriageRecord record;

  @override
  Widget build(BuildContext context) {
    final color = priorityColors[record.priority]!;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Record Detail',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5),
        ),
        backgroundColor: const Color(0xFF102A43),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'P${record.priority} · ${priorityLabels[record.priority]}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      record.syncStatus.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  record.patientName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  record.condition,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                _DetailRow(label: 'Status', value: record.status.label),
                _DetailRow(
                  label: 'Logged at',
                  value: record.createdAt.toLocal().toString(),
                ),
                _DetailRow(label: 'Record ID', value: record.id),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: Colors.black.withOpacity(0.45),
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
