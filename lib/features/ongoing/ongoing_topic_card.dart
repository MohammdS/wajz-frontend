import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/category_chip.dart';

class OngoingTopicCard extends StatelessWidget {
  const OngoingTopicCard({super.key, required this.topic, this.onTap});

  final OngoingTopic topic;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
          onTap: onTap ?? () => context.go('/ongoing/${topic.id}'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _TopicCover(topic: topic),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(WajzSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: WajzSpacing.sm,
                        runSpacing: WajzSpacing.xs,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _OngoingBadge(label: context.l10n.ongoingBadge),
                          if (topic.category != null)
                            CategoryChip(category: topic.category!),
                        ],
                      ),
                      const SizedBox(height: WajzSpacing.sm),
                      Text(
                        topic.title,
                        style: wajzDisplayFont(
                          Localizations.localeOf(context),
                          textStyle: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                          ),
                        ),
                      ),
                      const SizedBox(height: WajzSpacing.sm),
                      Text(
                        topic.description,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(height: WajzSpacing.md),
                      Row(
                        children: [
                          Icon(
                            Icons.library_books_outlined,
                            size: 17,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: WajzSpacing.xs),
                          Text(
                            context.l10n.topicStories(topic.storyCount),
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(width: WajzSpacing.sm),
                          Expanded(
                            child: Text(
                              context.l10n.updated(
                                context.l10n.timeAgo(topic.lastUpdatedAt),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopicCover extends StatelessWidget {
  const _TopicCover({required this.topic});

  final OngoingTopic topic;

  @override
  Widget build(BuildContext context) {
    final imageUrl = topic.imageUrl;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(WajzRadius.lg),
      ),
      child: SizedBox(
        height: 150,
        child: imageUrl != null && imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _TopicFallback(topic: topic),
              )
            : _TopicFallback(topic: topic),
      ),
    );
  }
}

class _TopicFallback extends StatelessWidget {
  const _TopicFallback({required this.topic});

  final OngoingTopic topic;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: context.brand.brandGradient),
      child: Center(
        child: Icon(
          _categoryIcon(topic.category),
          size: 54,
          color: context.brand.onBrandMuted,
          semanticLabel: topic.category,
        ),
      ),
    );
  }
}

class _OngoingBadge extends StatelessWidget {
  const _OngoingBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: WajzColors.amber.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(WajzRadius.pill),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: WajzColors.confidenceColor('developing', theme.brightness),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

IconData _categoryIcon(String? category) => switch (category) {
  'Sports' => Icons.sports_soccer,
  'Technology' => Icons.memory,
  'Economy' => Icons.trending_up,
  'Science' => Icons.science_outlined,
  'Health' => Icons.health_and_safety_outlined,
  'Politics' => Icons.account_balance_outlined,
  'Culture' => Icons.palette_outlined,
  'Middle East' || 'Local / Regional' => Icons.public,
  _ => Icons.radar,
};
