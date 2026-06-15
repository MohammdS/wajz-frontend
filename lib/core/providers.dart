import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/api_client.dart';
import 'models/models.dart';
import 'storage/local_store.dart';
import 'theme/app_theme.dart';

/// Overridden in main() with the real instance before runApp.
final localStoreProvider = Provider<LocalStore>(
  (ref) => throw UnimplementedError('localStoreProvider must be overridden'),
);

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

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
  const SessionState({this.token, required this.onboardingDone});

  final String? token;
  final bool onboardingDone;

  bool get authenticated => token != null;

  SessionState copyWith({String? token, bool? onboardingDone}) => SessionState(
    token: token ?? this.token,
    onboardingDone: onboardingDone ?? this.onboardingDone,
  );
}

class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    return const SessionState(onboardingDone: false);
  }

  /// Restore a stored development session without creating an account.
  Future<bool> restoreSession() async {
    final store = ref.read(localStoreProvider);
    final api = ref.read(apiClientProvider);

    final token = await store.readToken();
    if (token == null) return false;

    api.token = token;
    try {
      await _loadSession(token);
      return true;
    } catch (_) {
      await store.clearToken();
      api.token = null;
      return false;
    }
  }

  /// Temporary development login. The backend creates the account if needed.
  Future<void> signIn(String email, {String? displayName}) async {
    final store = ref.read(localStoreProvider);
    final api = ref.read(apiClientProvider);
    final token = await api.devLogin(email, displayName: displayName);
    await store.writeToken(token);
    api.token = token;
    await _loadSession(token);
  }

  Future<void> _loadSession(String token) async {
    final preferences = await ref.read(apiClientProvider).fetchPreferences();
    await ref
        .read(appLocaleProvider.notifier)
        .setLanguage(preferences.preferredLanguage);
    state = state.copyWith(
      token: token,
      onboardingDone: preferences.onboardingCompleted,
    );
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(onboardingDone: true);
  }

  Future<void> signOut() async {
    final store = ref.read(localStoreProvider);
    await store.clearToken();
    ref.read(apiClientProvider).token = null;
    state = const SessionState(token: null, onboardingDone: false);
  }
}

final sessionProvider = NotifierProvider<SessionController, SessionState>(
  SessionController.new,
);

final categoriesProvider = FutureProvider<CategoryInfo>((ref) {
  return ref.watch(apiClientProvider).fetchCategories();
});
