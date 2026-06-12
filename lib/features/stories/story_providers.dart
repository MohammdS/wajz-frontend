import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers.dart';

/// Stories for the Explore tab, optionally filtered by category.
final exploreStoriesProvider =
    FutureProvider.family<List<StoryListItem>, String?>((ref, category) {
  return ref.watch(apiClientProvider).fetchStories(category: category, limit: 25);
});

final storyDetailProvider = FutureProvider.family<StoryDetail, String>((ref, id) {
  return ref.watch(apiClientProvider).fetchStoryDetail(id);
});

/// Locally-known saved state, seeded from API responses and updated optimistically.
class SavedIdsController extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  void seed(Iterable<StoryListItem> stories) {
    final saved = stories.where((s) => s.saved).map((s) => s.id);
    final unsaved = stories.where((s) => !s.saved).map((s) => s.id).toSet();
    state = {...state.where((id) => !unsaved.contains(id)), ...saved};
  }

  void seedDetail(StoryDetail detail) {
    state = detail.saved ? {...state, detail.id} : ({...state}..remove(detail.id));
  }

  Future<void> toggle(String storyId) async {
    final api = ref.read(apiClientProvider);
    final wasSaved = state.contains(storyId);
    state = wasSaved ? ({...state}..remove(storyId)) : {...state, storyId};
    try {
      if (wasSaved) {
        await api.unsaveStory(storyId);
      } else {
        await api.saveStory(storyId);
      }
    } catch (_) {
      // Roll back the optimistic update on failure.
      state = wasSaved ? {...state, storyId} : ({...state}..remove(storyId));
      rethrow;
    }
  }
}

final savedIdsProvider =
    NotifierProvider<SavedIdsController, Set<String>>(SavedIdsController.new);

final savedStoriesProvider = FutureProvider<List<SavedStory>>((ref) async {
  final saved = await ref.watch(apiClientProvider).fetchSavedStories();
  // Keep the optimistic-set in sync whenever the list reloads.
  Future.microtask(
    () => ref.read(savedIdsProvider.notifier).seed(saved.map((s) => s.story)),
  );
  return saved;
});
