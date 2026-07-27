import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers.dart';

const exploreStoriesPageSize = 20;

class ExploreStoriesState {
  const ExploreStoriesState({
    required this.items,
    required this.hasMore,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final List<StoryListItem> items;
  final bool hasMore;
  final bool isLoadingMore;
  final Object? loadMoreError;

  ExploreStoriesState copyWith({
    List<StoryListItem>? items,
    bool? hasMore,
    bool? isLoadingMore,
    Object? loadMoreError,
  }) => ExploreStoriesState(
    items: items ?? this.items,
    hasMore: hasMore ?? this.hasMore,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreError: loadMoreError,
  );
}

/// Stories for the Explore tab, optionally filtered by category.
class ExploreStoriesController extends AsyncNotifier<ExploreStoriesState> {
  ExploreStoriesController(this.category);

  final String? category;

  @override
  Future<ExploreStoriesState> build() async {
    ref.watch(sessionProvider.select((session) => session.token));
    final language = ref.watch(appLocaleProvider).languageCode;
    final stories = await _fetchPage(offset: 0, language: language);
    return ExploreStoriesState(
      items: stories,
      hasMore: stories.length == exploreStoriesPageSize,
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final language = ref.read(appLocaleProvider).languageCode;
      final next = await _fetchPage(
        offset: current.items.length,
        language: language,
      );
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...next],
          hasMore: next.length == exploreStoriesPageSize,
          isLoadingMore: false,
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(isLoadingMore: false, loadMoreError: error),
      );
    }
  }

  Future<List<StoryListItem>> _fetchPage({
    required int offset,
    required String language,
  }) async {
    final stories = await ref
        .read(apiClientProvider)
        .fetchStories(
          category: category,
          language: language,
          limit: exploreStoriesPageSize,
          offset: offset,
        );
    Future.microtask(() => ref.read(savedIdsProvider.notifier).seed(stories));
    return stories;
  }
}

final exploreStoriesProvider =
    AsyncNotifierProvider.family<
      ExploreStoriesController,
      ExploreStoriesState,
      String?
    >(ExploreStoriesController.new);

final storyDetailProvider = FutureProvider.family<StoryDetail, String>((
  ref,
  id,
) async {
  ref.watch(sessionProvider.select((session) => session.token));
  final language = ref.watch(appLocaleProvider).languageCode;
  final detail = await ref
      .watch(apiClientProvider)
      .fetchStoryDetail(id, language: language);
  Future.microtask(
    () => ref.read(savedIdsProvider.notifier).seedDetail(detail),
  );
  return detail;
});

/// Locally-known saved state, seeded from API responses and updated optimistically.
class SavedIdsController extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    ref.watch(sessionProvider.select((session) => session.token));
    return {};
  }

  void seed(Iterable<StoryListItem> stories) {
    final saved = stories.where((s) => s.saved).map((s) => s.id);
    final unsaved = stories.where((s) => !s.saved).map((s) => s.id).toSet();
    state = {...state.where((id) => !unsaved.contains(id)), ...saved};
  }

  void seedDetail(StoryDetail detail) {
    state = detail.saved
        ? {...state, detail.id}
        : ({...state}..remove(detail.id));
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

final savedIdsProvider = NotifierProvider<SavedIdsController, Set<String>>(
  SavedIdsController.new,
);

final savedStoriesProvider = FutureProvider<List<SavedStory>>((ref) async {
  ref.watch(sessionProvider.select((session) => session.token));
  final language = ref.watch(appLocaleProvider).languageCode;
  final saved = await ref
      .watch(apiClientProvider)
      .fetchSavedStories(language: language);
  // Keep the optimistic-set in sync whenever the list reloads.
  Future.microtask(
    () => ref.read(savedIdsProvider.notifier).seed(saved.map((s) => s.story)),
  );
  return saved;
});
