import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../storage/local_store.dart';

const fallbackPrivacyVersion = '2026-08-13';

class PrivacyPolicyDocument {
  const PrivacyPolicyDocument({
    required this.version,
    required this.language,
    required this.title,
    required this.markdown,
  });

  final String version;
  final String language;
  final String title;
  final String markdown;
}

class AnalyticsService {
  AnalyticsService(this._store, {Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(baseUrl: apiBaseUrl));

  final LocalStore _store;
  final Dio _dio;
  final Random _random = Random.secure();
  String? _installationId;
  String? _writeKey;
  String? _token;
  String? _sessionId;
  DateTime? _lastEventAt;
  bool _flushing = false;

  late PrivacyPolicyDocument policy;
  bool accepted = false;

  set token(String? value) => _token = value;

  Future<void> initialize(String language) async {
    _installationId = _store.privacyInstallationId;
    _writeKey = await _store.readPrivacyWriteKey();
    policy = await _loadPolicy(language);
    accepted =
        _store.acceptedPrivacyVersion == policy.version &&
        _installationId != null &&
        _writeKey != null;
    if (accepted) {
      unawaited(track('session_started'));
      unawaited(flush());
    }
  }

  Future<PrivacyPolicyDocument> _loadPolicy(String language) async {
    final normalized = language == 'ar' ? 'ar' : 'en';
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/privacy-policy/current',
        queryParameters: {'language': normalized},
      );
      final data = response.data!;
      return PrivacyPolicyDocument(
        version: data['version'] as String,
        language: data['language'] as String,
        title: data['title'] as String,
        markdown: data['markdown'] as String,
      );
    } catch (_) {
      return PrivacyPolicyDocument(
        version: fallbackPrivacyVersion,
        language: normalized,
        title: normalized == 'ar'
            ? 'إشعار الخصوصية في واجِز'
            : 'Wajz Privacy Notice',
        markdown: normalized == 'ar'
            ? 'يستخدم واجِز تحليلات داخلية محدودة لقياس فتح الأخبار وحفظها وإكمال الموجز وزيارة المصادر. لا نضع نصوص الأخبار أو البريد الإلكتروني أو الروابط أو عناوين IP في أحداث التحليلات. نحتفظ بالأحداث لمدة 90 يوماً وبالإجماليات المجرّدة من الهوية لمدة 13 شهراً.'
            : 'Wajz uses limited first-party analytics for story opens, saves, briefing completion, and source visits. Analytics events exclude article text, email addresses, URLs, and IP addresses. Detailed events are retained for 90 days and deidentified totals for 13 months.',
      );
    }
  }

  Options get _installationOptions => Options(
    headers: {
      'X-Wajz-Installation-ID': _installationId,
      'X-Wajz-Analytics-Key': _writeKey,
      if (_token != null) 'Authorization': 'Bearer $_token',
    },
  );

  Future<void> accept() async {
    if (_installationId == null || _writeKey == null) {
      final response = await _dio.post<Map<String, dynamic>>(
        '/analytics/installations',
      );
      _installationId = response.data!['installation_id'] as String;
      _writeKey = response.data!['write_key'] as String;
      await _store.writePrivacyCredentials(_installationId!, _writeKey!);
    }
    await _dio.put<void>(
      '/privacy/acceptance',
      data: {'policy_version': policy.version, 'locale': policy.language},
      options: _installationOptions,
    );
    await _store.setAcceptedPrivacyVersion(policy.version);
    accepted = true;
    await track('session_started');
  }

  Future<void> withdraw() async {
    if (_installationId != null && _writeKey != null) {
      await _dio.post<void>('/privacy/withdraw', options: _installationOptions);
    }
    accepted = false;
    await _store.clearPrivacyAcceptance();
  }

  Future<void> deleteData() async {
    if (_installationId != null && _writeKey != null) {
      await _dio.delete<void>('/analytics/data', options: _installationOptions);
    }
    accepted = false;
    _installationId = null;
    _writeKey = null;
    await _store.clearPrivacyCredentials();
  }

  Future<void> track(
    String name, {
    String? entityType,
    String? entityId,
    Map<String, Object> properties = const {},
  }) async {
    if (!accepted) {
      return;
    }
    final now = DateTime.now().toUtc();
    if (_sessionId == null ||
        _lastEventAt == null ||
        now.difference(_lastEventAt!) > const Duration(minutes: 30)) {
      _sessionId = 'session_${_hex(12)}';
    }
    _lastEventAt = now;
    final queue = _readQueue();
    queue.add({
      'id': _hex(16),
      'session_id': _sessionId,
      'name': name,
      'occurred_at': now.toIso8601String(),
      'entity_type': ?entityType,
      'entity_id': ?entityId,
      'properties': properties,
      'locale': _store.language,
      'platform': _platform,
      'app_version': '0.1.0',
    });
    if (queue.length > 200) queue.removeRange(0, queue.length - 200);
    await _writeQueue(queue);
    unawaited(flush());
  }

  Future<void> flush() async {
    if (!accepted ||
        _flushing ||
        _installationId == null ||
        _writeKey == null) {
      return;
    }
    final queue = _readQueue();
    if (queue.isEmpty) return;
    _flushing = true;
    try {
      final batch = queue.take(50).toList();
      await _dio.post<void>(
        '/analytics/events/batch',
        data: {'events': batch},
        options: _installationOptions,
      );
      queue.removeRange(0, batch.length);
      await _writeQueue(queue);
    } catch (_) {
      // Analytics never blocks reading; the bounded queue retries later.
    } finally {
      _flushing = false;
    }
  }

  List<Map<String, dynamic>> _readQueue() {
    final raw = _store.analyticsQueue;
    if (raw == null || raw.isEmpty) return [];
    try {
      return (jsonDecode(raw) as List)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeQueue(List<Map<String, dynamic>> queue) =>
      _store.writeAnalyticsQueue(jsonEncode(queue));

  String _hex(int bytes) => List.generate(
    bytes,
    (_) => _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();

  String get _platform {
    if (kIsWeb) return 'web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'android',
      TargetPlatform.iOS => 'ios',
      TargetPlatform.windows => 'windows',
      TargetPlatform.macOS => 'macos',
      TargetPlatform.linux => 'linux',
      TargetPlatform.fuchsia => 'linux',
    };
  }
}
