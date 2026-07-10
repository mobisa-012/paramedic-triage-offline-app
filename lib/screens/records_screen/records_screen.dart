import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:paramedic_triage/screens/triage_form_screen/bloc/triage_bloc.dart';
import 'package:paramedic_triage/screens/records_screen/record_detail_screen.dart';
import 'package:paramedic_triage/screens/triage_form_screen/widgets/record_card.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'Patient Records',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5),
        ),
        backgroundColor: const Color(0xFF102A43),
        foregroundColor: Colors.white,
        actions: [
          BlocBuilder<TriageBloc, TriageState>(
            builder: (context, state) => state.pendingCount > 0
                ? TextButton.icon(
                    onPressed: () => context
                        .read<TriageBloc>()
                        .add(const TriageSyncRequested()),
                    icon: const Icon(Icons.sync,
                        size: 16, color: Colors.white),
                    label: Text(
                      'Sync ${state.pendingCount}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
      body: BlocBuilder<TriageBloc, TriageState>(
        builder: (context, state) {
          if (state.records.isEmpty) {
            return Center(
              child: Text(
                'No records yet.',
                style: TextStyle(color: Colors.black.withOpacity(0.4)),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.records.length,
            itemBuilder: (context, index) {
              final record = state.records[index];
              return Dismissible(
                key: ValueKey(record.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.only(right: 20),
                  alignment: Alignment.centerRight,
                  decoration: BoxDecoration(
                    color: const Color(0xFFB71C1C),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.delete_outline, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        'Delete',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                confirmDismiss: (_) async {
                  return await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Delete record?'),
                          content: Text(
                            'Delete "${record.patientName}"? This cannot be '
                            'undone.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              child: const Text('Cancel'),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFFB71C1C),
                              ),
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(true),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                },
                onDismissed: (_) {
                  context.read<TriageBloc>().add(TriageDeleted(record));
                },
                child: RecordCard(
                  record: record,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => RecordDetailScreen(record: record),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
