import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wajz/core/l10n/app_localizations.dart';
import 'package:wajz/core/models/models.dart';
import 'package:wajz/core/providers.dart';
import 'package:wajz/core/theme/app_theme.dart';
import 'package:wajz/features/login/login_screen.dart';
import 'package:wajz/features/privacy/privacy_gate.dart';
import 'package:wajz/core/analytics/analytics_service.dart';
import 'package:wajz/features/ongoing/ongoing_topic_card.dart';
import 'package:wajz/widgets/briefing_progress.dart';
import 'package:wajz/widgets/app_shell.dart';
import 'package:wajz/widgets/confidence_badge.dart';
import 'package:wajz/widgets/desktop/desktop_layout.dart';
import 'package:wajz/widgets/story_section.dart';
import 'package:wajz/router.dart';

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

    test('Briefing parses opened story ids', () {
      final briefing = Briefing.fromJson({
        'date': '2026-06-14',
        'briefing_length': '5_minutes',
        'estimated_read_time_minutes': 5,
        'greeting': 'Good morning.',
        'stories': <Map<String, dynamic>>[],
        'opened_story_ids': ['story-1', 'story-2'],
        'completion_message': 'You are caught up.',
      });
      expect(briefing.openedStoryIds, {'story-1', 'story-2'});
    });

    test('OngoingTopicDetail parses localized topic and paged stories', () {
      final detail = OngoingTopicDetail.fromJson({
        'id': 'topic-1',
        'title': 'World tournament',
        'description': 'Every verified update.',
        'category': 'Sports',
        'story_count': 1,
        'image_url': null,
        'last_updated_at': '2026-07-27T12:00:00',
        'expires_at': '2026-08-27T12:00:00',
        'content_language': 'en',
        'stories': {
          'items': [
            {
              'id': 'story-1',
              'headline': 'Opening match',
              'summary': 'The tournament has started.',
              'category': 'Sports',
              'region': 'World',
              'confidence_label': 'confirmed_by_multiple_sources',
              'confidence_display': 'Confirmed by multiple sources',
              'source_count': 3,
              'sources': ['BBC News'],
              'image_url': null,
              'last_updated_at': '2026-07-27T11:00:00',
              'saved': false,
              'content_language': 'en',
            },
          ],
          'total': 2,
          'limit': 1,
          'offset': 0,
        },
      });
      expect(detail.topic.title, 'World tournament');
      expect(detail.stories.single.id, 'story-1');
      expect(detail.hasMore, isTrue);
    });
  });

  group('localization', () {
    test('source count hides publication names', () {
      const english = AppLocalizations(Locale('en'));
      const arabic = AppLocalizations(Locale('ar'));

      expect(english.sourceCount(1), '1 source');
      expect(english.sourceCount(3), '3 sources');
      expect(english.readFullArticleOn, 'Read full article on');
      expect(arabic.sourceCount(1), 'مصدر واحد');
      expect(arabic.sourceCount(3), '3 مصادر');
      expect(arabic.readFullArticleOn, 'اقرأ المقال كاملاً على');
    });

    test('ongoing labels are localized', () {
      const english = AppLocalizations(Locale('en'));
      const arabic = AppLocalizations(Locale('ar'));
      expect(english.ongoing, 'Ongoing');
      expect(english.topicStories(3), '3 stories');
      expect(arabic.ongoing, 'الأحداث الجارية');
      expect(arabic.topicStories(3), '3 أخبار');
    });

    test('guest prompts and compact navigation labels are localized', () {
      const arabic = AppLocalizations(Locale('ar'));
      expect(arabic.navOngoing, 'الأحداث');
      expect(arabic.navSaved, 'محفوظ');
      expect(arabic.navProfile, 'حسابي');
      expect(arabic.signInToSave, 'سجّل الدخول لحفظ الأخبار.');
      expect(arabic.aiGeneratedSummary, 'ملخص مولّد بالذكاء الاصطناعي');
      expect(arabic.signInForBriefing, 'سجّل الدخول للحصول على موجزك اليومي');
    });
  });

  group('startup routing', () {
    test('root routes guests to explore', () {
      const session = SessionState(onboardingDone: false, authReady: true);
      expect(startupRedirect(Uri.parse('/'), session), '/explore');
    });

    test('root routes signed-in users by onboarding state', () {
      const pending = SessionState(
        token: 'token',
        onboardingDone: false,
        authReady: true,
      );
      const ready = SessionState(
        token: 'token',
        onboardingDone: true,
        authReady: true,
      );
      expect(startupRedirect(Uri.parse('/'), pending), '/onboarding');
      expect(startupRedirect(Uri.parse('/'), ready), '/today');
    });

    test('deep links are preserved during startup', () {
      const guest = SessionState(onboardingDone: false, authReady: true);
      expect(startupRedirect(Uri.parse('/story/story-1'), guest), isNull);
      expect(startupRedirect(Uri.parse('/ongoing/topic-1'), guest), isNull);
    });
  });

  group('widgets', () {
    testWidgets('privacy gate blocks content after decline', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PrivacyGate(
            policy: const PrivacyPolicyDocument(
              version: '2026-08-13',
              language: 'en',
              title: 'Privacy Notice',
              markdown: 'Limited first-party analytics.',
            ),
            onAccept: () async {},
          ),
        ),
      );
      expect(find.text('Limited first-party analytics.'), findsOneWidget);
      await tester.tap(find.text('Decline'));
      await tester.pump();
      expect(
        find.text('Wajz requires acceptance of the privacy notice'),
        findsOneWidget,
      );
    });

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

    testWidgets('OngoingTopicCard shows topic context and story count', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 360,
            height: 410,
            child: OngoingTopicCard(
              onTap: null,
              topic: OngoingTopic(
                id: 'topic-1',
                title: 'World tournament',
                description: 'Every verified update in one place.',
                category: 'Sports',
                storyCount: 3,
                imageUrl: null,
                lastUpdatedAt: DateTime(2026, 7, 27),
                expiresAt: null,
                contentLanguage: 'en',
              ),
            ),
          ),
        ),
      );
      expect(find.text('World tournament'), findsOneWidget);
      expect(find.text('Ongoing'), findsOneWidget);
      expect(find.text('3 stories'), findsOneWidget);
    });

    testWidgets('primary navigation places Ongoing after Briefing', (
      tester,
    ) async {
      late List<DesktopNavItem> items;
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) {
              items = desktopNavItems(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(items.map((item) => item.label).toList(), [
        'Briefing',
        'Ongoing',
        'Explore',
        'Saved',
        'Profile',
      ]);
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

    testWidgets('Arabic mobile navigation fits a 390px viewport', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => NavigationBar(
              selectedIndex: 0,
              destinations: mobileNavDestinations(context),
            ),
          ),
          locale: const Locale('ar'),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('الأحداث'), findsOneWidget);
      expect(find.text('محفوظ'), findsOneWidget);
      expect(find.text('حسابي'), findsOneWidget);
    });

    testWidgets('BulletList renders all items', (tester) async {
      await tester.pumpWidget(_wrap(const BulletList(items: ['One', 'Two'])));
      expect(find.textContaining('One'), findsOneWidget);
      expect(find.textContaining('Two'), findsOneWidget);
    });

    testWidgets('unconfigured auth keeps guest access available', (
      tester,
    ) async {
      await tester.pumpWidget(ProviderScope(child: _wrap(const LoginScreen())));
      expect(
        find.text(
          'Sign-in is not configured in this build. You can keep reading without an account.',
        ),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextButton, 'Continue without signing in'),
        findsOneWidget,
      );
      expect(find.byType(TextFormField), findsNothing);
    });
  });
}
