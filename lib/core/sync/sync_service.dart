import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

class SyncService with WidgetsBindingObserver {
  final Future<void> Function() syncPending;
  final Connectivity connectivity;
  StreamSubscription<List<ConnectivityResult>>? subscription;

  SyncService({
    required this.syncPending,
    Connectivity? connectivity,
  }) : connectivity = connectivity ?? Connectivity();

  final ValueNotifier<bool> isOnline = ValueNotifier(true);

  Future<void> start() async {
    WidgetsBinding.instance.addObserver(this);

    subscription = connectivity.onConnectivityChanged.listen((results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      final cameBackOnline = online && !isOnline.value;
      isOnline.value = online;
      if (cameBackOnline) {
        syncPending();
      }
    });

    final initial = await connectivity.checkConnectivity();
    isOnline.value = initial.any((r) => r != ConnectivityResult.none);
    if (isOnline.value) {
      syncPending();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      syncPending();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    subscription?.cancel();
    isOnline.dispose();
  }
}