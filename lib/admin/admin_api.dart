import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const adminApiBaseUrl = String.fromEnvironment(
  'WAJZ_API_BASE',
  defaultValue: kIsWeb ? 'http://127.0.0.1:8000' : 'http://10.0.2.2:8000',
);

class AdminSession {
  const AdminSession({
    required this.id,
    required this.email,
    required this.role,
    this.displayName,
  });

  final String id;
  final String email;
  final String role;
  final String? displayName;

  bool get canEdit => role == 'editor' || role == 'super_admin';
  bool get isSuperAdmin => role == 'super_admin';

  factory AdminSession.fromJson(Map<String, dynamic> json) => AdminSession(
    id: json['id'] as String,
    email: json['email'] as String,
    role: json['role'] as String,
    displayName: json['display_name'] as String?,
  );
}

class AdminApi {
  AdminApi()
    : _dio = Dio(
        BaseOptions(
          baseUrl: adminApiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 60),
        ),
      );

  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'wajz_admin_token';
  final Dio _dio;
  String? _token;

  Options get _auth => Options(
    headers: _token == null ? null : {'Authorization': 'Bearer $_token'},
  );

  Future<AdminSession?> restore() async {
    _token = await _storage.read(key: _tokenKey);
    if (_token == null) return null;
    try {
      return await session();
    } catch (_) {
      await logout();
      return null;
    }
  }

  Future<AdminSession> login(String email, {String? displayName}) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/auth/dev-login',
      data: {'email': email, 'display_name': displayName},
    );
    _token = response.data!['access_token'] as String;
    final current = await session();
    await _storage.write(key: _tokenKey, value: _token);
    return current;
  }

  Future<AdminSession> loginWithToken(String token) async {
    _token = token.trim();
    final current = await session();
    await _storage.write(key: _tokenKey, value: _token);
    return current;
  }

  Future<AdminSession> session() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/admin/session',
      options: _auth,
    );
    return AdminSession.fromJson(response.data!);
  }

  Future<void> logout() async {
    _token = null;
    await _storage.delete(key: _tokenKey);
  }

  Future<Map<String, dynamic>> getMap(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      path,
      queryParameters: query,
      options: _auth,
    );
    return response.data!;
  }

  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    final response = await _dio.get<List<dynamic>>(
      path,
      queryParameters: query,
      options: _auth,
    );
    return response.data!;
  }

  Future<dynamic> post(String path, [Map<String, dynamic>? data]) async {
    final response = await _dio.post<dynamic>(path, data: data, options: _auth);
    return response.data;
  }

  Future<dynamic> put(String path, Map<String, dynamic> data) async {
    final response = await _dio.put<dynamic>(path, data: data, options: _auth);
    return response.data;
  }

  Future<dynamic> patch(String path, Map<String, dynamic> data) async {
    final response = await _dio.patch<dynamic>(
      path,
      data: data,
      options: _auth,
    );
    return response.data;
  }
}
