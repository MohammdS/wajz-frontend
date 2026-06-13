import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/app_localizations.dart';
import '../core/models/models.dart';
import '../core/theme/app_theme.dart';
import 'category_chip.dart';
import 'confidence_badge.dart';
import 'save_button.dart';

/// Story card (PRD 10.1): category, headline, 2-3 line summary, source count
/// and names, confidence label, updated time, save button. Text-first.
class StoryCard extends StatelessWidget {
  const StoryCard({super.key, required this.story, this.onOpen});

  final StoryListItem story;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sourceText = story.sourceCount > 1
        ? context.l10n.moreSources(story.sources.first, story.sourceCount - 1)
        : (story.sources.isNotEmpty ? story.sources.first : context.l10n.unknownSource);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          onOpen?.call();
          context.push('/story/${story.id}');
        },
        child: Padding(
          padding: const EdgeInsets.all(WajzSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (story.category != null) CategoryChip(category: story.category!),
                  const Spacer(),
                  SizedBox(
                    height: 32,
                    width: 32,
                    child: FittedBox(child: SaveButton(storyId: story.id)),
                  ),
                ],
              ),
              const SizedBox(height: WajzSpacing.xs),
              Text(story.headline, style: theme.textTheme.titleMedium),
              if (story.summary != null && story.summary!.isNotEmpty) ...[
                const SizedBox(height: WajzSpacing.sm),
                Text(
                  story.summary!,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
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
                    context.l10n.sources(sourceText),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  Text(
                    context.l10n.timeAgo(story.lastUpdatedAt),
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
