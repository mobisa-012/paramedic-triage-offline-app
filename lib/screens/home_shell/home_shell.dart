import 'package:flutter/material.dart';

import 'package:paramedic_triage/core/sync/sync_service.dart';
import 'package:paramedic_triage/screens/records_screen/records_screen.dart';
import 'package:paramedic_triage/screens/triage_form_screen/triage_form_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.syncService});

  final SyncService syncService;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          TriageFormScreen(syncService: widget.syncService),
          const RecordsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: 'Intake',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Records',
          ),
        ],
      ),
    );
  }
}
