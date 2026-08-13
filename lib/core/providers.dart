import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/api_client.dart';
import 'analytics/analytics_service.dart';
import 'auth/auth_service.dart';
import 'models/models.dart';
import 'offline/connectivity_monitor.dart';
import 'offline/offline_store.dart';
import 'storage/local_store.dart';
import 'theme/app_theme.dart';

/// Overridden in main() with the real instance before runApp.
final localStoreProvider = Provider<LocalStore>(
  (ref) => throw UnimplementedError('localStoreProvider must be overridden'),
);

final offlineStoreProvider = Provider<OfflineStore>(
  (ref) => throw UnimplementedError('offlineStoreProvider must be overridden'),
);

final authServiceProvider = Provider<AuthService>(
  (ref) => const AuthService.disabled(),
);

final connectivityMonitorProvider = Provider<ConnectivityMonitor>(
  (ref) => throw UnimplementedError(
    'connectivityMonitorProvider must be overridden',
  ),
);

final apiClientProvider = Provider<ApiClient>((ref) {
  final client = ApiClient(
    offlineStore: ref.watch(offlineStoreProvider),
    connectivityMonitor: ref.watch(connectivityMonitorProvider),
  );
  ref.onDispose(client.dispose);
  return client;
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(ref.watch(localStoreProvider));
});

class PrivacyEpochController extends Notifier<int> {
  @override
  int build() => 0;

  void changed() => state++;
}

final privacyEpochProvider = NotifierProvider<PrivacyEpochController, int>(
  PrivacyEpochController.new,
);

class AppLocaleController extends Notifier<Locale> {
  @override
  Locale build() => Locale(ref.read(localStoreProvider).language);

  Future<void> setLanguage(String language) async {
    if (!const {'en', 'ar'}.contains(language)) return;
    await ref.read(localStoreProvider).setLanguage(language);
    state = Locale(language);
  }
}

final appLocaleProvider = NotifierProvider<AppLocaleController, Locale>(
  AppLocaleController.new,
);

/// The selected colour theme, persisted locally and applied app-wide.
class AppThemeController extends Notifier<WajzPalette> {
  @override
  WajzPalette build() => wajzPaletteById(ref.read(localStoreProvider).themeId);

  Future<void> setPalette(WajzPalette palette) async {
    await ref.read(localStoreProvider).setThemeId(palette.id);
    state = palette;
  }
}

final appThemeProvider = NotifierProvider<AppThemeController, WajzPalette>(
  AppThemeController.new,
);

/// App session state: token + whether onboarding is complete.
class SessionState {
  const SessionState({
    this.token,
    required this.onboardingDone,
    this.authReady = false,
  });

  final String? token;
  final bool onboardingDone;
  final bool authReady;

  bool get authenticated => token != null;

  SessionState copyWith({
    String? token,
    bool? onboardingDone,
    bool? authReady,
  }) => SessionState(
    token: token ?? this.token,
    onboardingDone: onboardingDone ?? this.onboardingDone,
    authReady: authReady ?? this.authReady,
  );
}

class SessionController extends Notifier<SessionState> {
  StreamSubscription<WajzAuthState>? _authSubscription;

  @override
  SessionState build() {
    final auth = ref.watch(authServiceProvider);
    _authSubscription?.cancel();
    if (auth.enabled) {
      _authSubscription = auth.authStateChanges.listen((event) {
        final token = event.session?.accessToken;
        if (token == null) {
          unawaited(_clearLocalSession());
        } else if (token != state.token) {
          unawaited(
            _activateToken(token).catchError((_) async {
              await auth.signOut();
              await _clearLocalSession();
            }),
          );
        }
      });
      ref.onDispose(() => _authSubscription?.cancel());
    }
    return const SessionState(onboardingDone: false, authReady: false);
  }

  /// Restore a Supabase session, or an explicitly enabled local dev session.
  Future<bool> restoreSession() async {
    final auth = ref.read(authServiceProvider);
    final store = ref.read(localStoreProvider);
    final token = auth.enabled
        ? auth.currentAccessToken
        : (devLoginEnabled ? await store.readToken() : null);
    if (token == null) return false;

    try {
      await _activateToken(token);
      return true;
    } catch (_) {
      if (auth.enabled) await auth.signOut();
      await _clearLocalSession();
      return false;
    }
  }

  Future<void> signInWithPassword(String email, String password) async {
    final response = await ref
        .read(authServiceProvider)
        .signInWithPassword(email: email, password: password);
    final token = response.session?.accessToken;
    if (token == null) throw StateError('No session returned after sign in.');
    await _activateToken(token);
  }

  /// Returns true when email confirmation is required before sign-in.
  Future<bool> signUp(
    String email,
    String password, {
    String? displayName,
  }) async {
    final response = await ref
        .read(authServiceProvider)
        .signUp(email: email, password: password, displayName: displayName);
    final token = response.session?.accessToken;
    if (token == null) return true;
    await _activateToken(token);
    return false;
  }

  Future<void> signInWithGoogle() async {
    final launched = await ref.read(authServiceProvider).signInWithGoogle();
    if (!launched) throw StateError('Could not open Google sign-in.');
  }

  Future<void> sendPasswordReset(String email) =>
      ref.read(authServiceProvider).sendPasswordReset(email);

  /// Temporary development login, disabled unless explicitly enabled at build.
  Future<void> signInForDevelopment(String email, {String? displayName}) async {
    if (!devLoginEnabled) {
      throw StateError('Development login is disabled.');
    }
    final store = ref.read(localStoreProvider);
    final api = ref.read(apiClientProvider);
    final token = await api.devLogin(email, displayName: displayName);
    await store.writeToken(token);
    await _activateToken(token);
  }

  Future<void> _activateToken(String token) async {
    final wasAuthenticated = state.token != null;
    if (state.token != token) {
      // Publish the identity boundary before loading account data so every
      // account-scoped provider is disposed before the new requests begin.
      state = SessionState(
        token: token,
        onboardingDone: false,
        authReady: state.authReady,
      );
    }
    final api = ref.read(apiClientProvider)..token = token;
    ref.read(analyticsServiceProvider).token = token;
    final preferences = await api.fetchPreferences();
    await ref
        .read(appLocaleProvider.notifier)
        .setLanguage(preferences.preferredLanguage);
    state = state.copyWith(
      token: token,
      onboardingDone: preferences.onboardingCompleted,
    );
    if (!wasAuthenticated) {
      unawaited(
        ref
            .read(analyticsServiceProvider)
            .track(
              'authentication_completed',
              properties: {'result': 'success'},
            ),
      );
    }
  }

  Future<void> _clearLocalSession() async {
    await ref.read(localStoreProvider).clearToken();
    ref.read(apiClientProvider).token = null;
    ref.read(analyticsServiceProvider).token = null;
    state = const SessionState(
      token: null,
      onboardingDone: false,
      authReady: true,
    );
  }

  void finishBootstrap() {
    if (!state.authReady) state = state.copyWith(authReady: true);
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingDone: true);
  }

  Future<void> signOut() async {
    await ref.read(authServiceProvider).signOut();
    await _clearLocalSession();
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

final categoriesProvider = FutureProvider<CategoryInfo>((ref) {
  return ref.watch(apiClientProvider).fetchCategories();
});
