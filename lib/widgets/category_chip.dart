import 'package:flutter/material.dart';

import '../core/l10n/app_localizations.dart';

class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      context.l10n.isArabic
          ? context.l10n.category(category)
          : category.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w700,
        letterSpacing: context.l10n.isArabic ? 0 : 1.1,
      ),
    );
  }
}
