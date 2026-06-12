import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local persistence: secure storage for the auth token, shared preferences
/// for non-sensitive flags (onboarding state, device account email).
class LocalStore {
  LocalStore(this._prefs);

  static const _secure = FlutterSecureStorage();
  static const _tokenKey = 'wajz_auth_token';
  static const _onboardingKey = 'wajz_onboarding_done';
  static const _emailKey = 'wajz_device_email';

  final SharedPreferences _prefs;

  static Future<LocalStore> create() async {
    return LocalStore(await SharedPreferences.getInstance());
  }

  Future<String?> readToken() => _secure.read(key: _tokenKey);

  Future<void> writeToken(String token) => _secure.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _secure.delete(key: _tokenKey);

  bool get onboardingDone => _prefs.getBool(_onboardingKey) ?? false;

  Future<void> setOnboardingDone(bool value) => _prefs.setBool(_onboardingKey, value);

  String? get deviceEmail => _prefs.getString(_emailKey);

  Future<void> setDeviceEmail(String email) => _prefs.setString(_emailKey, email);
}
