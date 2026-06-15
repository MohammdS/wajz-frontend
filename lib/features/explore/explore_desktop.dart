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
                onTap: () => setState(() => _category = null),
              ),
              for (final category
                  in categories.value?.categories ?? const <String>[])
                PreferenceChip(
                  label: context.l10n.category(category),
                  selected: _category == category,
                  onTap: () => setState(() => _category = category),
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
            data: (items) {
              if (items.isEmpty) {
                return EmptyState(
                  icon: Icons.travel_explore,
                  title: context.l10n.nothingHere,
                  message: context.l10n.noStoriesInCategory,
                );
              }
              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(exploreStoriesProvider(_category)),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    WajzSpacing.md,
                    0,
                    WajzSpacing.md,
                    WajzSpacing.xl,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
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
