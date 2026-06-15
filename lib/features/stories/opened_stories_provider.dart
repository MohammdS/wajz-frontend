import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';

class OpenedStoriesState {
  const OpenedStoriesState({this.date, this.ids = const {}});

  final String? date;
  final Set<String> ids;
}

/// Opened story ids are seeded from the account and updated optimistically.
class OpenedStoriesController extends Notifier<OpenedStoriesState> {
  @override
  OpenedStoriesState build() {
    ref.watch(sessionProvider.select((session) => session.token));
    return const OpenedStoriesState();
  }

  void seed(String date, Iterable<String> storyIds) {
    final ids = storyIds.toSet();
    state = state.date == date
        ? OpenedStoriesState(date: date, ids: {...state.ids, ...ids})
        : OpenedStoriesState(date: date, ids: ids);
  }

  Future<void> markOpened(String storyId) async {
    if (state.ids.contains(storyId)) return;
    final previous = state;
    state = OpenedStoriesState(date: state.date, ids: {...state.ids, storyId});
    try {
      await ref.read(apiClientProvider).markStoryOpened(storyId);
    } catch (_) {
      state = previous;
      rethrow;
    }
  }
}

final openedStoriesProvider =
    NotifierProvider<OpenedStoriesController, OpenedStoriesState>(
      OpenedStoriesController.new,
    );
