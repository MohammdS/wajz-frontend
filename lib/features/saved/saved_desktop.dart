import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/desktop/desktop_layout.dart';
import '../../widgets/desktop/desktop_story_tile.dart';
import '../../widgets/states.dart';
import '../stories/opened_stories_provider.dart';
import '../stories/story_providers.dart';

/// Saved, desktop layout: saved list as master pane, reading pane alongside.
class DesktopSavedView extends ConsumerStatefulWidget {
  const DesktopSavedView({super.key});

  @override
  ConsumerState<DesktopSavedView> createState() => _DesktopSavedViewState();
}

class _DesktopSavedViewState extends ConsumerState<DesktopSavedView> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final saved = ref.watch(savedStoriesProvider);
    final opened = ref.watch(openedStoriesProvider).ids;

    final master = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesktopPaneHeader(title: context.l10n.saved),
        Expanded(
          child: saved.when(
            loading: () => const LoadingState(),
            error: (e, _) =>
                ErrorState(onRetry: () => ref.invalidate(savedStoriesProvider)),
            data: (items) {
              if (items.isEmpty) {
                return EmptyState(
                  icon: Icons.bookmark_border,
                  title: context.l10n.noSavedStories,
                  message: context.l10n.saveStoryHelp,
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(savedStoriesProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    WajzSpacing.md,
                    0,
                    WajzSpacing.md,
                    WajzSpacing.xl,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final story = items[index].story;
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
