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
}
