import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Tracks whether the Wajz API is reachable, not only whether a network exists.
class ConnectivityMonitor {
  ConnectivityMonitor({required String baseUrl, Connectivity? connectivity})
    : _connectivity = kIsWeb ? null : (connectivity ?? Connectivity()),
      _probeClient = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 4),
          receiveTimeout: const Duration(seconds: 4),
        ),
      );

  final Connectivity? _connectivity;
  final Dio _probeClient;
  final ValueNotifier<bool> online = ValueNotifier(true);
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _retryTimer;

  Future<void> initialize() async {
    final connectivity = _connectivity;
    if (connectivity == null) {
      await _probeApi();
    } else {
      await _update(await connectivity.checkConnectivity());
      _subscription = connectivity.onConnectivityChanged.listen(_update);
    }
    _retryTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!online.value) checkNow();
    });
  }

  Future<bool> checkNow() async {
    final connectivity = _connectivity;
    if (connectivity == null) {
      await _probeApi();
    } else {
      await _update(await connectivity.checkConnectivity());
    }
    return online.value;
  }

  Future<void> _update(List<ConnectivityResult> results) async {
    if (results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none)) {
      markOffline();
      return;
    }
    await _probeApi();
  }

  Future<void> _probeApi() async {
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
