import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/desktop/desktop_layout.dart';
import '../../widgets/states.dart';
import '../../widgets/story_card.dart';
import '../stories/story_providers.dart';
import 'saved_desktop.dart';

/// Saved tab (PRD 16.4): saved list, unsave, empty state.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isDesktopWidth(context)) return const DesktopSavedView();

    final saved = ref.watch(savedStoriesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.saved)),
      body: saved.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(onRetry: () => ref.invalidate(savedStoriesProvider)),
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
            child: ListView.separated(
              padding: const EdgeInsets.all(WajzSpacing.md),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: WajzSpacing.md),
              itemBuilder: (context, index) => StoryCard(story: items[index].story),
            ),
          );
        },
      ),
    );
  }
}
