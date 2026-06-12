import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api/api_client.dart';
import 'models/models.dart';
import 'storage/local_store.dart';

/// Overridden in main() with the real instance before runApp.
final localStoreProvider = Provider<LocalStore>(
  (ref) => throw UnimplementedError('localStoreProvider must be overridden'),
);

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// App session state: token + whether onboarding is complete.
class SessionState {
  const SessionState({this.token, required this.onboardingDone});

  final String? token;
  final bool onboardingDone;

  bool get authenticated => token != null;

  SessionState copyWith({String? token, bool? onboardingDone}) =>
      SessionState(token: token ?? this.token, onboardingDone: onboardingDone ?? this.onboardingDone);
}

class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    return SessionState(onboardingDone: ref.read(localStoreProvider).onboardingDone);
  }

  /// Restore a stored token, or sign in with a stable per-device dev account.
  /// (MVP auth: the backend issues dev JWTs; swap for Firebase/Supabase later.)
  Future<void> ensureSignedIn() async {
    final store = ref.read(localStoreProvider);
    final api = ref.read(apiClientProvider);

    var token = await store.readToken();
    if (token == null) {
      var email = store.deviceEmail;
      if (email == null) {
        final suffix = Random().nextInt(0x7FFFFFFF).toRadixString(16);
        email = 'reader-$suffix@wajz.dev';
        await store.setDeviceEmail(email);
      }
      token = await api.devLogin(email);
      await store.writeToken(token);
    }
    api.token = token;
    state = state.copyWith(token: token);
  }

  Future<void> completeOnboarding() async {
    await ref.read(localStoreProvider).setOnboardingDone(true);
    state = state.copyWith(onboardingDone: true);
  }

  Future<void> signOut() async {
    final store = ref.read(localStoreProvider);
    await store.clearToken();
    await store.setOnboardingDone(false);
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
