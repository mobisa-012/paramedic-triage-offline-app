import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:paramedic_triage/screens/triage_form_screen/bloc/triage_bloc.dart';
import 'package:paramedic_triage/core/data/local_store.dart';
import 'package:paramedic_triage/core/data/mock_api_client.dart';
import 'package:paramedic_triage/core/data/triage_repo.dart';
import 'package:paramedic_triage/core/sync/sync_service.dart';
import 'package:paramedic_triage/screens/home_shell/home_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  final store = await LocalStore.open();
  final apiClient = MockAPIClient();
  final repository = TriageRepo(store: store, api: apiClient);
  final syncService = SyncService(syncPending: repository.syncPending);
  await syncService.start();

  runApp(TriageApp(
    repository: repository,
    apiClient: apiClient,
    syncService: syncService,
  ));
}

class TriageApp extends StatelessWidget {
  const TriageApp({
    super.key,
    required this.repository,
    required this.apiClient,
    required this.syncService,
  });

  final TriageRepo repository;
  final MockAPIClient apiClient;
  final SyncService syncService;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          TriageBloc(triageRepository: repository, apiClient: apiClient),
      child: MaterialApp(
        title: 'Paramedic Triage',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF102A43),
          ),
          fontFamily: 'Roboto',
        ),
        home: HomeShell(syncService: syncService),
      ),
    );
  }
}
