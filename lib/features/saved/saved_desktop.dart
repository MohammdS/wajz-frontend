import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/desktop/desktop_layout.dart';
import '../../widgets/desktop/desktop_story_tile.dart';
import '../../widgets/states.dart';
import '../stories/opened_stories_provider.dart';
import '../stories/story_providers.dart';

/// Saved, desktop layout: saved list as master pane, reading pane alongside.
class DesktopSavedView extends ConsumerStatefulWidget {
  const DesktopSavedView({super.key});

  @override
  ConsumerState<DesktopSavedView> createState() => _DesktopSavedViewState();
}

class _DesktopSavedViewState extends ConsumerState<DesktopSavedView> {
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
          DesktopPaneHeader(title: context.l10n.saved),
          Expanded(
            child: _DesktopSignInRequired(
              title: 'Sign in to view saved stories',
              message: 'Saved stories are tied to your account.',
              from: '/saved',
            ),
          ),
        ],
      );
    }

    final saved = ref.watch(savedStoriesProvider);
    final opened = ref.watch(openedStoriesProvider).ids;

    final master = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesktopPaneHeader(title: context.l10n.saved),
        Expanded(
          child: saved.when(
            loading: () => const LoadingState(),
            error: (e, _) =>
                ErrorState(onRetry: () => ref.invalidate(savedStoriesProvider)),
            data: (items) {
              if (items.isEmpty) {
                return EmptyState(
                  icon: Icons.bookmark_border,
                  title: context.l10n.noSavedStories,
                  message: context.l10n.saveStoryHelp,
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(savedStoriesProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    WajzSpacing.md,
                    0,
                    WajzSpacing.md,
                    WajzSpacing.xl,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final story = items[index].story;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: DesktopStoryTile(
                        story: story,
                        selected: _selected == story.id,
                        opened: opened.contains(story.id),
                        onTap: () => setState(() => _selected = story.id),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );

    return DesktopMasterDetail(
      master: master,
      selectedStoryId: _selected,
      onCloseDetail: () => setState(() => _selected = null),
    );
  }
}

class _DesktopSignInRequired extends StatelessWidget {
  const _DesktopSignInRequired({
    required this.title,
    required this.message,
    required this.from,
  });

  final String title;
  final String message;
  final String from;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WajzSpacing.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: WajzSpacing.md),
              Text(
                title,
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: WajzSpacing.sm),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: WajzSpacing.md),
              FilledButton(
                onPressed: () => context.go(
                  Uri(
                    path: '/login',
                    queryParameters: {'from': from},
                  ).toString(),
                ),
                child: Text(context.l10n.loginTitle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
