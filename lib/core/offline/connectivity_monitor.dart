import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Tracks whether the Wajz API is reachable, not only whether a network exists.
class ConnectivityMonitor {
  ConnectivityMonitor({required String baseUrl, Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity(),
      _probeClient = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );

  final Connectivity _connectivity;
  final Dio _probeClient;
  final ValueNotifier<bool> online = ValueNotifier(true);
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _retryTimer;

  Future<void> initialize() async {
    await _update(await _connectivity.checkConnectivity());
    _subscription = _connectivity.onConnectivityChanged.listen(_update);
    _retryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!online.value) checkNow();
    });
  }

  Future<bool> checkNow() async {
    await _update(await _connectivity.checkConnectivity());
    return online.value;
  }

  Future<void> _update(List<ConnectivityResult> results) async {
    if (results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none)) {
      markOffline();
      return;
    }
    try {
      await _probeClient.get<void>('/health');
      markOnline();
    } on DioException {
      markOffline();
    }
  }

  void markOnline() {
    if (!online.value) online.value = true;
  }

  void markOffline() {
    if (online.value) online.value = false;
  }

  void dispose() {
    _subscription?.cancel();
    _retryTimer?.cancel();
    online.dispose();
    _probeClient.close(force: true);
  }
}
