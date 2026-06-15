import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../category_chip.dart';
import '../confidence_badge.dart';
import '../save_button.dart';

/// A compact, selectable story row for the desktop master list. Unlike the
/// mobile [StoryCard] it does not navigate — tapping selects it so the story
/// opens in the adjacent reading pane.
class DesktopStoryTile extends ConsumerWidget {
  const DesktopStoryTile({
    super.key,
    required this.story,
    required this.selected,
    required this.opened,
    required this.onTap,
  });

  final StoryListItem story;
  final bool selected;
  final bool opened;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasImage = story.imageUrl != null && story.imageUrl!.isNotEmpty;
    final accent = theme.colorScheme.primary;

    return Material(
      color: selected ? accent.withValues(alpha: 0.09) : Colors.transparent,
      borderRadius: BorderRadius.circular(WajzRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WajzRadius.md),
        hoverColor: theme.colorScheme.onSurface.withValues(alpha: 0.04),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(WajzRadius.md),
            border: Border.all(
              color: selected ? accent.withValues(alpha: 0.45) : Colors.transparent,
            ),
          ),
          padding: const EdgeInsets.all(WajzSpacing.sm + 2),
          child: Opacity(
            opacity: opened && !selected ? 0.62 : 1,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImage) ...[
                  _Thumb(url: story.imageUrl!),
                  const SizedBox(width: WajzSpacing.sm + 2),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (story.category != null)
                            Flexible(child: CategoryChip(category: story.category!)),
                          const Spacer(),
                          if (opened)
                            Padding(
                              padding: const EdgeInsets.only(right: 2),
                              child: Icon(
                                Icons.check_circle,
                                size: 15,
                                color: accent.withValues(alpha: 0.7),
                              ),
                            ),
                          SizedBox(
                            height: 30,
                            width: 30,
                            child: FittedBox(child: SaveButton(storyId: story.id)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        story.headline,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: wajzDisplayFont(
                          Localizations.localeOf(context),
                          textStyle: theme.textTheme.titleSmall?.copyWith(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: WajzSpacing.sm),
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
                            context.l10n.timeAgo(story.lastUpdatedAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget placeholder() => Container(
      color: theme.colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        Icons.photo_outlined,
        size: 18,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(WajzRadius.sm),
      child: SizedBox(
        width: 58,
        height: 58,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) =>
              progress == null ? child : placeholder(),
          errorBuilder: (context, error, stack) => placeholder(),
        ),
      ),
    );
  }
}
