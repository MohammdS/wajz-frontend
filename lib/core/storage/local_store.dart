import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence for the auth token and current interface language.
class LocalStore {
  LocalStore(this._prefs);

  static const _secure = FlutterSecureStorage();
  static const _tokenKey = 'wajz_auth_token';
  static const _languageKey = 'wajz_language';

  final SharedPreferences _prefs;

  static Future<LocalStore> create() async {
    return LocalStore(await SharedPreferences.getInstance());
  }

  Future<String?> readToken() => _secure.read(key: _tokenKey);

  Future<void> writeToken(String token) =>
      _secure.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _secure.delete(key: _tokenKey);

  String get language => _prefs.getString(_languageKey) ?? 'en';

  Future<void> setLanguage(String language) =>
      _prefs.setString(_languageKey, language);
}
