import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/l10n/app_localizations.dart';
import 'core/offline/offline_status_banner.dart';
import 'core/providers.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';
import 'features/privacy/privacy_gate.dart';
import 'router.dart';

class WajzApp extends ConsumerStatefulWidget {
  const WajzApp({super.key});

  @override
  ConsumerState<WajzApp> createState() => _WajzAppState();
}

class _WajzAppState extends ConsumerState<WajzApp> {
  var _bootstrapping = true;

  @override
  void initState() {
    super.initState();
    Future.microtask(_bootstrap);
  }

  Future<void> _bootstrap() async {
    final controller = ref.read(sessionProvider.notifier);
    final analytics = ref.read(analyticsServiceProvider);
    try {
      await analytics.initialize(ref.read(appLocaleProvider).languageCode);
      if (analytics.accepted) {
        await controller.restoreSession().timeout(const Duration(seconds: 6));
      }
    } catch (_) {
      // Guest mode remains usable when session restoration is unavailable.
    } finally {
      controller.finishBootstrap();
    }

    if (!mounted) return;
    if (analytics.accepted) _redirectForSession();
    setState(() => _bootstrapping = false);
  }

  void _redirectForSession() {
    final router = ref.read(routerProvider);
    final redirect = startupRedirect(
      router.routeInformationProvider.value.uri,
      ref.read(sessionProvider),
    );
    if (redirect != null) router.go(redirect);
  }

  Future<void> _acceptPrivacy() async {
    final analytics = ref.read(analyticsServiceProvider);
    await analytics.accept();
    final controller = ref.read(sessionProvider.notifier);
    await controller.restoreSession().timeout(const Duration(seconds: 6));
    controller.finishBootstrap();
    if (!mounted) return;
    _redirectForSession();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(appLocaleProvider);
    final palette = ref.watch(appThemeProvider);
    final analytics = ref.watch(analyticsServiceProvider);
    ref.watch(privacyEpochProvider);
    return MaterialApp.router(
      title: 'Wajz',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: appTheme(Brightness.light, locale, palette: palette),
      darkTheme: appTheme(Brightness.dark, locale, palette: palette),
      themeMode: palette.modeLock ?? ThemeMode.system,
      builder: (context, child) => OfflineStatusBanner(
        monitor: ref.watch(connectivityMonitorProvider),
        store: ref.watch(offlineStoreProvider),
        child: _bootstrapping
            ? const SplashScreen()
            : !analytics.accepted
            ? PrivacyGate(policy: analytics.policy, onAccept: _acceptPrivacy)
            : child ?? const SizedBox.shrink(),
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
