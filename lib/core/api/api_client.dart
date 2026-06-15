import 'package:dio/dio.dart';

import 'package:flutter/foundation.dart';

import '../models/models.dart';

/// Backend base URL. Override at build time:
///   flutter run --dart-define=WAJZ_API_BASE=http://192.168.1.10:8000
/// Defaults to local host on web and the Android emulator's host loopback on mobile.
const apiBaseUrl = String.fromEnvironment(
  'WAJZ_API_BASE',
  defaultValue: kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000',
);

class ApiClient {
  ApiClient({String? baseUrl, Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl ?? apiBaseUrl,
              connectTimeout: const Duration(seconds: 10),
              receiveTimeout: const Duration(seconds: 20),
            ),
          );

  final Dio _dio;
  String? _token;

  // The app never talks to AI APIs directly; all keys live in the backend.

  set token(String? value) => _token = value;

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
    final response = await _dio.get<Map<String, dynamic>>('/categories');
    return CategoryInfo.fromJson(response.data!);
  }

  Future<List<StoryListItem>> fetchStories({
    String? category,
    String? region,
    String? language,
    int limit = 20,
    int offset = 0,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/stories',
      queryParameters: {
        'category': ?category,
        'region': ?region,
        'language': ?language,
        'limit': limit,
        'offset': offset,
      },
      options: _authOptions,
    );
    return (response.data!['items'] as List)
        .map((item) => StoryListItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<StoryDetail> fetchStoryDetail(String id, {String? language}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/stories/$id',
      queryParameters: {'language': ?language},
      options: _authOptions,
    );
    return StoryDetail.fromJson(response.data!);
  }

  Future<Briefing> fetchTodayBriefing({String? language}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/me/briefing/today',
      queryParameters: {'language': ?language},
      options: _authOptions,
    );
    return Briefing.fromJson(response.data!);
  }

  Future<void> markStoryOpened(String id) =>
      _dio.post<void>('/me/stories/$id/opened', options: _authOptions);

  Future<Preferences> fetchPreferences() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/me/preferences',
      options: _authOptions,
    );
    return Preferences.fromJson(response.data!);
  }

  Future<Preferences> updatePreferences(Preferences prefs) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/me/preferences',
      data: prefs.toJson(),
      options: _authOptions,
    );
    return Preferences.fromJson(response.data!);
  }

  Future<List<SavedStory>> fetchSavedStories({String? language}) async {
    final response = await _dio.get<List<dynamic>>(
      '/me/saved-stories',
      queryParameters: {'language': ?language},
      options: _authOptions,
    );
    return response.data!
        .map((item) => SavedStory.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveStory(String id) =>
      _dio.post<void>('/me/saved-stories/$id', options: _authOptions);

  Future<void> unsaveStory(String id) =>
      _dio.delete<void>('/me/saved-stories/$id', options: _authOptions);
}
