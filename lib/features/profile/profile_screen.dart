import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  static const _languages = [
    ('en', 'English'),
    ('ar', 'العربية'),
    ('he', 'עברית'),
  ];
  static const _lengths = [
    ('5_minutes', '5 minutes'),
    ('10_minutes', '10 minutes'),
    ('20_minutes', '20 minutes'),
  ];
  static const _levels = [
    ('brief', 'Brief'),
    ('standard', 'Standard'),
    ('beginner_friendly', 'Beginner-friendly'),
  ];
  static const _notifications = [
    ('none', 'No notifications'),
    ('daily_morning', 'Daily morning briefing'),
    ('daily_evening', 'Daily evening briefing'),
    ('major_confirmed_only', 'Major confirmed stories only'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(preferencesProvider);
    final categories = ref.watch(categoriesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: prefsAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(onRetry: () => ref.invalidate(preferencesProvider)),
        data: (prefs) {
          Future<void> save(Preferences updated) =>
              ref.read(preferencesProvider.notifier).save(updated);

          return ListView(
            padding: const EdgeInsets.all(WajzSpacing.md),
            children: [
              _SectionTitle('Language'),
              Wrap(
                spacing: WajzSpacing.sm,
                children: [
                  for (final (code, name) in _languages)
                    PreferenceChip(
                      label: name,
                      selected: prefs.preferredLanguage == code,
                      onTap: () => save(prefs.copyWith(preferredLanguage: code)),
                    ),
                ],
              ),
              _SectionTitle('Topics'),
              Wrap(
                spacing: WajzSpacing.sm,
                runSpacing: WajzSpacing.sm,
                children: [
                  for (final category
                      in categories.value?.categories ?? prefs.topics)
                    PreferenceChip(
                      label: category,
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
              _SectionTitle('Regions'),
              Wrap(
                spacing: WajzSpacing.sm,
                runSpacing: WajzSpacing.sm,
                children: [
                  for (final region in categories.value?.regions ?? prefs.regions)
                    PreferenceChip(
                      label: region,
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
              _SectionTitle('Briefing length'),
              for (final (value, label) in _lengths)
                SelectableTile(
                  title: label,
                  selected: prefs.briefingLength == value,
                  onTap: () => save(prefs.copyWith(briefingLength: value)),
                ),
              _SectionTitle('Explanation level'),
              for (final (value, label) in _levels)
                SelectableTile(
                  title: label,
                  selected: prefs.explanationLevel == value,
                  onTap: () => save(prefs.copyWith(explanationLevel: value)),
                ),
              _SectionTitle('Notifications'),
              for (final (value, label) in _notifications)
                SelectableTile(
                  title: label,
                  selected: prefs.notificationPreference == value,
                  onTap: () => save(prefs.copyWith(notificationPreference: value)),
                ),
              const SizedBox(height: WajzSpacing.lg),
              const Divider(),
              const SizedBox(height: WajzSpacing.sm),
              OutlinedButton.icon(
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Sign out'),
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
                  'Wajz 0.1.0 — Stay informed in minutes.',
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
