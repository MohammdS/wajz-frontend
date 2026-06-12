import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/briefing_progress.dart';
import '../../widgets/states.dart';
import '../../widgets/story_card.dart';
import '../stories/story_providers.dart';
import 'briefing_provider.dart';

/// Today tab (PRD 16.2): greeting, briefing summary, progress, finite story
/// list ending in "You are caught up." No infinite feed.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final briefing = ref.watch(briefingProvider);
    final readIds = ref.watch(readStoriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Today')),
      body: briefing.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(onRetry: () => ref.invalidate(briefingProvider)),
        data: (data) {
          // Seed saved-state from the API payload.
          ref.read(savedIdsProvider.notifier).seed(data.stories);
          final read = data.stories.where((s) => readIds.contains(s.id)).length;

          if (data.stories.isEmpty) {
            return EmptyState(
              icon: Icons.wb_sunny_outlined,
              title: 'No briefing yet',
              message:
                  'Stories are still being gathered. Check back in a little while.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(briefingProvider),
            child: ListView(
              padding: const EdgeInsets.all(WajzSpacing.md),
              children: [
                Text(data.greeting, style: theme.textTheme.headlineSmall),
                const SizedBox(height: WajzSpacing.xs),
                Text(
                  'Your ${data.estimatedReadTimeMinutes}-minute briefing is ready. '
                  '${data.stories.length} stories selected from trusted sources.',
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: WajzSpacing.md),
                BriefingProgress(read: read, total: data.stories.length),
                const SizedBox(height: WajzSpacing.lg),
                for (final story in data.stories)
                  Padding(
                    padding: const EdgeInsets.only(bottom: WajzSpacing.md),
                    child: StoryCard(
                      story: story,
                      onOpen: () =>
                          ref.read(readStoriesProvider.notifier).markRead(story.id),
                    ),
                  ),
                _CaughtUpCard(message: data.completionMessage),
                const SizedBox(height: WajzSpacing.xl),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CaughtUpCard extends StatelessWidget {
  const _CaughtUpCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(WajzSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline, color: theme.colorScheme.primary, size: 32),
          const SizedBox(height: WajzSpacing.sm),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: WajzSpacing.xs),
          Text(
            'That is everything worth knowing for now.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
