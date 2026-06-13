import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/app_localizations.dart';
import '../features/stories/story_providers.dart';

class SaveButton extends ConsumerWidget {
  const SaveButton({super.key, required this.storyId});

  final String storyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedIdsProvider).contains(storyId);
    return IconButton(
      icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
      color: saved ? Theme.of(context).colorScheme.primary : null,
      tooltip: saved ? context.l10n.removeFromSaved : context.l10n.saveForLater,
      onPressed: () async {
        try {
          await ref.read(savedIdsProvider.notifier).toggle(storyId);
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
