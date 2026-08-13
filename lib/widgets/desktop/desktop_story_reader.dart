import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/models.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../features/stories/opened_stories_provider.dart';
import '../../features/stories/story_providers.dart';
import '../category_chip.dart';
import '../confidence_badge.dart';
import '../save_button.dart';
import '../source_comparison_row.dart';
import '../states.dart';
import '../story_section.dart';

/// The desktop reading pane: the full story detail rendered inside a pane
/// (not a route). Reuses [storyDetailProvider] and marks the story opened, so
/// the briefing progress and the master list stay in sync.
class DesktopStoryReader extends ConsumerStatefulWidget {
  const DesktopStoryReader({super.key, required this.storyId, this.onClose});

  final String storyId;

  /// When non-null the pane shows a "back to list" button (collapsed layout).
  final VoidCallback? onClose;

  @override
  ConsumerState<DesktopStoryReader> createState() => _DesktopStoryReaderState();
}

class _DesktopStoryReaderState extends ConsumerState<DesktopStoryReader> {
  @override
  void initState() {
    super.initState();
    _markOpened();
  }

  @override
  void didUpdateWidget(DesktopStoryReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.storyId != widget.storyId) _markOpened();
  }

  void _markOpened() {
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
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Pane action bar.
        Padding(
          padding: const EdgeInsets.fromLTRB(
            WajzSpacing.sm,
            WajzSpacing.sm,
            WajzSpacing.sm,
            0,
          ),
          child: Row(
            children: [
              if (widget.onClose != null)
                TextButton.icon(
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: Text(context.l10n.backToList),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              const Spacer(),
              SaveButton(storyId: widget.storyId),
              const SizedBox(width: WajzSpacing.xs),
            ],
          ),
        ),
        Expanded(
          child: detail.when(
            loading: () => const LoadingState(),
            error: (e, _) => ErrorState(
              onRetry: () =>
                  ref.invalidate(storyDetailProvider(widget.storyId)),
            ),
            data: (story) => _ReaderBody(story: story),
          ),
        ),
      ],
    );
  }
}

class _ReaderBody extends ConsumerWidget {
  const _ReaderBody({required this.story});

  final StoryDetail story;

  Future<void> _openSource(
    BuildContext context,
    WidgetRef ref,
    String url,
  ) async {
    await ref
        .read(analyticsServiceProvider)
        .track(
          'source_link_clicked',
          entityType: 'story',
          entityId: story.id,
          properties: {
            if (story.category != null) 'category': story.category!,
            'language': story.contentLanguage,
          },
        );
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

  bool _has(String? value) => value != null && value.trim().isNotEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scrollbar(
      child: ListView(
        primary: true,
        padding: const EdgeInsets.fromLTRB(
          WajzSpacing.xl,
          WajzSpacing.sm,
          WajzSpacing.xl,
          WajzSpacing.xxl,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kReaderContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (story.category != null)
                    CategoryChip(category: story.category!),
                  const SizedBox(height: WajzSpacing.sm),
                  Text(
                    story.headline,
                    style: wajzDisplayFont(
                      Localizations.localeOf(context),
                      textStyle: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.18,
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
                      Chip(
                        avatar: const Icon(
                          Icons.auto_awesome_outlined,
                          size: 15,
                        ),
                        label: Text(context.l10n.aiGeneratedSummary),
                        visualDensity: VisualDensity.compact,
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
                        context.l10n.updated(
                          context.l10n.timeAgo(story.lastUpdatedAt),
                        ),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: WajzSpacing.lg,
                    ),
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
                      child: Text(
                        story.whatHappened!,
                        style: theme.textTheme.bodyLarge,
                      ),
                    ),
                  if (_has(story.whyItMatters))
                    StorySection(
                      title: context.l10n.whyItMatters,
                      child: Text(
                        story.whyItMatters!,
                        style: theme.textTheme.bodyLarge,
                      ),
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
                            padding: const EdgeInsets.only(
                              bottom: WajzSpacing.sm,
                            ),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                alignment: AlignmentDirectional.centerStart,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () =>
                                  _openSource(context, ref, source.url),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Comfortable reading measure inside the (potentially very wide) reader pane.
const double kReaderContentWidth = 680;
