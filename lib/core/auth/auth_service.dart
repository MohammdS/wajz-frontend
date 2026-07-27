import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

typedef WajzAuthState = AuthState;

const supabaseUrl = String.fromEnvironment('WAJZ_SUPABASE_URL');
const supabasePublishableKey = String.fromEnvironment(
  'WAJZ_SUPABASE_PUBLISHABLE_KEY',
);
const authRedirectUrl = String.fromEnvironment(
  'WAJZ_AUTH_REDIRECT_URL',
  defaultValue: 'io.wajz.app://login-callback/',
);
const devLoginEnabled = bool.fromEnvironment('WAJZ_ENABLE_DEV_LOGIN');

class AuthService {
  AuthService._(this._client);

  const AuthService.disabled() : _client = null;

  final SupabaseClient? _client;

  bool get enabled => _client != null;
  String? get currentAccessToken => _client?.auth.currentSession?.accessToken;
  Stream<AuthState> get authStateChanges =>
      _client?.auth.onAuthStateChange ?? const Stream.empty();

  static Future<AuthService> create() async {
    if (supabaseUrl.isEmpty && supabasePublishableKey.isEmpty) {
      return const AuthService.disabled();
    }
    if (supabaseUrl.isEmpty || supabasePublishableKey.isEmpty) {
      throw StateError(
        'WAJZ_SUPABASE_URL and WAJZ_SUPABASE_PUBLISHABLE_KEY must both be set.',
      );
    }
    final supabase = await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabasePublishableKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    return AuthService._(supabase.client);
  }

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) {
    return _requireClient().auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? displayName,
  }) {
    return _requireClient().auth.signUp(
      email: email,
      password: password,
      data: {if (displayName?.isNotEmpty == true) 'full_name': displayName},
      emailRedirectTo: kIsWeb ? null : authRedirectUrl,
    );
  }

  Future<bool> signInWithGoogle() {
    return _requireClient().auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : authRedirectUrl,
      authScreenLaunchMode: kIsWeb
          ? LaunchMode.platformDefault
          : LaunchMode.externalApplication,
    );
  }

  Future<void> sendPasswordReset(String email) {
    return _requireClient().auth.resetPasswordForEmail(
      email,
      redirectTo: kIsWeb ? null : authRedirectUrl,
    );
  }

  Future<void> signOut() async {
    if (_client != null) await _client.auth.signOut();
  }

  SupabaseClient _requireClient() {
    final client = _client;
    if (client == null) {
      throw StateError('Production authentication is not configured.');
    }
    return client;
  }
}
