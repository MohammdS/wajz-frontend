import 'package:flutter/material.dart';

import '../core/models/models.dart';
import '../core/theme/app_theme.dart';

/// One row of the "how sources framed it" comparison — the source on a teal
/// rail, its framing alongside.
class SourceComparisonRow extends StatelessWidget {
  const SourceComparisonRow({super.key, required this.comparison});

  final SourceComparison comparison;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: WajzSpacing.sm),
      padding: const EdgeInsets.all(WajzSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(WajzRadius.md),
        border: Border(
          left: BorderSide(color: theme.colorScheme.secondary, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comparison.source,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: WajzSpacing.xs),
          Text(
            comparison.framing,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
