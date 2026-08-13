import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/desktop/desktop_layout.dart';
import '../../widgets/desktop/desktop_story_tile.dart';
import '../../widgets/states.dart';
import '../../widgets/story_card.dart';
import '../stories/opened_stories_provider.dart';
import 'ongoing_providers.dart';

class OngoingTopicScreen extends ConsumerStatefulWidget {
  const OngoingTopicScreen({super.key, required this.topicId});

  final String topicId;

  @override
  ConsumerState<OngoingTopicScreen> createState() => _OngoingTopicScreenState();
}

class _OngoingTopicScreenState extends ConsumerState<OngoingTopicScreen> {
  late final ScrollController _scrollController;
  String? _selectedStoryId;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_loadMoreNearBottom);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_loadMoreNearBottom)
      ..dispose();
    super.dispose();
  }

  void _loadMoreNearBottom() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.extentAfter > 600) return;
    ref.read(ongoingTopicProvider(widget.topicId).notifier).loadMore();
  }

  Future<void> _refresh() async {
    ref.invalidate(ongoingTopicProvider(widget.topicId));
    ref.invalidate(ongoingTopicsProvider);
    await ref.read(ongoingTopicProvider(widget.topicId).future);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ongoingTopicProvider(widget.topicId));
    if (isDesktopWidth(context)) {
      return Scaffold(body: _desktopBody(state));
    }
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/ongoing')),
        title: Text(context.l10n.ongoing),
      ),
      body: state.when(
        loading: () => const LoadingState(),
        error: (_, _) => ErrorState(
          onRetry: () => ref.invalidate(ongoingTopicProvider(widget.topicId)),
        ),
        data: (data) => _mobileBody(data),
      ),
    );
  }

  Widget _mobileBody(OngoingTopicState data) {
    if (data.items.isEmpty) {
      return Column(
        children: [
          _TopicHeader(topic: data.topic, onBack: null),
          Expanded(
            child: EmptyState(
              icon: Icons.article_outlined,
              title: context.l10n.nothingHere,
              message: context.l10n.noStoriesInTopic,
            ),
          ),
        ],
      );
    }
    final showFooter = data.hasMore || data.loadMoreError != null;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          WajzSpacing.md,
          WajzSpacing.sm,
          WajzSpacing.md,
          WajzSpacing.xl,
        ),
        itemCount: data.items.length + 1 + (showFooter ? 1 : 0),
        separatorBuilder: (_, _) => const SizedBox(height: WajzSpacing.md),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _TopicHeader(topic: data.topic, onBack: null);
          }
          final storyIndex = index - 1;
          if (storyIndex == data.items.length) {
            return _LoadMoreFooter(
              isLoading: data.isLoadingMore,
              hasError: data.loadMoreError != null,
              onRetry: () => ref
                  .read(ongoingTopicProvider(widget.topicId).notifier)
                  .loadMore(),
            );
          }
          return StoryCard(story: data.items[storyIndex]);
        },
      ),
    );
  }

  Widget _desktopBody(AsyncValue<OngoingTopicState> state) {
    return state.when(
      loading: () => const LoadingState(),
      error: (_, _) => ErrorState(
        onRetry: () => ref.invalidate(ongoingTopicProvider(widget.topicId)),
      ),
      data: (data) {
        final opened = ref.watch(openedStoriesProvider).ids;
        final master = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TopicHeader(
              topic: data.topic,
              onBack: () => context.go('/ongoing'),
            ),
            Expanded(
              child: data.items.isEmpty
                  ? EmptyState(
                      icon: Icons.article_outlined,
                      title: context.l10n.nothingHere,
                      message: context.l10n.noStoriesInTopic,
                    )
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(
                          WajzSpacing.md,
                          0,
                          WajzSpacing.md,
                          WajzSpacing.xl,
                        ),
                        itemCount:
                            data.items.length +
                            (data.hasMore || data.loadMoreError != null
                                ? 1
                                : 0),
                        itemBuilder: (context, index) {
                          if (index == data.items.length) {
                            return _LoadMoreFooter(
                              isLoading: data.isLoadingMore,
                              hasError: data.loadMoreError != null,
                              onRetry: () => ref
                                  .read(
                                    ongoingTopicProvider(
                                      widget.topicId,
                                    ).notifier,
                                  )
                                  .loadMore(),
                            );
                          }
                          final story = data.items[index];
                          return DesktopStoryTile(
                            story: story,
                            selected: _selectedStoryId == story.id,
                            opened: opened.contains(story.id),
                            onTap: () =>
                                setState(() => _selectedStoryId = story.id),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
        return DesktopMasterDetail(
          master: master,
          selectedStoryId: _selectedStoryId,
          onCloseDetail: () => setState(() => _selectedStoryId = null),
        );
      },
    );
  }
}

class _TopicHeader extends StatelessWidget {
  const _TopicHeader({required this.topic, required this.onBack});

  final OngoingTopic topic;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(WajzSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (onBack != null) ...[
            TextButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: Text(context.l10n.backToOngoing),
            ),
            const SizedBox(height: WajzSpacing.sm),
          ],
          Wrap(
            spacing: WajzSpacing.sm,
            runSpacing: WajzSpacing.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Chip(
                avatar: const Icon(Icons.radar, size: 16),
                label: Text(context.l10n.ongoingBadge),
                visualDensity: VisualDensity.compact,
              ),
              if (topic.category != null)
                CategoryChip(category: topic.category!),
            ],
          ),
          const SizedBox(height: WajzSpacing.sm),
          Text(
            topic.title,
            style: wajzDisplayFont(
              Localizations.localeOf(context),
              textStyle: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
          const SizedBox(height: WajzSpacing.sm),
          Text(
            topic.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: WajzSpacing.md),
          Text(
            '${context.l10n.topicStories(topic.storyCount)} · '
            '${context.l10n.updated(context.l10n.timeAgo(topic.lastUpdatedAt))}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  const _LoadMoreFooter({
    required this.isLoading,
    required this.hasError,
    required this.onRetry,
  });

  final bool isLoading;
  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (hasError) {
      return Center(
        child: OutlinedButton(
          onPressed: onRetry,
          child: Text(context.l10n.tryAgain),
        ),
      );
    }
    if (!isLoading) return const SizedBox(height: WajzSpacing.md);
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: WajzSpacing.md),
      child: Center(
        child: SizedBox.square(
          dimension: 22,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      ),
    );
  }
}
