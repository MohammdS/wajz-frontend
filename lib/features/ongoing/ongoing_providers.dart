import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/models.dart';
import '../../core/providers.dart';
import '../stories/story_providers.dart';

const ongoingTopicPageSize = 20;

final ongoingTopicsProvider = FutureProvider<List<OngoingTopic>>((ref) async {
  ref.watch(sessionProvider.select((session) => session.token));
  final language = ref.watch(appLocaleProvider).languageCode;
  return ref.watch(apiClientProvider).fetchOngoingTopics(language: language);
});

class OngoingTopicState {
  const OngoingTopicState({
    required this.topic,
    required this.items,
    required this.total,
    this.isLoadingMore = false,
    this.loadMoreError,
  });

  final OngoingTopic topic;
  final List<StoryListItem> items;
  final int total;
  final bool isLoadingMore;
  final Object? loadMoreError;

  bool get hasMore => items.length < total;

  OngoingTopicState copyWith({
    List<StoryListItem>? items,
    int? total,
    bool? isLoadingMore,
    Object? loadMoreError,
  }) => OngoingTopicState(
    topic: topic,
    items: items ?? this.items,
    total: total ?? this.total,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    loadMoreError: loadMoreError,
  );
}

class OngoingTopicController extends AsyncNotifier<OngoingTopicState> {
  OngoingTopicController(this.topicId);

  final String topicId;

  @override
  Future<OngoingTopicState> build() async {
    ref.watch(sessionProvider.select((session) => session.token));
    final language = ref.watch(appLocaleProvider).languageCode;
    final detail = await _fetchPage(offset: 0, language: language);
    Future.microtask(
      () => ref
          .read(analyticsServiceProvider)
          .track(
            'ongoing_topic_viewed',
            entityType: 'ongoing_topic',
            entityId: topicId,
            properties: {'language': language},
          ),
    );
    return OngoingTopicState(
      topic: detail.topic,
      items: detail.stories,
      total: detail.total,
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || current.isLoadingMore || !current.hasMore) return;
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final language = ref.read(appLocaleProvider).languageCode;
      final detail = await _fetchPage(
        offset: current.items.length,
        language: language,
      );
      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...detail.stories],
          total: detail.total,
          isLoadingMore: false,
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(isLoadingMore: false, loadMoreError: error),
      );
    }
  }

  Future<OngoingTopicDetail> _fetchPage({
    required int offset,
    required String language,
  }) async {
    final detail = await ref
        .read(apiClientProvider)
        .fetchOngoingTopic(
          topicId,
          language: language,
          limit: ongoingTopicPageSize,
          offset: offset,
        );
    Future.microtask(
      () => ref.read(savedIdsProvider.notifier).seed(detail.stories),
    );
    return detail;
  }
}

final ongoingTopicProvider =
    AsyncNotifierProvider.family<
      OngoingTopicController,
      OngoingTopicState,
      String
    >(OngoingTopicController.new);
