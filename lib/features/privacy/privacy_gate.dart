import 'package:flutter/material.dart';

import '../../core/analytics/analytics_service.dart';
import '../../core/theme/app_theme.dart';

class PrivacyGate extends StatefulWidget {
  const PrivacyGate({super.key, required this.policy, required this.onAccept});

  final PrivacyPolicyDocument policy;
  final Future<void> Function() onAccept;

  @override
  State<PrivacyGate> createState() => _PrivacyGateState();
}

class _PrivacyGateState extends State<PrivacyGate> {
  bool _saving = false;
  bool _declined = false;
  String? _error;

  Future<void> _accept() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onAccept();
    } catch (_) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = widget.policy.language == 'ar'
              ? 'تعذر تسجيل الموافقة. تحقق من الاتصال وحاول مجدداً.'
              : 'Could not record acceptance. Check your connection and try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ar = widget.policy.language == 'ar';
    if (_declined) {
      return Scaffold(
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.all(WajzSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.privacy_tip_outlined,
                    size: 54,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: WajzSpacing.md),
                  Text(
                    ar
                        ? 'يتطلب استخدام واجِز قبول إشعار الخصوصية'
                        : 'Wajz requires acceptance of the privacy notice',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: WajzSpacing.sm),
                  Text(
                    ar
                        ? 'لن يجمع التطبيق أحداث التحليلات ولن يفتح المحتوى ما لم تقبل النسخة الحالية.'
                        : 'The app will not collect analytics events or open content unless you accept the current notice.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: WajzSpacing.lg),
                  FilledButton(
                    onPressed: () => setState(() => _declined = false),
                    child: Text(
                      ar ? 'مراجعة الإشعار مجدداً' : 'Review the notice again',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(WajzSpacing.lg),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(WajzSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: WajzSpacing.sm),
                          Expanded(
                            child: Text(
                              widget.policy.title,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: WajzSpacing.sm),
                      Text(
                        ar
                            ? 'النسخة ${widget.policy.version}'
                            : 'Version ${widget.policy.version}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: WajzSpacing.md),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            widget.policy.markdown.replaceAll(
                              RegExp(r'^#+\s*', multiLine: true),
                              '',
                            ),
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: WajzSpacing.sm),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: WajzSpacing.md),
                      FilledButton.icon(
                        onPressed: _saving ? null : _accept,
                        icon: _saving
                            ? const SizedBox.square(
                                dimension: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline),
                        label: Text(
                          ar ? 'أوافق وأتابع' : 'Accept and continue',
                        ),
                      ),
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => setState(() => _declined = true),
                        child: Text(ar ? 'لا أوافق' : 'Decline'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
