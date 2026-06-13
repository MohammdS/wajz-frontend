import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/models.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/preference_chip.dart';
import '../../widgets/states.dart';
import '../onboarding/onboarding_screen.dart' show SelectableTile;
import '../preferences/preferences_provider.dart';

/// Profile tab (PRD 16.5): language, regions, topics, briefing length,
/// explanation level, notification preference, account/logout.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _languages = ['en', 'ar'];
  static const _lengths = ['5_minutes', '10_minutes', '20_minutes'];
  static const _levels = ['brief', 'standard', 'beginner_friendly'];
  static const _notifications = [
    'none',
    'daily_morning',
    'daily_evening',
    'major_confirmed_only',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(preferencesProvider);
    final categories = ref.watch(categoriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profile)),
      body: prefsAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(onRetry: () => ref.invalidate(preferencesProvider)),
        data: (prefs) {
          Future<void> save(Preferences updated) =>
              ref.read(preferencesProvider.notifier).save(updated);

          return ListView(
            padding: const EdgeInsets.all(WajzSpacing.md),
            children: [
              _SectionTitle(context.l10n.language),
              Wrap(
                spacing: WajzSpacing.sm,
                children: [
                  for (final code in _languages)
                    PreferenceChip(
                      label: context.l10n.languageName(code),
                      selected: prefs.preferredLanguage == code,
                      onTap: () {
                        ref.read(appLocaleProvider.notifier).setLanguage(code);
                        save(prefs.copyWith(preferredLanguage: code));
                      },
                    ),
                ],
              ),
              _SectionTitle(context.l10n.topics),
              Wrap(
                spacing: WajzSpacing.sm,
                runSpacing: WajzSpacing.sm,
                children: [
                  for (final category
                      in categories.value?.categories ?? prefs.topics)
                    PreferenceChip(
                      label: context.l10n.category(category),
                      selected: prefs.topics.contains(category),
                      onTap: () {
                        final topics = [...prefs.topics];
                        topics.contains(category)
                            ? topics.remove(category)
                            : topics.add(category);
                        save(prefs.copyWith(topics: topics));
                      },
                    ),
                ],
              ),
              _SectionTitle(context.l10n.regions),
              Wrap(
                spacing: WajzSpacing.sm,
                runSpacing: WajzSpacing.sm,
                children: [
                  for (final region in categories.value?.regions ?? prefs.regions)
                    PreferenceChip(
                      label: context.l10n.region(region),
                      selected: prefs.regions.contains(region),
                      onTap: () {
                        final regions = [...prefs.regions];
                        regions.contains(region)
                            ? regions.remove(region)
                            : regions.add(region);
                        save(prefs.copyWith(regions: regions));
                      },
                    ),
                ],
              ),
              _SectionTitle(context.l10n.briefingLength),
              for (final value in _lengths)
                SelectableTile(
                  title: context.l10n.briefingLengthLabel(value),
                  selected: prefs.briefingLength == value,
                  onTap: () => save(prefs.copyWith(briefingLength: value)),
                ),
              _SectionTitle(context.l10n.explanationLevel),
              for (final value in _levels)
                SelectableTile(
                  title: context.l10n.explanationLabel(value),
                  selected: prefs.explanationLevel == value,
                  onTap: () => save(prefs.copyWith(explanationLevel: value)),
                ),
              _SectionTitle(context.l10n.notifications),
              for (final value in _notifications)
                SelectableTile(
                  title: context.l10n.notificationLabel(value),
                  selected: prefs.notificationPreference == value,
                  onTap: () => save(prefs.copyWith(notificationPreference: value)),
                ),
              const SizedBox(height: WajzSpacing.lg),
              const Divider(),
              const SizedBox(height: WajzSpacing.sm),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout, size: 18),
                label: Text(context.l10n.signOut),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  foregroundColor: theme.colorScheme.error,
                ),
                onPressed: () async {
                  await ref.read(sessionProvider.notifier).signOut();
                  if (context.mounted) context.go('/');
                },
              ),
              const SizedBox(height: WajzSpacing.md),
              Center(
                child: Text(
                  context.l10n.versionTagline,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              const SizedBox(height: WajzSpacing.xl),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: WajzSpacing.lg, bottom: WajzSpacing.sm),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
