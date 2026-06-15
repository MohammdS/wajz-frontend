import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/arabesque.dart';
import '../../widgets/wajz_logo.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;
  String? _error;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _start();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      final restored =
          await ref.read(sessionProvider.notifier).restoreSession().timeout(
                const Duration(seconds: 6),
              );
      if (!mounted) return;
      if (!restored) {
        context.go('/login');
        return;
      }
      final session = ref.read(sessionProvider);
      context.go(session.onboardingDone ? '/today' : '/onboarding');
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.l10n.connectToWajzError);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fade = CurvedAnimation(parent: _intro, curve: Curves.easeOut);
    final scale = Tween(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _intro, curve: Curves.easeOutBack),
    );
    final brand = context.brand;

    return Scaffold(
      backgroundColor: brand.brandDeep,
      body: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(gradient: brand.brandGradient),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: WajzDotsPainter(
                color: Colors.white,
                gap: 30,
                opacity: 0.05,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: FadeTransition(
                opacity: fade,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ScaleTransition(
                      scale: scale,
                      child: const WajzLogoMark(size: 112, tile: true),
                    ),
                    const SizedBox(height: WajzSpacing.lg),
                    WajzWordmark(
                      fontSize: 46,
                      color: brand.onBrand,
                      subColor: brand.accentBright,
                      center: true,
                    ),
                    const SizedBox(height: WajzSpacing.md),
                    Text(
                      context.l10n.tagline,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: brand.onBrandFaint,
                            height: 1.5,
                          ),
                    ),
                    const SizedBox(height: WajzSpacing.xxl),
                    if (_error == null)
                      SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(brand.accentBright),
                        ),
                      )
                    else ...[
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFFCBD7E4)),
                      ),
                      const SizedBox(height: WajzSpacing.sm),
                      OutlinedButton(
                        onPressed: _start,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: brand.accentBright,
                          side: BorderSide(color: brand.accent),
                        ),
                        child: Text(context.l10n.tryAgain),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
