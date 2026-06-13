import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/preference_chip.dart';
import '../../widgets/states.dart';
import '../../widgets/story_card.dart';
import '../stories/story_providers.dart';

/// Explore tab (PRD 16.3): controlled browsing by category - a limited list
/// per category, not an infinite feed.
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);
    final stories = ref.watch(exploreStoriesProvider(_category));

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.explore)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    onTap: () => setState(() => _category = null),
                  ),
                ),
                for (final category
                    in categories.value?.categories ?? const <String>[])
                  Padding(
                    padding: const EdgeInsets.only(right: WajzSpacing.sm),
                    child: PreferenceChip(
                      label: context.l10n.category(category),
                      selected: _category == category,
                      onTap: () => setState(() => _category = category),
                    ),
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
                  child: ListView.separated(
                    padding: const EdgeInsets.all(WajzSpacing.md),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: WajzSpacing.md),
                    itemBuilder: (context, index) => StoryCard(story: items[index]),
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
