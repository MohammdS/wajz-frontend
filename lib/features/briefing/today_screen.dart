import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/arabesque.dart';
import '../../widgets/desktop/desktop_layout.dart';
import '../../widgets/states.dart';
import '../../widgets/story_card.dart';
import '../../widgets/wajz_logo.dart';
import '../stories/opened_stories_provider.dart';
import 'briefing_provider.dart';
import 'today_desktop.dart';

/// Today tab (PRD 16.2): greeting, briefing summary, progress, finite story
/// list ending in "You are caught up." No infinite feed.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isDesktopWidth(context)) return const DesktopTodayView();

    final authenticated = ref.watch(
      sessionProvider.select((session) => session.authenticated),
    );
    if (!authenticated) {
      return Scaffold(
        appBar: AppBar(
          titleSpacing: WajzSpacing.md,
          title: const WajzLogo(markSize: 30, fontSize: 22, showLatin: false),
        ),
        body: SignInRequiredState(
          title: context.l10n.briefingSignInTitle,
          message: context.l10n.briefingSignInMessage,
          from: '/today',
        ),
      );
    }

    final briefing = ref.watch(briefingProvider);
    final locallyOpenedIds = ref.watch(openedStoriesProvider).ids;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: WajzSpacing.md,
        title: const WajzLogo(markSize: 30, fontSize: 22, showLatin: false),
      ),
      body: briefing.when(
        loading: () => const LoadingState(),
        error: (e, _) =>
            ErrorState(onRetry: () => ref.invalidate(briefingProvider)),
        data: (data) {
          final openedIds = {...data.openedStoryIds, ...locallyOpenedIds};
          final read = data.stories
              .where((s) => openedIds.contains(s.id))
              .length;
          final remainingStories = data.stories
              .where((story) => !openedIds.contains(story.id))
              .toList();

          if (data.stories.isEmpty) {
            return EmptyState(
              icon: Icons.wb_twilight_outlined,
              title: context.l10n.noBriefing,
              message: context.l10n.gatheringStories,
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(briefingProvider),
            child: ListView(
              padding: const EdgeInsets.all(WajzSpacing.md),
              children: [
                _BriefingHero(
                  greeting: context.l10n.greeting(
                    DateTime.now(),
                    name: data.displayName,
                  ),
                  summary: context.l10n.briefingReady(
                    data.estimatedReadTimeMinutes,
                    data.stories.length,
                  ),
                  read: read,
                  total: data.stories.length,
                ),
                const SizedBox(height: WajzSpacing.lg),
                if (remainingStories.isNotEmpty) ...[
                  Row(
                    children: [
                      Text(
                        context.l10n.today,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(width: WajzSpacing.sm),
                      Expanded(
                        child: Divider(color: theme.colorScheme.outlineVariant),
                      ),
                    ],
                  ),
                  const SizedBox(height: WajzSpacing.md),
                  for (final story in remainingStories)
                    Padding(
                      padding: const EdgeInsets.only(bottom: WajzSpacing.md),
                      child: StoryCard(
                        story: story,
                        onOpen: () {
                          ref
                              .read(openedStoriesProvider.notifier)
                              .markOpened(story.id)
                              .catchError((_) {});
                        },
                      ),
                    ),
                ] else ...[
                  _CaughtUpCard(message: context.l10n.caughtUp),
                  const SizedBox(height: WajzSpacing.xl),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BriefingHero extends StatelessWidget {
  const _BriefingHero({
    required this.greeting,
    required this.summary,
    required this.read,
    required this.total,
  });

  final String greeting;
  final String summary;
  final int read;
  final int total;

  @override
  Widget build(BuildContext context) {
    final progress = total == 0 ? 0.0 : (read / total).clamp(0.0, 1.0);
    final done = read >= total && total > 0;
    final brand = context.brand;
    return WajzHeroPanel(
      padding: const EdgeInsets.all(WajzSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: wajzDisplayFont(
              Localizations.localeOf(context),
              textStyle: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: brand.onBrand,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: WajzSpacing.sm),
          Text(
            summary,
            style: TextStyle(
              color: brand.onBrandMuted,
              height: 1.5,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: WajzSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(WajzRadius.pill),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: brand.onBrand.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(brand.accentBright),
            ),
          ),
          const SizedBox(height: WajzSpacing.sm),
          Row(
            children: [
              Icon(
                done ? Icons.check_circle_rounded : Icons.auto_stories_outlined,
                size: 16,
                color: brand.accentBright,
              ),
              const SizedBox(width: WajzSpacing.xs),
              Text(
                done
                    ? context.l10n.briefingComplete
                    : context.l10n.briefingProgress(read, total),
                style: TextStyle(color: brand.onBrandFaint, fontSize: 12.5),
              ),
            ],
          ),
        ],
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
        borderRadius: BorderRadius.circular(WajzRadius.lg),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          const WajzLogoMark(size: 34),
          const SizedBox(height: WajzSpacing.sm),
          Text(
            message,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: WajzSpacing.xs),
          Text(
            context.l10n.caughtUpDetail,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
