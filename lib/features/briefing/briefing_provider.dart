import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers.dart';
import '../stories/opened_stories_provider.dart';
import '../stories/story_providers.dart';

final briefingProvider = FutureProvider<Briefing>((ref) async {
  ref.watch(sessionProvider.select((session) => session.token));
  final language = ref.watch(appLocaleProvider).languageCode;
  final briefing = await ref
      .watch(apiClientProvider)
      .fetchTodayBriefing(language: language);
  Future.microtask(
    () => ref
        .read(analyticsServiceProvider)
        .track(
          'briefing_viewed',
          entityType: 'briefing',
          entityId: briefing.date,
          properties: {
            'briefing_length': briefing.briefingLength,
            'language': language,
          },
        ),
  );
  Future.microtask(() {
    ref.read(savedIdsProvider.notifier).seed(briefing.stories);
    ref
        .read(openedStoriesProvider.notifier)
        .seed(
          briefing.date,
          briefing.openedStoryIds,
          total: briefing.stories.length,
        );
  });
  return briefing;
});
