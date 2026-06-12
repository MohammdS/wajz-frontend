import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      await ref.read(sessionProvider.notifier).ensureSignedIn();
      if (!mounted) return;
      final session = ref.read(sessionProvider);
      context.go(session.onboardingDone ? '/today' : '/onboarding');
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not connect to Wajz.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('وجز', style: theme.textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                )),
            const SizedBox(height: WajzSpacing.sm),
            Text('Wajz', style: theme.textTheme.headlineSmall),
            const SizedBox(height: WajzSpacing.xs),
            Text(
              'Stay informed in minutes.\nNo noise. Sources included.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: WajzSpacing.xl),
            if (_error == null)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else ...[
              Text(_error!, style: theme.textTheme.bodyMedium),
              const SizedBox(height: WajzSpacing.sm),
              OutlinedButton(onPressed: _start, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}
