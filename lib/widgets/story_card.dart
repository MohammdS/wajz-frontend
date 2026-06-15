import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/app_localizations.dart';
import '../core/models/models.dart';
import '../core/theme/app_theme.dart';
import 'category_chip.dart';
import 'confidence_badge.dart';
import 'save_button.dart';

/// Story card (PRD 10.1): category, headline, 2-3 line summary, source count,
/// confidence label, updated time, save button. Editorial,
/// text-first — with an optional cover image when one is available.
class StoryCard extends StatelessWidget {
  const StoryCard({super.key, required this.story, this.onOpen});

  final StoryListItem story;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = story.imageUrl != null && story.imageUrl!.isNotEmpty;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(WajzRadius.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: wajzCardShadow(theme.brightness),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(WajzRadius.lg),
          onTap: () {
            onOpen?.call();
            context.push('/story/${story.id}');
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasImage) _Cover(url: story.imageUrl!),
              Padding(
                padding: const EdgeInsets.all(WajzSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (story.category != null)
                          Flexible(
                            child: CategoryChip(category: story.category!),
                          ),
                        const Spacer(),
                        SizedBox(
                          height: 32,
                          width: 32,
                          child: FittedBox(
                            child: SaveButton(storyId: story.id),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: WajzSpacing.xs),
                    Text(
                      story.headline,
                      style: wajzDisplayFont(
                        Localizations.localeOf(context),
                        textStyle: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                      ),
                    ),
                    if (story.summary != null && story.summary!.isNotEmpty) ...[
                      const SizedBox(height: WajzSpacing.sm),
                      Text(
                        story.summary!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: WajzSpacing.md),
                    _MetaRow(
                      label: story.confidenceLabel,
                      display: story.confidenceDisplay,
                      sourceText: context.l10n.sourceCount(story.sourceCount),
                      time: context.l10n.timeAgo(story.lastUpdatedAt),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.display,
    required this.sourceText,
    required this.time,
  });

  final String label;
  final String display;
  final String sourceText;
  final String time;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Wrap(
      spacing: WajzSpacing.sm,
      runSpacing: WajzSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConfidenceBadge(label: label, display: display),
        Text(sourceText, style: meta),
        Text('·', style: meta),
        Text(time, style: meta),
      ],
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(WajzRadius.lg),
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : _placeholder(theme),
          errorBuilder: (context, error, stack) => _placeholder(theme),
        ),
      ),
    );
  }

  Widget _placeholder(ThemeData theme) => Container(
    color: theme.colorScheme.surfaceContainerHighest,
    alignment: Alignment.center,
    child: Icon(
      Icons.photo_outlined,
      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
    ),
  );
}
