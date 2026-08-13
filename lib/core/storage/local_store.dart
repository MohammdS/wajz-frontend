import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for the auth token and current interface language.
class LocalStore {
  LocalStore(this._prefs);

  static const _secure = FlutterSecureStorage();
  static const _tokenKey = 'wajz_auth_token';
  static const _languageKey = 'wajz_language';
  static const _themeKey = 'wajz_theme';
  static const _privacyInstallationKey = 'wajz_privacy_installation';
  static const _privacyWriteKey = 'wajz_privacy_write_key';
  static const _privacyVersionKey = 'wajz_privacy_version';
  static const _analyticsQueueKey = 'wajz_analytics_queue';

  final SharedPreferences _prefs;

  static Future<LocalStore> create() async {
    return LocalStore(await SharedPreferences.getInstance());
  }

  Future<String?> readToken() async {
    if (kIsWeb) {
      return _prefs.getString(_tokenKey);
    }
    return _secure.read(key: _tokenKey);
  }

  Future<void> writeToken(String token) async {
    if (kIsWeb) {
      await _prefs.setString(_tokenKey, token);
      return;
    }
    await _secure.write(key: _tokenKey, value: token);
  }

  Future<void> clearToken() async {
    if (kIsWeb) {
      await _prefs.remove(_tokenKey);
      return;
    }
    await _secure.delete(key: _tokenKey);
  }

  String get language => _prefs.getString(_languageKey) ?? 'en';

  Future<void> setLanguage(String language) =>
      _prefs.setString(_languageKey, language);

  /// Selected colour theme id (see `wajzPalettes`). Null until first chosen.
  String? get themeId => _prefs.getString(_themeKey);

  Future<void> setThemeId(String id) => _prefs.setString(_themeKey, id);

  String? get privacyInstallationId =>
      _prefs.getString(_privacyInstallationKey);
  String? get acceptedPrivacyVersion => _prefs.getString(_privacyVersionKey);
  String? get analyticsQueue => _prefs.getString(_analyticsQueueKey);

  Future<String?> readPrivacyWriteKey() async {
    if (kIsWeb) return _prefs.getString(_privacyWriteKey);
    return _secure.read(key: _privacyWriteKey);
  }

  Future<void> writePrivacyCredentials(
    String installationId,
    String key,
  ) async {
    await _prefs.setString(_privacyInstallationKey, installationId);
    if (kIsWeb) {
      await _prefs.setString(_privacyWriteKey, key);
    } else {
      await _secure.write(key: _privacyWriteKey, value: key);
    }
  }

  Future<void> setAcceptedPrivacyVersion(String version) =>
      _prefs.setString(_privacyVersionKey, version);

  Future<void> clearPrivacyAcceptance() => _prefs.remove(_privacyVersionKey);

  Future<void> clearPrivacyCredentials() async {
    await _prefs.remove(_privacyInstallationKey);
    await _prefs.remove(_privacyVersionKey);
    await _prefs.remove(_analyticsQueueKey);
    if (kIsWeb) {
      await _prefs.remove(_privacyWriteKey);
    } else {
      await _secure.delete(key: _privacyWriteKey);
    }
  }

  Future<void> writeAnalyticsQueue(String value) =>
      _prefs.setString(_analyticsQueueKey, value);
}
