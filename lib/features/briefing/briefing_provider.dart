import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers.dart';

final briefingProvider = FutureProvider<Briefing>((ref) {
  return ref.watch(apiClientProvider).fetchTodayBriefing();
});

/// Story ids the user has opened today; drives the briefing progress bar.
class ReadStoriesController extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void markRead(String storyId) => state = {...state, storyId};
}

final readStoriesProvider =
    NotifierProvider<ReadStoriesController, Set<String>>(ReadStoriesController.new);
