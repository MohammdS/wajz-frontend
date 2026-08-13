import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class OpenedStoriesState {
  const OpenedStoriesState({
    this.date,
    this.ids = const {},
    this.briefingTotal = 0,
    this.completionTracked = false,
  });

  final String? date;
  final Set<String> ids;
  final int briefingTotal;
  final bool completionTracked;
}

/// Opened story ids are seeded from the account and updated optimistically.
class OpenedStoriesController extends Notifier<OpenedStoriesState> {
  @override
  OpenedStoriesState build() {
    ref.watch(sessionProvider.select((session) => session.token));
    return const OpenedStoriesState();
  }

  void seed(String date, Iterable<String> storyIds, {required int total}) {
    final ids = storyIds.toSet();
    final merged = state.date == date ? {...state.ids, ...ids} : ids;
    state = OpenedStoriesState(
      date: date,
      ids: merged,
      briefingTotal: total,
      completionTracked: merged.length >= total && total > 0,
    );
  }

  Future<void> markOpened(String storyId) async {
    if (state.ids.contains(storyId)) return;
    await ref
        .read(analyticsServiceProvider)
        .track('story_opened', entityType: 'story', entityId: storyId);
    final previous = state;
    state = OpenedStoriesState(
      date: state.date,
      ids: {...state.ids, storyId},
      briefingTotal: state.briefingTotal,
      completionTracked: state.completionTracked,
    );
    if (ref.read(sessionProvider).authenticated) {
      try {
        await ref.read(apiClientProvider).markStoryOpened(storyId);
      } catch (_) {
        state = previous;
        rethrow;
      }
    }
    if (!state.completionTracked &&
        state.date != null &&
        state.briefingTotal > 0 &&
        state.ids.length >= state.briefingTotal) {
      state = OpenedStoriesState(
        date: state.date,
        ids: state.ids,
        briefingTotal: state.briefingTotal,
        completionTracked: true,
      );
      await ref
          .read(analyticsServiceProvider)
          .track(
            'briefing_completed',
            entityType: 'briefing',
            entityId: state.date,
            properties: {'briefing_length': state.briefingTotal},
          );
    }
  }
}

final openedStoriesProvider =
    NotifierProvider<OpenedStoriesController, OpenedStoriesState>(
      OpenedStoriesController.new,
    );
