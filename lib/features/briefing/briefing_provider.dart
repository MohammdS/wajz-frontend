import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers.dart';
import '../stories/story_providers.dart';

final briefingProvider = FutureProvider<Briefing>((ref) async {
  final language = ref.watch(appLocaleProvider).languageCode;
  final briefing = await ref.watch(apiClientProvider).fetchTodayBriefing(
        language: language,
      );
  Future.microtask(
    () => ref.read(savedIdsProvider.notifier).seed(briefing.stories),
  );
  return briefing;
});

/// Story ids the user has opened today; drives the briefing progress bar.
class ReadStoriesController extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void markRead(String storyId) => state = {...state, storyId};
}

final readStoriesProvider =
    NotifierProvider<ReadStoriesController, Set<String>>(ReadStoriesController.new);
