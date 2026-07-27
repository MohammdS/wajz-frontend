import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/desktop/desktop_layout.dart';
import '../../widgets/desktop/desktop_story_tile.dart';
import '../../widgets/preference_chip.dart';
import '../../widgets/states.dart';
import '../stories/opened_stories_provider.dart';
import '../stories/story_providers.dart';

/// Explore, desktop layout: category filter + story list as the master pane,
/// reading pane alongside.
class DesktopExploreView extends ConsumerStatefulWidget {
  const DesktopExploreView({super.key});

  @override
  ConsumerState<DesktopExploreView> createState() => _DesktopExploreViewState();
}

class _DesktopExploreViewState extends ConsumerState<DesktopExploreView> {
  String? _category;
  String? _selected;
  late final ScrollController _scrollController;

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
    ref.read(exploreStoriesProvider(_category).notifier).loadMore();
  }

  void _selectCategory(String? category) {
    setState(() {
      _category = category;
      _selected = null;
    });
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final stories = ref.watch(exploreStoriesProvider(_category));
    final opened = ref.watch(openedStoriesProvider).ids;

    final master = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesktopPaneHeader(
          title: context.l10n.explore,
          subtitle: context.l10n.topicsHelp,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            WajzSpacing.lg,
            WajzSpacing.xs,
            WajzSpacing.lg,
            WajzSpacing.sm,
          ),
          child: Wrap(
            spacing: WajzSpacing.sm,
            runSpacing: WajzSpacing.sm,
            children: [
              PreferenceChip(
                label: context.l10n.all,
                selected: _category == null,
                onTap: () => _selectCategory(null),
              ),
              for (final category
                  in categories.value?.categories ?? const <String>[])
                PreferenceChip(
                  label: context.l10n.category(category),
                  selected: _category == category,
                  onTap: () => _selectCategory(category),
                ),
            ],
          ),
        ),
        Expanded(
          child: stories.when(
            loading: () => const LoadingState(),
            error: (e, _) => ErrorState(
              onRetry: () => ref.invalidate(exploreStoriesProvider(_category)),
            ),
            data: (data) {
              final items = data.items;
              if (items.isEmpty) {
                return EmptyState(
                  icon: Icons.travel_explore,
                  title: context.l10n.nothingHere,
                  message: context.l10n.noStoriesInCategory,
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(exploreStoriesProvider(_category));
                  await ref.read(exploreStoriesProvider(_category).future);
                },
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    WajzSpacing.md,
                    0,
                    WajzSpacing.md,
                    WajzSpacing.xl,
                  ),
                  itemCount:
                      items.length +
                      (data.hasMore || data.loadMoreError != null ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == items.length) {
                      return _DesktopLoadMoreFooter(
                        isLoading: data.isLoadingMore,
                        hasError: data.loadMoreError != null,
                        onRetry: () => ref
                            .read(exploreStoriesProvider(_category).notifier)
                            .loadMore(),
                      );
                    }
                    final story = items[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: DesktopStoryTile(
                        story: story,
                        selected: _selected == story.id,
                        opened: opened.contains(story.id),
                        onTap: () => setState(() => _selected = story.id),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );

    return DesktopMasterDetail(
      master: master,
      selectedStoryId: _selected,
      onCloseDetail: () => setState(() => _selected = null),
    );
  }
}

class _DesktopLoadMoreFooter extends StatelessWidget {
  const _DesktopLoadMoreFooter({
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
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: WajzSpacing.md),
        child: Center(
          child: OutlinedButton(
            onPressed: onRetry,
            child: Text(context.l10n.tryAgain),
          ),
        ),
      );
    }
    if (!isLoading) return const SizedBox(height: WajzSpacing.md);
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: WajzSpacing.md),
      child: Center(
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      ),
    );
  }
}
