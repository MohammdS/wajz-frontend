import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/models.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/preference_chip.dart';
import '../preferences/preferences_provider.dart';

/// Onboarding flow (PRD milestone 6): language -> topics -> regions ->
/// briefing length, then preferences are pushed to the backend.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  bool _saving = false;

  String _language = 'en';
  final Set<String> _topics = {};
  final Set<String> _regions = {};
  String _briefingLength = '10_minutes';

  static const _languages = ['en', 'ar'];

  static const _lengths = ['5_minutes', '10_minutes', '20_minutes'];

  @override
  void initState() {
    super.initState();
    _language = ref.read(appLocaleProvider).languageCode;
    Future.microtask(
      () => ref.read(analyticsServiceProvider).track('onboarding_started'),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_page < 3) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(preferencesProvider.notifier)
          .save(
            Preferences(
              preferredLanguage: _language,
              topics: _topics.toList(),
              regions: _regions.toList(),
              briefingLength: _briefingLength,
              onboardingCompleted: true,
            ),
          );
      await ref.read(sessionProvider.notifier).completeOnboarding();
      await ref
          .read(analyticsServiceProvider)
          .track(
            'onboarding_completed',
            properties: {
              'language': _language,
              'briefing_length': _briefingLength,
            },
          );
      if (mounted) context.go('/today');
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.preferencesSaveError)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryInfo = ref.watch(categoriesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(WajzSpacing.md),
              child: Row(
                children: [
                  for (var i = 0; i < 4; i++)
                    Expanded(
                      child: Container(
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i <= _page
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (page) => setState(() => _page = page),
                children: [
                  _buildLanguagePage(theme),
                  _buildTopicsPage(theme, categoryInfo),
                  _buildRegionsPage(theme, categoryInfo),
                  _buildLengthPage(theme),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(WajzSpacing.md),
              child: FilledButton(
                onPressed: _saving ? null : _next,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _page < 3
                            ? context.l10n.continueLabel
                            : context.l10n.startBriefing,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _page_(ThemeData theme, String title, String subtitle, Widget body) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: WajzSpacing.lg),
      children: [
        const SizedBox(height: WajzSpacing.lg),
        Text(title, style: theme.textTheme.headlineSmall),
        const SizedBox(height: WajzSpacing.sm),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: WajzSpacing.lg),
        body,
      ],
    );
  }

  Widget _buildLanguagePage(ThemeData theme) {
    return _page_(
      theme,
      context.l10n.welcome,
      context.l10n.chooseLanguage,
      Column(
        children: [
          for (final code in _languages)
            SelectableTile(
              title: context.l10n.languageName(code),
              selected: _language == code,
              onTap: () {
                setState(() => _language = code);
                ref.read(appLocaleProvider.notifier).setLanguage(code);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTopicsPage(ThemeData theme, AsyncValue<CategoryInfo> info) {
    final categories =
        info.value?.categories ??
        const [
          'World',
          'Technology',
          'Economy',
          'Science',
          'Health',
          'Sports',
          'Culture',
          'Politics',
        ];
    return _page_(
      theme,
      context.l10n.yourTopics,
      context.l10n.topicsHelp,
      Wrap(
        spacing: WajzSpacing.sm,
        runSpacing: WajzSpacing.sm,
        children: [
          for (final category in categories)
            PreferenceChip(
              label: context.l10n.category(category),
              selected: _topics.contains(category),
              onTap: () => setState(() {
                _topics.contains(category)
                    ? _topics.remove(category)
                    : _topics.add(category);
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildRegionsPage(ThemeData theme, AsyncValue<CategoryInfo> info) {
    final regions =
        info.value?.regions ??
        const [
          'World',
          'Middle East',
          'Israel / Palestine',
          'United States',
          'Europe',
        ];
    return _page_(
      theme,
      context.l10n.yourRegions,
      context.l10n.regionsHelp,
      Wrap(
        spacing: WajzSpacing.sm,
        runSpacing: WajzSpacing.sm,
        children: [
          for (final region in regions)
            PreferenceChip(
              label: context.l10n.region(region),
              selected: _regions.contains(region),
              onTap: () => setState(() {
                _regions.contains(region)
                    ? _regions.remove(region)
                    : _regions.add(region);
              }),
            ),
        ],
      ),
    );
  }

  Widget _buildLengthPage(ThemeData theme) {
    return _page_(
      theme,
      context.l10n.yourBriefing,
      context.l10n.briefingTimeHelp,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final value in _lengths)
            SelectableTile(
              title: context.l10n.briefingLengthLabel(value),
              subtitle: context.l10n.briefingLengthDetail(value),
              selected: _briefingLength == value,
              onTap: () => setState(() => _briefingLength = value),
            ),
        ],
      ),
    );
  }
}

class SelectableTile extends StatelessWidget {
  const SelectableTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: WajzSpacing.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(WajzSpacing.md),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outlineVariant,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
