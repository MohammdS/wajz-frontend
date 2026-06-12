import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../widgets/states.dart';
import '../../widgets/story_card.dart';
import '../stories/story_providers.dart';

/// Saved tab (PRD 16.4): saved list, unsave, empty state.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedStoriesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Saved')),
      body: saved.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(onRetry: () => ref.invalidate(savedStoriesProvider)),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.bookmark_border,
              title: 'No saved stories',
              message: 'Tap the bookmark on any story to read it later.',
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
