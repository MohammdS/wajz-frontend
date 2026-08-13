import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/desktop/desktop_layout.dart';
import '../../widgets/states.dart';
import 'ongoing_providers.dart';
import 'ongoing_topic_card.dart';

class OngoingScreen extends ConsumerWidget {
  const OngoingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final desktop = isDesktopWidth(context);
    final topics = ref.watch(ongoingTopicsProvider);
    return Scaffold(
      appBar: desktop ? null : AppBar(title: Text(context.l10n.ongoing)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (desktop)
            DesktopPaneHeader(
              title: context.l10n.ongoing,
              subtitle: context.l10n.ongoingHelp,
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(
                WajzSpacing.md,
                WajzSpacing.xs,
                WajzSpacing.md,
                WajzSpacing.md,
              ),
              child: Text(
                context.l10n.ongoingHelp,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Expanded(
            child: topics.when(
              loading: () => const LoadingState(),
              error: (_, _) => ErrorState(
                onRetry: () => ref.invalidate(ongoingTopicsProvider),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () => _refresh(ref),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: MediaQuery.sizeOf(context).height * 0.55,
                          child: EmptyState(
                            icon: Icons.radar,
                            title: context.l10n.nothingHere,
                            message: context.l10n.noOngoingTopics,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () => _refresh(ref),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth >= 1180
                          ? 3
                          : constraints.maxWidth >= 680
                          ? 2
                          : 1;
                      return GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          desktop ? WajzSpacing.lg : WajzSpacing.md,
                          WajzSpacing.sm,
                          desktop ? WajzSpacing.lg : WajzSpacing.md,
                          WajzSpacing.xl,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: WajzSpacing.md,
                          mainAxisSpacing: WajzSpacing.md,
                          mainAxisExtent: 410,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) =>
                            OngoingTopicCard(topic: items[index]),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(ongoingTopicsProvider);
    await ref.read(ongoingTopicsProvider.future);
  }
}
