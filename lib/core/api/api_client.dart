import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../models/models.dart';
import '../offline/connectivity_monitor.dart';
import '../offline/offline_store.dart';

/// Backend base URL. Override at build time:
///   flutter run --dart-define=WAJZ_API_BASE=http://192.168.1.10:8000
/// Defaults to local host on web and the Android emulator's host loopback on mobile.
const apiBaseUrl = String.fromEnvironment(
  'WAJZ_API_BASE',
  defaultValue: kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000',
);

class ApiClient {
  ApiClient({
    String? baseUrl,
    Dio? dio,
    this.offlineStore,
    this.connectivityMonitor,
  }) : _dio =
           dio ??
           Dio(
             BaseOptions(
               baseUrl: baseUrl ?? apiBaseUrl,
               connectTimeout: const Duration(seconds: 10),
               receiveTimeout: const Duration(seconds: 20),
             ),
           ) {
    connectivityMonitor?.online.addListener(_onConnectivityChanged);
  }

  final Dio _dio;
  final OfflineStore? offlineStore;
  final ConnectivityMonitor? connectivityMonitor;
  String? _token;
  String _scope = 'anonymous';
  bool _syncing = false;

  // The app never talks to AI APIs directly; all keys live in the backend.

  set token(String? value) {
    _token = value;
    _scope = _tokenScope(value);
    if (value != null && (connectivityMonitor?.online.value ?? true)) {
      flushQueuedActions();
    }
  }

  Options get _authOptions => Options(
    headers: _token != null ? {'Authorization': 'Bearer $_token'} : null,
  );

  Future<String> devLogin(String email, {String? displayName}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/dev-login',
      data: {'email': email, 'display_name': displayName},
    );
    return response.data!['access_token'] as String;
  }

  Future<CategoryInfo> fetchCategories() async {
    final data = await _getCachedMap('/categories', cacheKey: 'categories');
    return CategoryInfo.fromJson(data);
  }

  Future<List<OngoingTopic>> fetchOngoingTopics({
    String? language,
    int limit = 20,
    int offset = 0,
  }) async {
    final data = await _getCachedMap(
      '/ongoing-topics',
      cacheKey: 'ongoing-topics:$_scope:${language ?? '-'}:$limit:$offset',
      queryParameters: {
        'language': ?language,
        'limit': limit,
        'offset': offset,
      },
      options: _authOptions,
    );
    return (data['items'] as List)
        .map((item) => OngoingTopic.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<OngoingTopicDetail> fetchOngoingTopic(
    String id, {
    String? language,
    int limit = 20,
    int offset = 0,
  }) async {
    final data = await _getCachedMap(
      '/ongoing-topics/$id',
      cacheKey: 'ongoing-topic:$_scope:$id:${language ?? '-'}:$limit:$offset',
      queryParameters: {
        'language': ?language,
        'limit': limit,
        'offset': offset,
      },
      options: _authOptions,
    );
    return OngoingTopicDetail.fromJson(data);
  }

  Future<List<StoryListItem>> fetchStories({
    String? category,
    String? region,
    String? language,
    int limit = 20,
    int offset = 0,
  }) async {
    final data = await _getCachedMap(
      '/stories',
      cacheKey:
          'stories:$_scope:${category ?? '-'}:${region ?? '-'}:${language ?? '-'}:$limit:$offset',
      queryParameters: {
        'category': ?category,
        'region': ?region,
        'language': ?language,
        'limit': limit,
        'offset': offset,
      },
      options: _authOptions,
    );
    return (data['items'] as List)
        .map((item) => StoryListItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<StoryDetail> fetchStoryDetail(String id, {String? language}) async {
    final data = await _getCachedMap(
      '/stories/$id',
      cacheKey: 'story:$_scope:$id:${language ?? '-'}',
      queryParameters: {'language': ?language},
      options: _authOptions,
    );
    return StoryDetail.fromJson(data);
  }

  Future<Briefing> fetchTodayBriefing({String? language}) async {
    final data = await _getCachedMap(
      '/me/briefing/today',
      cacheKey: 'briefing:$_scope:${language ?? '-'}',
      queryParameters: {'language': ?language},
      options: _authOptions,
    );
    return Briefing.fromJson(data);
  }

  Future<void> markStoryOpened(String id) =>
      _sendOrQueue('POST', '/me/stories/$id/opened', options: _authOptions);

  Future<Preferences> fetchPreferences() async {
    final data = await _getCachedMap(
      '/me/preferences',
      cacheKey: 'preferences:$_scope',
      options: _authOptions,
    );
    return Preferences.fromJson(data);
  }

  Future<Preferences> updatePreferences(Preferences prefs) async {
    final data = prefs.toJson();
    final queued = await _sendOrQueue(
      'PUT',
      '/me/preferences',
      data: data,
      options: _authOptions,
    );
    await offlineStore?.writeCache('preferences:$_scope', data);
    if (queued) {
      return prefs;
    }
    return fetchPreferences();
  }

  Future<List<SavedStory>> fetchSavedStories({String? language}) async {
    final data = await _getCachedList(
      '/me/saved-stories',
      cacheKey: 'saved:$_scope:${language ?? '-'}',
      queryParameters: {'language': ?language},
      options: _authOptions,
    );
    return data
        .map((item) => SavedStory.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveStory(String id) =>
      _sendOrQueue('POST', '/me/saved-stories/$id', options: _authOptions);

  Future<void> unsaveStory(String id) =>
      _sendOrQueue('DELETE', '/me/saved-stories/$id', options: _authOptions);

  Future<Map<String, dynamic>> _getCachedMap(
    String path, {
    required String cacheKey,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final data = await _getCached(
      path,
      cacheKey: cacheKey,
      queryParameters: queryParameters,
      options: options,
    );
    return (data as Map).cast<String, dynamic>();
  }

  Future<List<dynamic>> _getCachedList(
    String path, {
    required String cacheKey,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    final data = await _getCached(
      path,
      cacheKey: cacheKey,
      queryParameters: queryParameters,
      options: options,
    );
    return data as List<dynamic>;
  }

  Future<dynamic> _getCached(
    String path, {
    required String cacheKey,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    if (connectivityMonitor?.online.value == false) {
      final cached = offlineStore?.readCache(cacheKey);
      if (cached != null) return cached;
    }
    try {
      final response = await _dio.get<dynamic>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      connectivityMonitor?.markOnline();
      await offlineStore?.writeCache(cacheKey, response.data);
      return response.data;
    } on DioException catch (error) {
      if (!_isConnectionFailure(error)) rethrow;
      connectivityMonitor?.markOffline();
      final cached = offlineStore?.readCache(cacheKey);
      if (cached == null) rethrow;
      return cached;
    }
  }

  /// Returns true when the mutation was queued instead of sent.
  Future<bool> _sendOrQueue(
    String method,
    String path, {
    Map<String, dynamic>? data,
    Options? options,
  }) async {
    if (connectivityMonitor?.online.value == false && offlineStore != null) {
      await _enqueueAction(method, path, data);
      return true;
    }
    try {
      await _dio.request<void>(
        path,
        data: data,
        options: (options ?? Options()).copyWith(method: method),
      );
      connectivityMonitor?.markOnline();
      return false;
    } on DioException catch (error) {
      if (!_isConnectionFailure(error) || offlineStore == null) rethrow;
      connectivityMonitor?.markOffline();
      await _enqueueAction(method, path, data);
      return true;
    }
  }

  Future<void> _enqueueAction(
    String method,
    String path,
    Map<String, dynamic>? data,
  ) => offlineStore!.enqueue(
    PendingOfflineAction(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      scope: _scope,
      method: method,
      path: path,
      data: data,
    ),
  );

  void _onConnectivityChanged() {
    if (connectivityMonitor?.online.value ?? false) flushQueuedActions();
  }

  Future<void> flushQueuedActions() async {
    final store = offlineStore;
    if (store == null || _syncing || _token == null) return;
    _syncing = true;
    try {
      final actions = store.pendingActions
          .where((action) => action.scope == _scope)
          .toList();
      for (final action in actions) {
        try {
          await _dio.request<void>(
            action.path,
            data: action.data,
            options: _authOptions.copyWith(method: action.method),
          );
          await store.removeAction(action.id);
        } on DioException catch (error) {
          if (_isConnectionFailure(error) ||
              error.response?.statusCode == 429) {
            connectivityMonitor?.markOffline();
            break;
          }
          // Validation, authorization, and missing-resource failures cannot
          // succeed on retry; discard them instead of blocking the queue.
          await store.removeAction(action.id);
        }
      }
    } finally {
      _syncing = false;
    }
  }

  bool _isConnectionFailure(DioException error) =>
      error.response == null &&
      {
        DioExceptionType.connectionTimeout,
        DioExceptionType.sendTimeout,
        DioExceptionType.receiveTimeout,
        DioExceptionType.connectionError,
        DioExceptionType.unknown,
      }.contains(error.type);

  String _tokenScope(String? token) {
    if (token == null) return 'anonymous';
    try {
      final parts = token.split('.');
      if (parts.length != 3) return token.hashCode.toString();
      final payload =
          jsonDecode(
                utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
              )
              as Map<String, dynamic>;
      return (payload['sub'] ?? payload['email'] ?? token.hashCode).toString();
    } on Object {
      return token.hashCode.toString();
    }
  }

  void dispose() {
    connectivityMonitor?.online.removeListener(_onConnectivityChanged);
    _dio.close(force: true);
  }
}
