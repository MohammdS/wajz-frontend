import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/providers.dart';
import '../../core/auth/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/arabesque.dart';
import '../../widgets/wajz_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _submitting = false;
  bool _signUpMode = false;
  String? _error;
  String? _message;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _finishAuthentication() {
    if (!mounted) return;
    final session = ref.read(sessionProvider);
    if (!session.authenticated) return;
    final from = GoRouterState.of(context).uri.queryParameters['from'];
    context.go(
      session.onboardingDone
          ? (from?.isNotEmpty == true ? from! : '/today')
          : '/onboarding',
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
      _message = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      final email = _emailController.text.trim().toLowerCase();
      final name = _nameController.text.trim();
      if (auth.enabled) {
        if (_signUpMode) {
          final confirmationRequired = await ref
              .read(sessionProvider.notifier)
              .signUp(
                email,
                _passwordController.text,
                displayName: name.isEmpty ? null : name,
              );
          if (confirmationRequired) {
            if (mounted) {
              setState(() => _message = context.l10n.confirmationSent);
            }
            return;
          }
        } else {
          await ref
              .read(sessionProvider.notifier)
              .signInWithPassword(email, _passwordController.text);
        }
      } else {
        await ref
            .read(sessionProvider.notifier)
            .signInForDevelopment(
              email,
              displayName: name.isEmpty ? null : name,
            );
      }
      _finishAuthentication();
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.loginFailed);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _submitting = true;
      _error = null;
      _message = null;
    });
    try {
      await ref.read(sessionProvider.notifier).signInWithGoogle();
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.loginFailed);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim().toLowerCase();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = context.l10n.emailRequired);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
      _message = null;
    });
    try {
      await ref.read(sessionProvider.notifier).sendPasswordReset(email);
      if (mounted) setState(() => _message = context.l10n.resetSent);
    } catch (_) {
      if (mounted) setState(() => _error = context.l10n.loginFailed);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(sessionProvider, (_, next) {
      if (next.authenticated) _finishAuthentication();
    });
    final theme = Theme.of(context);
    final productionAuth = ref.watch(authServiceProvider).enabled;
    final authAvailable = productionAuth || devLoginEnabled;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(WajzSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    WajzHeroPanel(
                      padding: const EdgeInsets.fromLTRB(
                        WajzSpacing.lg,
                        WajzSpacing.xl,
                        WajzSpacing.lg,
                        WajzSpacing.xl,
                      ),
                      child: Column(
                        children: [
                          const WajzLogoMark(size: 72),
                          const SizedBox(height: WajzSpacing.md),
                          WajzWordmark(
                            fontSize: 38,
                            color: context.brand.onBrand,
                            subColor: context.brand.accentBright,
                            center: true,
                          ),
                          const SizedBox(height: WajzSpacing.sm),
                          Text(
                            context.l10n.loginSubtitle,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF93A4B8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: WajzSpacing.xl),
                    Text(
                      _signUpMode
                          ? context.l10n.signUp
                          : context.l10n.loginTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: WajzSpacing.lg),
                    if (!productionAuth)
                      Container(
                        padding: const EdgeInsets.all(WajzSpacing.md),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          devLoginEnabled
                              ? context.l10n.temporaryLoginNotice
                              : context.l10n.authUnavailable,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSecondaryContainer,
                          ),
                        ),
                      ),
                    if (authAvailable) ...[
                      const SizedBox(height: WajzSpacing.lg),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: context.l10n.emailAddress,
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (!RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(email)) {
                            return context.l10n.emailRequired;
                          }
                          return null;
                        },
                      ),
                      if (_signUpMode || !productionAuth) ...[
                        const SizedBox(height: WajzSpacing.md),
                        TextFormField(
                          controller: _nameController,
                          autofillHints: const [AutofillHints.name],
                          textInputAction: TextInputAction.next,
                          decoration: InputDecoration(
                            labelText: context.l10n.displayName,
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                        ),
                      ],
                      if (productionAuth) ...[
                        const SizedBox(height: WajzSpacing.md),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: true,
                          autofillHints: [
                            _signUpMode
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          textInputAction: _signUpMode
                              ? TextInputAction.next
                              : TextInputAction.done,
                          onFieldSubmitted: (_) {
                            if (!_signUpMode && !_submitting) _submit();
                          },
                          decoration: InputDecoration(
                            labelText: context.l10n.password,
                            prefixIcon: const Icon(Icons.lock_outline),
                          ),
                          validator: (value) {
                            if ((value ?? '').length < 8) {
                              return context.l10n.passwordRequired;
                            }
                            return null;
                          },
                        ),
                        if (_signUpMode) ...[
                          const SizedBox(height: WajzSpacing.md),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            autofillHints: const [AutofillHints.newPassword],
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) {
                              if (!_submitting) _submit();
                            },
                            decoration: InputDecoration(
                              labelText: context.l10n.confirmPassword,
                              prefixIcon: const Icon(Icons.lock_outline),
                            ),
                            validator: (value) =>
                                value != _passwordController.text
                                ? context.l10n.passwordMismatch
                                : null,
                          ),
                        ],
                      ],
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: WajzSpacing.md),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    if (_message != null) ...[
                      const SizedBox(height: WajzSpacing.md),
                      Text(
                        _message!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.primary),
                      ),
                    ],
                    if (authAvailable) ...[
                      const SizedBox(height: WajzSpacing.lg),
                      FilledButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _signUpMode
                                    ? context.l10n.signUp
                                    : context.l10n.loginTitle,
                              ),
                      ),
                    ],
                    if (productionAuth) ...[
                      const SizedBox(height: WajzSpacing.sm),
                      OutlinedButton.icon(
                        onPressed: _submitting ? null : _signInWithGoogle,
                        icon: const Icon(Icons.g_mobiledata, size: 28),
                        label: Text(context.l10n.continueWithGoogle),
                      ),
                      if (!_signUpMode)
                        TextButton(
                          onPressed: _submitting ? null : _resetPassword,
                          child: Text(context.l10n.forgotPassword),
                        ),
                      TextButton(
                        onPressed: _submitting
                            ? null
                            : () => setState(() {
                                _signUpMode = !_signUpMode;
                                _error = null;
                                _message = null;
                              }),
                        child: Text(
                          _signUpMode
                              ? context.l10n.haveAccount
                              : context.l10n.needAccount,
                        ),
                      ),
                    ],
                    const SizedBox(height: WajzSpacing.sm),
                    TextButton(
                      onPressed: _submitting
                          ? null
                          : () => context.go('/explore'),
                      child: Text(context.l10n.continueWithoutAccount),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
