import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  const AppLocalizations(this.locale);

  final Locale locale;

  bool get isArabic => locale.languageCode == 'ar';

  static const supportedLocales = [Locale('en'), Locale('ar')];
  static const delegate = _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(
          Localizations.maybeLocaleOf(context) ?? const Locale('en'),
        );
  }

  String get tagline => isArabic
      ? 'ابقَ على اطلاع خلال دقائق.\nمن دون ضوضاء. المصادر مرفقة.'
      : 'Stay informed in minutes.\nNo noise. Sources included.';
  String get tryAgain => isArabic ? 'حاول مرة أخرى' : 'Try again';
  String get continueLabel => isArabic ? 'متابعة' : 'Continue';
  String get loginTitle => isArabic ? 'تسجيل الدخول' : 'Sign in';
  String get loginSubtitle => isArabic
      ? 'استخدم بريدك الإلكتروني للمتابعة إلى واجِز.'
      : 'Use your email to continue to Wajz.';
  String get temporaryLoginNotice => isArabic
      ? 'تسجيل دخول مؤقت للتطوير. لا تحتاج إلى كلمة مرور.'
      : 'Temporary development login. No password is required.';
  String get emailAddress => isArabic ? 'البريد الإلكتروني' : 'Email address';
  String get displayName => isArabic ? 'الاسم (اختياري)' : 'Name (optional)';
  String get emailRequired => isArabic
      ? 'أدخل بريداً إلكترونياً صالحاً.'
      : 'Enter a valid email address.';
  String get loginFailed => isArabic
      ? 'تعذر تسجيل الدخول. تحقق من اتصال الخادم وحاول مرة أخرى.'
      : 'Could not sign in. Check the backend connection and try again.';
  String get startBriefing => isArabic ? 'ابدأ موجزي' : 'Start my briefing';
  String get today => isArabic ? 'اليوم' : 'Today';
  String get explore => isArabic ? 'استكشف' : 'Explore';
  String get saved => isArabic ? 'المحفوظات' : 'Saved';
  String get profile => isArabic ? 'الملف الشخصي' : 'Profile';
  String get all => isArabic ? 'الكل' : 'All';

  String get welcome => isArabic ? 'مرحباً بك في واجِز' : 'Welcome to Wajz';
  String get chooseLanguage =>
      isArabic ? 'اختر لغتك المفضلة.' : 'Choose your preferred language.';
  String get yourTopics => isArabic ? 'مواضيعك' : 'Your topics';
  String get topicsHelp => isArabic
      ? 'اختر ما تريد أن يظهر في موجزك. يمكنك تغيير ذلك في أي وقت.'
      : 'Pick what you want in your briefing. You can change this anytime.';
  String get yourRegions => isArabic ? 'مناطقك' : 'Your regions';
  String get regionsHelp => isArabic
      ? 'ما المناطق التي تتابع أخبارها؟'
      : 'Which parts of the world do you follow?';
  String get yourBriefing => isArabic ? 'موجزك' : 'Your briefing';
  String get briefingTimeHelp => isArabic
      ? 'كم من الوقت تريد تخصيصه يومياً؟'
      : 'How much time do you want to spend each day?';
  String get explanationLevel => isArabic ? 'مستوى الشرح' : 'Explanation level';
  String get preferencesSaveError => isArabic
      ? 'تعذر حفظ التفضيلات. حاول مرة أخرى.'
      : 'Could not save preferences. Try again.';

  String get language => isArabic ? 'اللغة' : 'Language';
  String get topics => isArabic ? 'المواضيع' : 'Topics';
  String get regions => isArabic ? 'المناطق' : 'Regions';
  String get briefingLength => isArabic ? 'مدة الموجز' : 'Briefing length';
  String get notifications => isArabic ? 'الإشعارات' : 'Notifications';
  String get signOut => isArabic ? 'تسجيل الخروج' : 'Sign out';
  String get versionTagline => isArabic
      ? 'واجِز 0.1.0 - ابقَ على اطلاع خلال دقائق.'
      : 'Wajz 0.1.0 - Stay informed in minutes.';

  String get noBriefing => isArabic ? 'لا يوجد موجز بعد' : 'No briefing yet';
  String get gatheringStories => isArabic
      ? 'ما زلنا نجمع الأخبار. عُد بعد قليل.'
      : 'Stories are still being gathered. Check back in a little while.';
  String get caughtUp =>
      isArabic ? 'أنت مطّلع على كل جديد.' : 'You are caught up.';
  String get caughtUpDetail => isArabic
      ? 'هذا كل ما يستحق معرفته في الوقت الحالي.'
      : 'That is everything worth knowing for now.';
  String briefingReady(int minutes, int count) => isArabic
      ? 'موجزك لمدة $minutes دقائق جاهز. تم اختيار $count أخبار من مصادر موثوقة.'
      : 'Your $minutes-minute briefing is ready. $count stories selected from trusted sources.';
  String greeting(DateTime now) {
    final hour = now.hour;
    if (hour >= 5 && hour < 12) {
      return isArabic ? 'صباح الخير.' : 'Good morning.';
    }
    if (hour >= 12 && hour < 18) {
      return isArabic ? 'مساء الخير.' : 'Good afternoon.';
    }
    return isArabic ? 'مساء الخير.' : 'Good evening.';
  }

  String get nothingHere =>
      isArabic ? 'لا يوجد شيء هنا بعد' : 'Nothing here yet';
  String get noStoriesInCategory => isArabic
      ? 'لا توجد أخبار في هذه الفئة حالياً.'
      : 'No stories in this category right now.';
  String get noSavedStories =>
      isArabic ? 'لا توجد أخبار محفوظة' : 'No saved stories';
  String get saveStoryHelp => isArabic
      ? 'اضغط علامة الحفظ على أي خبر لقراءته لاحقاً.'
      : 'Tap the bookmark on any story to read it later.';

  String get somethingWentWrong =>
      isArabic ? 'حدث خطأ ما' : 'Something went wrong';
  String get connectionError => isArabic
      ? 'تعذر الوصول إلى واجِز. تحقق من اتصالك وحاول مرة أخرى.'
      : 'Could not reach Wajz. Check your connection and try again.';
  String get connectToWajzError =>
      isArabic ? 'تعذر الاتصال بواجِز.' : 'Could not connect to Wajz.';
  String get saveForLater => isArabic ? 'حفظ لوقت لاحق' : 'Save for later';
  String get removeFromSaved =>
      isArabic ? 'إزالة من المحفوظات' : 'Remove from saved';
  String get updateSavedError => isArabic
      ? 'تعذر تحديث الأخبار المحفوظة.'
      : 'Could not update saved stories.';
  String get openLinkError =>
      isArabic ? 'تعذر فتح الرابط.' : 'Could not open the link.';

  String get whatHappened => isArabic ? 'ماذا حدث؟' : 'What happened';
  String get whyItMatters => isArabic ? 'لماذا يهم؟' : 'Why it matters';
  String get keyFacts => isArabic ? 'حقائق أساسية' : 'Key facts';
  String get stillUnclear =>
      isArabic ? 'ما الذي لا يزال غير واضح؟' : 'What is still unclear';
  String get sourceComparison =>
      isArabic ? 'مقارنة المصادر' : 'Source comparison';
  String get originalSources =>
      isArabic ? 'المصادر الأصلية' : 'Original sources';
  String openSource(String source) =>
      isArabic ? 'افتح $source' : 'Open $source';
  String sources(String value) =>
      isArabic ? 'المصادر: $value' : 'Sources: $value';
  String updated(String value) => isArabic ? 'حُدّث $value' : 'Updated $value';
  String get unknownSource => isArabic ? 'مصدر غير معروف' : 'Unknown source';
  String moreSources(String source, int count) => '$source + $count';

  String briefingProgress(int read, int total) => isArabic
      ? 'تمت قراءة $read من $total أخبار'
      : '$read of $total stories read';
  String get briefingComplete =>
      isArabic ? 'اكتمل الموجز' : 'Briefing complete';

  String languageName(String code) => code == 'ar' ? 'العربية' : 'English';

  String briefingLengthLabel(String value) {
    return switch (value) {
      '5_minutes' => isArabic ? '5 دقائق' : '5 minutes',
      '20_minutes' => isArabic ? '20 دقيقة' : '20 minutes',
      _ => isArabic ? '10 دقائق' : '10 minutes',
    };
  }

  String briefingLengthDetail(String value) {
    return switch (value) {
      '5_minutes' => isArabic ? '5-7 أخبار' : '5-7 stories',
      '20_minutes' => isArabic ? '18-25 خبراً' : '18-25 stories',
      _ => isArabic ? '10-12 خبراً' : '10-12 stories',
    };
  }

  String explanationLabel(String value) {
    return switch (value) {
      'brief' => isArabic ? 'مختصر' : 'Brief',
      'beginner_friendly' => isArabic ? 'مناسب للمبتدئين' : 'Beginner-friendly',
      _ => isArabic ? 'قياسي' : 'Standard',
    };
  }

  String explanationDetail(String value) {
    return switch (value) {
      'brief' => isArabic ? 'الأساسيات فقط' : 'Just the essentials',
      'beginner_friendly' =>
        isArabic
            ? 'خلفية إضافية ولغة بسيطة'
            : 'Extra background and simple language',
      _ => isArabic ? 'ملخصات واضحة مع سياق' : 'Clear summaries with context',
    };
  }

  String notificationLabel(String value) {
    return switch (value) {
      'none' => isArabic ? 'من دون إشعارات' : 'No notifications',
      'daily_evening' =>
        isArabic ? 'موجز مسائي يومي' : 'Daily evening briefing',
      'major_confirmed_only' =>
        isArabic
            ? 'الأخبار المهمة والمؤكدة فقط'
            : 'Major confirmed stories only',
      _ => isArabic ? 'موجز صباحي يومي' : 'Daily morning briefing',
    };
  }

  String category(String value) {
    if (!isArabic) return value;
    return const {
          'World': 'العالم',
          'Middle East': 'الشرق الأوسط',
          'Local / Regional': 'محلي وإقليمي',
          'Technology': 'التكنولوجيا',
          'Economy': 'الاقتصاد',
          'Science': 'العلوم',
          'Health': 'الصحة',
          'Sports': 'الرياضة',
          'Culture': 'الثقافة',
          'Politics': 'السياسة',
        }[value] ??
        value;
  }

  String region(String value) {
    if (!isArabic) return value;
    return const {
          'World': 'العالم',
          'Middle East': 'الشرق الأوسط',
          'Israel / Palestine': 'فلسطين / إسرائيل',
          'United States': 'الولايات المتحدة',
          'Europe': 'أوروبا',
          'Technology Global': 'التكنولوجيا عالمياً',
        }[value] ??
        value;
  }

  String confidence(String label, String fallback) {
    if (!isArabic) return fallback;
    return const {
          'confirmed_by_multiple_sources': 'مؤكد من عدة مصادر',
          'developing': 'خبر متطور',
          'single_source': 'تقرير من مصدر واحد',
          'opinion_analysis': 'رأي / تحليل',
          'correction_or_update': 'تصحيح أو تحديث',
          'low_confidence': 'ثقة منخفضة',
        }[label] ??
        fallback;
  }

  String timeAgo(DateTime time) {
    final now = DateTime.now().toUtc();
    final utcTime = time.isUtc
        ? time
        : DateTime.utc(
            time.year,
            time.month,
            time.day,
            time.hour,
            time.minute,
            time.second,
          );
    final diff = now.difference(utcTime);
    if (diff.inMinutes < 1) return isArabic ? 'الآن' : 'just now';
    if (diff.inMinutes < 60) {
      return isArabic ? 'قبل ${diff.inMinutes} د' : '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return isArabic ? 'قبل ${diff.inHours} س' : '${diff.inHours}h ago';
    }
    if (diff.inDays < 7) {
      return isArabic ? 'قبل ${diff.inDays} ي' : '${diff.inDays}d ago';
    }
    return '${time.day}/${time.month}/${time.year}';
  }
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) =>
      SynchronousFuture(AppLocalizations(locale));

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
