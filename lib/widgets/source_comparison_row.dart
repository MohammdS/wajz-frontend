import 'package:flutter/material.dart';

import '../core/models/models.dart';
import '../core/theme/app_theme.dart';

class SourceComparisonRow extends StatelessWidget {
  const SourceComparisonRow({super.key, required this.comparison});

  final SourceComparison comparison;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: WajzSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              comparison.source,
              style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: WajzSpacing.sm),
          Expanded(
            child: Text(
              comparison.framing,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
