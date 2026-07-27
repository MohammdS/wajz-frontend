import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/models.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/desktop/desktop_layout.dart';
import '../../widgets/preference_chip.dart';
import '../../widgets/states.dart';
import '../../widgets/wajz_logo.dart';
import '../onboarding/onboarding_screen.dart' show SelectableTile;
import '../preferences/preferences_provider.dart';
import 'profile_desktop.dart';

/// Profile tab (PRD 16.5): language, regions, topics, briefing length,
/// account/logout. Adapts to a roomier centred layout on desktop.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isDesktopWidth(context)) return const DesktopProfileView();
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profile)),
      body: const ProfileSettingsList(),
    );
  }
}

/// The shared settings body, used by both the mobile screen and the desktop
/// profile view.
class ProfileSettingsList extends ConsumerWidget {
  const ProfileSettingsList({super.key, this.padding});

  static const _languages = ['en', 'ar'];
  static const _lengths = ['5_minutes', '10_minutes', '20_minutes'];

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authenticated = ref.watch(
      sessionProvider.select((session) => session.authenticated),
    );
    final theme = Theme.of(context);

    if (!authenticated) {
      final language = ref.watch(appLocaleProvider).languageCode;
      return ListView(
        padding: padding ?? const EdgeInsets.all(WajzSpacing.md),
        children: [
          _SectionTitle(context.l10n.appearance),
          const _ThemePicker(),
          _SectionTitle(context.l10n.language),
          Wrap(
            spacing: WajzSpacing.sm,
            children: [
              for (final code in _languages)
                PreferenceChip(
                  label: context.l10n.languageName(code),
                  selected: language == code,
                  onTap: () =>
                      ref.read(appLocaleProvider.notifier).setLanguage(code),
                ),
            ],
          ),
          const SizedBox(height: WajzSpacing.xl),
          Container(
            padding: const EdgeInsets.all(WajzSpacing.lg),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(WajzRadius.lg),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 36,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: WajzSpacing.sm),
                Text(
                  'Sign in for your daily briefing',
                  style: theme.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: WajzSpacing.xs),
                Text(
                  'Briefing preferences, saved stories, and reading progress are account features.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: WajzSpacing.md),
                FilledButton(
                  onPressed: () => context.go(
                    Uri(
                      path: '/login',
                      queryParameters: {'from': '/profile'},
                    ).toString(),
                  ),
                  child: Text(context.l10n.loginTitle),
                ),
              ],
            ),
          ),
          const SizedBox(height: WajzSpacing.xl),
        ],
      );
    }

    final prefsAsync = ref.watch(preferencesProvider);
    final categories = ref.watch(categoriesProvider);

    return prefsAsync.when(
      loading: () => const LoadingState(),
      error: (e, _) =>
          ErrorState(onRetry: () => ref.invalidate(preferencesProvider)),
      data: (prefs) {
        Future<void> save(Preferences updated) =>
            ref.read(preferencesProvider.notifier).save(updated);

        return ListView(
          padding: padding ?? const EdgeInsets.all(WajzSpacing.md),
          children: [
            _SectionTitle(context.l10n.appearance),
            const _ThemePicker(),
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
            const SizedBox(height: WajzSpacing.lg),
            Center(
              child: Column(
                children: [
                  const WajzLogoMark(size: 30),
                  const SizedBox(height: WajzSpacing.sm),
                  Text(
                    context.l10n.versionTagline,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: WajzSpacing.xl),
          ],
        );
      },
    );
  }
}

/// Four selectable colour themes shown as live brand previews.
class _ThemePicker extends ConsumerWidget {
  const _ThemePicker();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(appThemeProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = WajzSpacing.sm;
        // Two per row, but allow more on wide profile columns.
        final perRow = constraints.maxWidth >= 520 ? 4 : 2;
        final cardWidth =
            (constraints.maxWidth - spacing * (perRow - 1)) / perRow;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final palette in wajzPalettes)
              SizedBox(
                width: cardWidth,
                child: _ThemeCard(
                  palette: palette,
                  selected: palette.id == selected.id,
                  onTap: () =>
                      ref.read(appThemeProvider.notifier).setPalette(palette),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.palette,
    required this.selected,
    required this.onTap,
  });

  final WajzPalette palette;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      selected: selected,
      button: true,
      label: context.l10n.themeName(palette.id),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(WajzRadius.lg),
            border: Border.all(
              color: selected
                  ? palette.accentBright
                  : theme.colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(3),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Live brand-gradient swatch with the accent mark.
              Container(
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(WajzRadius.md),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [palette.brandTop, palette.brandDeep],
                  ),
                ),
                child: Stack(
                  children: [
                    Center(child: const WajzLogoMark(size: 24)),
                    if (selected)
                      Positioned(
                        top: 5,
                        right: 5,
                        child: Icon(
                          Icons.check_circle,
                          size: 16,
                          color: palette.accentBright,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: WajzSpacing.xs + 2),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  context.l10n.themeName(palette.id),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.only(
        top: WajzSpacing.lg,
        bottom: WajzSpacing.sm,
      ),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}
