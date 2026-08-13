import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'app.dart';
import 'core/api/api_client.dart';
import 'core/auth/auth_service.dart';
import 'core/offline/connectivity_monitor.dart';
import 'core/offline/offline_store.dart';
import 'core/providers.dart';
import 'core/storage/local_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();
  final store = await LocalStore.create();
  final offlineStore = await OfflineStore.create();
  final authService = await AuthService.create();
  final connectivityMonitor = ConnectivityMonitor(baseUrl: apiBaseUrl);
  unawaited(connectivityMonitor.initialize());
  runApp(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(store),
        offlineStoreProvider.overrideWithValue(offlineStore),
        authServiceProvider.overrideWithValue(authService),
        connectivityMonitorProvider.overrideWithValue(connectivityMonitor),
      ],
      child: const WajzApp(),
    ),
  );
}
