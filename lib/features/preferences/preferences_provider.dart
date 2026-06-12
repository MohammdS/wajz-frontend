import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers.dart';
import '../briefing/briefing_provider.dart';

class PreferencesController extends AsyncNotifier<Preferences> {
  @override
  Future<Preferences> build() {
    return ref.watch(apiClientProvider).fetchPreferences();
  }

  Future<void> save(Preferences prefs) async {
    final api = ref.read(apiClientProvider);
    state = await AsyncValue.guard(() => api.updatePreferences(prefs));
    // Briefing depends on topics/regions/length.
    ref.invalidate(briefingProvider);
  }
}

final preferencesProvider =
    AsyncNotifierProvider<PreferencesController, Preferences>(PreferencesController.new);
