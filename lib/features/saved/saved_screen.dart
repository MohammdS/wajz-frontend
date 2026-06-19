import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/desktop/desktop_layout.dart';
import '../../widgets/states.dart';
import '../../widgets/story_card.dart';
import '../stories/story_providers.dart';
import 'saved_desktop.dart';

/// Saved tab (PRD 16.4): saved list, unsave, empty state.
class SavedScreen extends ConsumerWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isDesktopWidth(context)) return const DesktopSavedView();

    final authenticated = ref.watch(
      sessionProvider.select((session) => session.authenticated),
    );
    if (!authenticated) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.saved)),
        body: const _SignInRequired(
          title: 'Sign in to view saved stories',
          message: 'Saved stories are tied to your account.',
          from: '/saved',
        ),
      );
    }

    final saved = ref.watch(savedStoriesProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.saved)),
      body: saved.when(
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
            child: ListView.separated(
              padding: const EdgeInsets.all(WajzSpacing.md),
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: WajzSpacing.md),
              itemBuilder: (context, index) =>
                  StoryCard(story: items[index].story),
            ),
          );
        },
      ),
    );
  }
}

class _SignInRequired extends StatelessWidget {
  const _SignInRequired({
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
                Uri(path: '/login', queryParameters: {'from': from}).toString(),
              ),
              child: Text(context.l10n.loginTitle),
            ),
          ],
        ),
      ),
    );
  }
}
