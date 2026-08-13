import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/app_localizations.dart';
import '../core/providers.dart';
import '../features/stories/story_providers.dart';

class SaveButton extends ConsumerWidget {
  const SaveButton({super.key, required this.storyId});

  final String storyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authenticated = ref.watch(
      sessionProvider.select((session) => session.authenticated),
    );
    final saved = ref.watch(savedIdsProvider).contains(storyId);
    return IconButton(
      icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
      color: saved ? Theme.of(context).colorScheme.primary : null,
      tooltip: saved ? context.l10n.removeFromSaved : context.l10n.saveForLater,
      onPressed: () async {
        if (!authenticated) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.signInToSave),
              action: SnackBarAction(
                label: context.l10n.loginTitle,
                onPressed: () => context.go(
                  Uri(
                    path: '/login',
                    queryParameters: {'from': '/story/$storyId'},
                  ).toString(),
                ),
              ),
            ),
          );
          return;
        }
        try {
          await ref.read(savedIdsProvider.notifier).toggle(storyId);
          await ref
              .read(analyticsServiceProvider)
              .track(
                'story_saved',
                entityType: 'story',
                entityId: storyId,
                properties: {'action': saved ? 'unsaved' : 'saved'},
              );
          ref.invalidate(savedStoriesProvider);
        } catch (_) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.updateSavedError)),
            );
          }
        }
      },
    );
  }
}
