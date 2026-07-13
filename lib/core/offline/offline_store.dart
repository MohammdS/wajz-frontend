import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PendingOfflineAction {
  const PendingOfflineAction({
    required this.id,
    required this.scope,
    required this.method,
    required this.path,
    this.data,
  });

  final String id;
  final String scope;
  final String method;
  final String path;
  final Map<String, dynamic>? data;

  Map<String, dynamic> toJson() => {
    'id': id,
    'scope': scope,
    'method': method,
    'path': path,
    'data': data,
  };

  factory PendingOfflineAction.fromJson(Map<String, dynamic> json) =>
      PendingOfflineAction(
        id: json['id'] as String,
        scope: json['scope'] as String,
        method: json['method'] as String,
        path: json['path'] as String,
        data: (json['data'] as Map?)?.cast<String, dynamic>(),
      );
}

/// Persistent response cache and mutation queue shared by mobile and web.
class OfflineStore {
  OfflineStore(this._preferences) {
    pendingCount.value = pendingActions.length;
  }

  static const _cachePrefix = 'wajz_offline_cache_v1:';
  static const _queueKey = 'wajz_offline_actions_v1';

  final SharedPreferences _preferences;
  final ValueNotifier<int> pendingCount = ValueNotifier(0);

  static Future<OfflineStore> create() async =>
      OfflineStore(await SharedPreferences.getInstance());

  dynamic readCache(String key) {
    final encoded = _preferences.getString('$_cachePrefix$key');
    if (encoded == null) return null;
    try {
      return jsonDecode(encoded);
    } on FormatException {
      _preferences.remove('$_cachePrefix$key');
      return null;
    }
  }

  Future<void> writeCache(String key, Object? value) async {
    await _preferences.setString('$_cachePrefix$key', jsonEncode(value));
  }

  List<PendingOfflineAction> get pendingActions {
    final encoded = _preferences.getString(_queueKey);
    if (encoded == null) return const [];
    try {
      return (jsonDecode(encoded) as List)
          .map(
            (item) => PendingOfflineAction.fromJson(
              (item as Map).cast<String, dynamic>(),
            ),
          )
          .toList();
    } on Object {
      return const [];
    }
  }

  Future<void> enqueue(PendingOfflineAction action) async {
    final actions =
        pendingActions
            .where(
              (existing) =>
                  existing.scope != action.scope ||
                  existing.path != action.path,
            )
            .toList()
          ..add(action);
    await _saveActions(actions);
  }

  Future<void> removeAction(String id) async {
    await _saveActions(
      pendingActions.where((action) => action.id != id).toList(),
    );
  }

  Future<void> _saveActions(List<PendingOfflineAction> actions) async {
    await _preferences.setString(
      _queueKey,
      jsonEncode(actions.map((action) => action.toJson()).toList()),
    );
    pendingCount.value = actions.length;
  }
}
