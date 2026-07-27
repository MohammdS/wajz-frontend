import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/desktop/desktop_layout.dart';
import '../../widgets/preference_chip.dart';
import '../../widgets/states.dart';
import '../../widgets/story_card.dart';
import '../stories/story_providers.dart';
import 'explore_desktop.dart';

/// Explore tab (PRD 16.3): controlled browsing by category with paged loading.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  String? _category;
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
    setState(() => _category = category);
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isDesktopWidth(context)) return const DesktopExploreView();

    final categories = ref.watch(categoriesProvider);
    final stories = ref.watch(exploreStoriesProvider(_category));

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.explore)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              WajzSpacing.md,
              WajzSpacing.xs,
              WajzSpacing.md,
              WajzSpacing.md,
            ),
            child: Text(
              context.l10n.topicsHelp,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: WajzSpacing.md),
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: WajzSpacing.sm),
                  child: PreferenceChip(
                    label: context.l10n.all,
                    selected: _category == null,
                    onTap: () => _selectCategory(null),
                  ),
                ),
                for (final category
                    in categories.value?.categories ?? const <String>[])
                  Padding(
                    padding: const EdgeInsets.only(right: WajzSpacing.sm),
                    child: PreferenceChip(
                      label: context.l10n.category(category),
                      selected: _category == category,
                      onTap: () => _selectCategory(category),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: stories.when(
              loading: () => const LoadingState(),
              error: (e, _) => ErrorState(
                onRetry: () =>
                    ref.invalidate(exploreStoriesProvider(_category)),
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
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(WajzSpacing.md),
                    itemCount:
                        items.length +
                        (data.hasMore || data.loadMoreError != null ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: WajzSpacing.md),
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        return _LoadMoreFooter(
                          isLoading: data.isLoadingMore,
                          hasError: data.loadMoreError != null,
                          onRetry: () => ref
                              .read(exploreStoriesProvider(_category).notifier)
                              .loadMore(),
                        );
                      }
                      return StoryCard(story: items[index]);
                    },
                  ),
                );
              },
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: WajzSpacing.md),
        child: SizedBox(
          height: 22,
          width: 22,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      ),
    );
  }
}
