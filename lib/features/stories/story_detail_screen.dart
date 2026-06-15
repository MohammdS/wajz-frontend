import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/category_chip.dart';
import '../../widgets/confidence_badge.dart';
import '../../widgets/save_button.dart';
import '../../widgets/source_comparison_row.dart';
import '../../widgets/states.dart';
import '../../widgets/story_section.dart';
import 'opened_stories_provider.dart';
import 'story_providers.dart';

/// Story detail (PRD 10.1): headline, status, sources, what happened,
/// why it matters, key facts, what is still unclear, source comparison,
/// original source links. Every story must show its sources.
class StoryDetailScreen extends ConsumerStatefulWidget {
  const StoryDetailScreen({super.key, required this.storyId});

  final String storyId;

  @override
  ConsumerState<StoryDetailScreen> createState() => _StoryDetailScreenState();
}

class _StoryDetailScreenState extends ConsumerState<StoryDetailScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref
          .read(openedStoriesProvider.notifier)
          .markOpened(widget.storyId)
          .catchError((_) {}),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(storyDetailProvider(widget.storyId));
    return Scaffold(
      appBar: AppBar(
        actions: [
          SaveButton(storyId: widget.storyId),
          const SizedBox(width: WajzSpacing.sm),
        ],
      ),
      body: detail.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          onRetry: () => ref.invalidate(storyDetailProvider(widget.storyId)),
        ),
        data: (story) => _StoryDetailBody(story: story),
      ),
    );
  }
}

class _StoryDetailBody extends StatelessWidget {
  const _StoryDetailBody({required this.story});

  final StoryDetail story;

  Future<void> _openSource(BuildContext context, String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.openLinkError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(WajzSpacing.md),
      children: [
        if (story.category != null) CategoryChip(category: story.category!),
        const SizedBox(height: WajzSpacing.sm),
        Text(
          story.headline,
          style: wajzDisplayFont(
            Localizations.localeOf(context),
            textStyle: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ),
        const SizedBox(height: WajzSpacing.md),
        Wrap(
          spacing: WajzSpacing.sm,
          runSpacing: WajzSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConfidenceBadge(
              label: story.confidenceLabel,
              display: story.confidenceDisplay,
            ),
            Text(
              context.l10n.sources(
                story.sources.map((s) => s.name).toSet().join(', '),
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Text(
              context.l10n.updated(context.l10n.timeAgo(story.lastUpdatedAt)),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: WajzSpacing.lg),
          child: Container(
            height: 3,
            width: 48,
            decoration: BoxDecoration(
              gradient: context.brand.accentGradient,
              borderRadius: BorderRadius.circular(WajzRadius.pill),
            ),
          ),
        ),
        if (_has(story.whatHappened))
          StorySection(
            title: context.l10n.whatHappened,
            child: Text(story.whatHappened!, style: theme.textTheme.bodyMedium),
          ),
        if (_has(story.whyItMatters))
          StorySection(
            title: context.l10n.whyItMatters,
            child: Text(story.whyItMatters!, style: theme.textTheme.bodyMedium),
          ),
        if (story.keyFacts.isNotEmpty)
          StorySection(
            title: context.l10n.keyFacts,
            child: BulletList(items: story.keyFacts),
          ),
        if (story.unclearPoints.isNotEmpty)
          StorySection(
            title: context.l10n.stillUnclear,
            child: BulletList(items: story.unclearPoints),
          ),
        if (story.sourceComparison.isNotEmpty)
          StorySection(
            title: context.l10n.sourceComparison,
            child: Column(
              children: [
                for (final comparison in story.sourceComparison)
                  SourceComparisonRow(comparison: comparison),
              ],
            ),
          ),
        StorySection(
          title: context.l10n.readFullArticleOn,
          child: Column(
            children: [
              for (final source in story.sources)
                Padding(
                  padding: const EdgeInsets.only(bottom: WajzSpacing.sm),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      alignment: AlignmentDirectional.centerStart,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _openSource(context, source.url),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            source.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.open_in_new, size: 16),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: WajzSpacing.xl),
      ],
    );
  }

  bool _has(String? value) => value != null && value.trim().isNotEmpty;
}
