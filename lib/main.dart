import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/api/api_client.dart';
import 'core/offline/connectivity_monitor.dart';
import 'core/offline/offline_store.dart';
import 'core/providers.dart';
import 'core/storage/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await LocalStore.create();
  final offlineStore = await OfflineStore.create();
  final connectivityMonitor = ConnectivityMonitor(baseUrl: apiBaseUrl);
  await connectivityMonitor.initialize();
  runApp(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(store),
        offlineStoreProvider.overrideWithValue(offlineStore),
        connectivityMonitorProvider.overrideWithValue(connectivityMonitor),
      ],
      child: const WajzApp(),
    ),
  );
}
