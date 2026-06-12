import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class BriefingProgress extends StatelessWidget {
  const BriefingProgress({super.key, required this.read, required this.total});

  final int read;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = total == 0 ? 0.0 : (read / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: theme.colorScheme.outlineVariant,
          ),
        ),
        const SizedBox(height: WajzSpacing.xs),
        Text(
          read >= total && total > 0 ? 'Briefing complete' : '$read of $total stories read',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }
}
