import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/arabesque.dart';
import '../../widgets/desktop/desktop_layout.dart';
import '../../widgets/desktop/desktop_story_tile.dart';
import '../../widgets/states.dart';
import '../../widgets/wajz_logo.dart';
import '../stories/opened_stories_provider.dart';
import 'briefing_provider.dart';

/// Today, desktop layout: the briefing summary + story list as a master pane,
/// with the selected story open in the reading pane beside it.
class DesktopTodayView extends ConsumerStatefulWidget {
  const DesktopTodayView({super.key});

  @override
  ConsumerState<DesktopTodayView> createState() => _DesktopTodayViewState();
}

class _DesktopTodayViewState extends ConsumerState<DesktopTodayView> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final authenticated = ref.watch(
      sessionProvider.select((session) => session.authenticated),
    );
    if (!authenticated) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DesktopPaneHeader(title: context.l10n.today),
          Expanded(
            child: SignInRequiredState(
              title: context.l10n.briefingSignInTitle,
              message: context.l10n.briefingSignInMessage,
              from: '/today',
            ),
          ),
        ],
      );
    }

    final briefing = ref.watch(briefingProvider);
    final locallyOpened = ref.watch(openedStoriesProvider).ids;

    final master = briefing.when(
      loading: () => const LoadingState(),
      error: (e, _) =>
          ErrorState(onRetry: () => ref.invalidate(briefingProvider)),
      data: (data) {
        if (data.stories.isEmpty) {
          return EmptyState(
            icon: Icons.wb_twilight_outlined,
            title: context.l10n.noBriefing,
            message: context.l10n.gatheringStories,
          );
        }
        final openedIds = {...data.openedStoryIds, ...locallyOpened};
        final read = data.stories.where((s) => openedIds.contains(s.id)).length;

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(briefingProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              WajzSpacing.md,
              WajzSpacing.md,
              WajzSpacing.md,
              WajzSpacing.xl,
            ),
            children: [
              _BriefingHeader(
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
              const SizedBox(height: WajzSpacing.md),
              for (final story in data.stories)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: DesktopStoryTile(
                    story: story,
                    selected: _selected == story.id,
                    opened: openedIds.contains(story.id),
                    onTap: () => _select(story.id),
                  ),
                ),
            ],
          ),
        );
      },
    );

    return DesktopMasterDetail(
      master: master,
      selectedStoryId: _selected,
      onCloseDetail: () => setState(() => _selected = null),
    );
  }

  void _select(String id) {
    setState(() => _selected = id);
    ref.read(openedStoriesProvider.notifier).markOpened(id).catchError((_) {});
  }
}

class _BriefingHeader extends StatelessWidget {
  const _BriefingHeader({
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
          Row(
            children: [
              const WajzLogoMark(size: 26),
              const SizedBox(width: WajzSpacing.sm),
              Expanded(
                child: Text(
                  greeting,
                  style: wajzDisplayFont(
                    Localizations.localeOf(context),
                    textStyle: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: brand.onBrand,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: WajzSpacing.sm),
          Text(
            summary,
            style: TextStyle(
              color: brand.onBrandMuted,
              height: 1.5,
              fontSize: 13.5,
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
