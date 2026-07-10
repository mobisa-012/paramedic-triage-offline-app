import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:paramedic_triage/core/sync/sync_service.dart';
import 'package:paramedic_triage/core/domain/triage_record.dart';
import 'package:paramedic_triage/screens/triage_form_screen/bloc/triage_bloc.dart';
import 'package:paramedic_triage/screens/triage_form_screen/widgets/priority_selector.dart';
import 'package:paramedic_triage/screens/triage_form_screen/widgets/record_card.dart';

class TriageFormScreen extends StatefulWidget {
  const TriageFormScreen({super.key, required this.syncService});

  final SyncService syncService;

  @override
  State<TriageFormScreen> createState() => _TriageFormScreenState();
}

class _TriageFormScreenState extends State<TriageFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _conditionController = TextEditingController();
  int? _priority;
  TriageStatus _status = TriageStatus.pending;
  String? _priorityError;

  @override
  void dispose() {
    _nameController.dispose();
    _conditionController.dispose();
    super.dispose();
  }

  void _submit() {
    final formOk = _formKey.currentState!.validate();
    final priorityOk = _priority != null;
    setState(() {
      _priorityError = priorityOk ? null : 'Select a priority level';
    });
    if (!formOk || !priorityOk) return;

    context.read<TriageBloc>().add(TriageSubmitted(
          patientName: _nameController.text,
          condition: _conditionController.text,
          priority: _priority!,
          status: _status,
        ));
  }

  void _resetForm() {
    _formKey.currentState!.reset();
    _nameController.clear();
    _conditionController.clear();
    setState(() {
      _priority = null;
      _status = TriageStatus.pending;
      _priorityError = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text(
          'TRIAGE INTAKE',
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5),
        ),
        backgroundColor: const Color(0xFF102A43),
        foregroundColor: Colors.white,
        actions: [
          BlocBuilder<TriageBloc, TriageState>(
            buildWhen: (p, c) => p.simulateFailure != c.simulateFailure,
            builder: (context, state) => Row(
              children: [
                Icon(
                  Icons.bug_report,
                  size: 18,
                  color: state.simulateFailure
                      ? Colors.orangeAccent
                      : Colors.white38,
                ),
                Switch(
                  value: state.simulateFailure,
                  activeColor: Colors.orangeAccent,
                  onChanged: (v) => context
                      .read<TriageBloc>()
                      .add(FailureSimulationToggled(v)),
                ),
              ],
            ),
          ),
        ],
      ),
      body: BlocListener<TriageBloc, TriageState>(
        listenWhen: (prev, curr) =>
            curr.lastSavedId != null && prev.lastSavedId != curr.lastSavedId,
        listener: (context, state) {
          _resetForm();
          final online = widget.syncService.isOnline.value;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(
              behavior: SnackBarBehavior.floating,
              backgroundColor:
                  online ? const Color(0xFF2E7D32) : const Color(0xFFF9A825),
              content: Text(
                online
                    ? 'Record saved — uploading'
                    : 'Record saved on device — will sync when back online',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ));
        },
        child: Column(
          children: [
            _OfflineBanner(syncService: widget.syncService),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildFormCard(),
                  const SizedBox(height: 24),
                  _buildQueueHeader(),
                  const SizedBox(height: 10),
                  BlocBuilder<TriageBloc, TriageState>(
                    builder: (context, state) {
                      if (state.records.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'No patients logged yet.\nSaved records appear here — online or offline.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.black.withOpacity(0.4),
                              ),
                            ),
                          ),
                        );
                      }
                      return Column(
                        children: [
                          for (final record in state.records)
                            RecordCard(record: record),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _FieldLabel('PATIENT NAME'),
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: _fieldDecoration('e.g. Jane Achieng'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Patient name is required'
                  : null,
            ),
            const SizedBox(height: 16),
            const _FieldLabel('CONDITION DESCRIPTION'),
            TextFormField(
              controller: _conditionController,
              maxLines: 3,
              minLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration:
                  _fieldDecoration('e.g. Chest pain, shallow breathing'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Condition description is required'
                  : null,
            ),
            const SizedBox(height: 16),
            const _FieldLabel('PRIORITY LEVEL  ·  1 = LIFE-THREATENING'),
            PrioritySelector(
              selected: _priority,
              error: _priorityError,
              onChanged: (level) => setState(() {
                _priority = level;
                _priorityError = null;
              }),
            ),
            const SizedBox(height: 16),
            const _FieldLabel('STATUS'),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<TriageStatus>(
                segments: const [
                  ButtonSegment(
                    value: TriageStatus.pending,
                    label: Text('Pending'),
                    icon: Icon(Icons.hourglass_top, size: 16),
                  ),
                  ButtonSegment(
                    value: TriageStatus.inTransit,
                    label: Text('In-Transit'),
                    icon: Icon(Icons.local_shipping, size: 16),
                  ),
                ],
                selected: {_status},
                onSelectionChanged: (s) => setState(() => _status = s.first),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 56, // large primary action for thumb input
              child: FilledButton.icon(
                onPressed: _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF102A43),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                icon: const Icon(Icons.save),
                label: const Text('SAVE TRIAGE RECORD'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueHeader() {
    return BlocBuilder<TriageBloc, TriageState>(
      builder: (context, state) => Row(
        children: [
          Text(
            'LOGGED PATIENTS (${state.records.length})',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
              color: Colors.black.withOpacity(0.55),
            ),
          ),
          const Spacer(),
          if (state.pendingCount > 0)
            TextButton.icon(
              onPressed: () =>
                  context.read<TriageBloc>().add(const TriageSyncRequested()),
              icon: const Icon(Icons.sync, size: 16),
              label: Text('Sync ${state.pendingCount} now'),
            ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF4F6F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: Colors.black.withOpacity(0.55),
          ),
        ),
      );
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.syncService});
  final SyncService syncService;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: syncService.isOnline,
      builder: (context, online, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: online ? 0 : 40,
        color: const Color(0xFFF9A825),
        child: online
            ? null
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 16, color: Colors.black87),
                  SizedBox(width: 8),
                  Text(
                    'Offline — records save on device and sync later',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
