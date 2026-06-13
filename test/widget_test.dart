import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wajz/core/l10n/app_localizations.dart';
import 'package:wajz/core/models/models.dart';
import 'package:wajz/core/theme/app_theme.dart';
import 'package:wajz/features/login/login_screen.dart';
import 'package:wajz/widgets/briefing_progress.dart';
import 'package:wajz/widgets/confidence_badge.dart';
import 'package:wajz/widgets/story_section.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) => MaterialApp(
  locale: locale,
  supportedLocales: AppLocalizations.supportedLocales,
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  theme: lightTheme,
  home: Scaffold(body: child),
);

void main() {
  group('models', () {
    test('StoryListItem.fromJson parses API payload', () {
      final item = StoryListItem.fromJson({
        'id': 'abc',
        'headline': 'EU proposes stricter AI model rules',
        'summary': 'The proposal would require disclosure.',
        'category': 'Technology',
        'region': 'Europe',
        'confidence_label': 'confirmed_by_multiple_sources',
        'confidence_display': 'Confirmed by multiple sources',
        'source_count': 3,
        'sources': ['BBC News', 'The Verge'],
        'image_url': null,
        'last_updated_at': '2026-06-11T08:30:00',
        'saved': true,
        'content_language': 'en',
      });
      expect(item.id, 'abc');
      expect(item.sourceCount, 3);
      expect(item.saved, isTrue);
      expect(item.contentLanguage, 'en');
      expect(item.copyWith(saved: false).saved, isFalse);
    });

    test('Preferences round-trips through JSON', () {
      const prefs = Preferences(
        preferredLanguage: 'ar',
        topics: ['Technology'],
        regions: ['Middle East'],
        briefingLength: '5_minutes',
        onboardingCompleted: true,
      );
      final parsed = Preferences.fromJson(prefs.toJson());
      expect(parsed.preferredLanguage, 'ar');
      expect(parsed.topics, ['Technology']);
      expect(parsed.briefingLength, '5_minutes');
      expect(parsed.onboardingCompleted, isTrue);
    });
  });

  group('widgets', () {
    testWidgets('ConfidenceBadge shows display text', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const ConfidenceBadge(label: 'developing', display: 'Developing'),
        ),
      );
      expect(find.text('Developing'), findsOneWidget);
    });

    testWidgets('BriefingProgress reports read count', (tester) async {
      await tester.pumpWidget(
        _wrap(const BriefingProgress(read: 3, total: 12)),
      );
      expect(find.text('3 of 12 stories read'), findsOneWidget);
    });

    testWidgets('BriefingProgress completion state', (tester) async {
      await tester.pumpWidget(
        _wrap(const BriefingProgress(read: 12, total: 12)),
      );
      expect(find.text('Briefing complete'), findsOneWidget);
    });

    testWidgets('Arabic locale translates UI and uses RTL', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const BriefingProgress(read: 3, total: 12),
          locale: const Locale('ar'),
        ),
      );
      expect(find.text('تمت قراءة 3 من 12 أخبار'), findsOneWidget);
      final directionality = tester.widget<Directionality>(
        find.byType(Directionality).first,
      );
      expect(directionality.textDirection, TextDirection.rtl);
    });

    testWidgets('BulletList renders all items', (tester) async {
      await tester.pumpWidget(_wrap(const BulletList(items: ['One', 'Two'])));
      expect(find.textContaining('One'), findsOneWidget);
      expect(find.textContaining('Two'), findsOneWidget);
    });

    testWidgets('temporary login shows its form fields', (tester) async {
      await tester.pumpWidget(ProviderScope(child: _wrap(const LoginScreen())));
      expect(
        find.text('Temporary development login. No password is required.'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, 'Email address'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, 'Name (optional)'),
        findsOneWidget,
      );
      expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
    });
  });
}
