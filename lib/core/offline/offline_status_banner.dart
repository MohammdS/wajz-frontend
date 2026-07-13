import 'package:flutter/material.dart';

import 'connectivity_monitor.dart';
import 'offline_store.dart';

class OfflineStatusBanner extends StatelessWidget {
  const OfflineStatusBanner({
    super.key,
    required this.child,
    required this.monitor,
    required this.store,
  });

  final Widget child;
  final ConnectivityMonitor monitor;
  final OfflineStore store;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: monitor.online,
      builder: (context, online, _) => ValueListenableBuilder<int>(
        valueListenable: store.pendingCount,
        builder: (context, pending, _) {
          if (online && pending == 0) return child;
          final arabic = Localizations.localeOf(context).languageCode == 'ar';
          final message = online
              ? (arabic
                    ? 'جارٍ مزامنة $pending من التغييرات…'
                    : 'Syncing $pending pending change${pending == 1 ? '' : 's'}…')
              : (arabic
                    ? 'أنت غير متصل. نعرض المحتوى المحفوظ وستتم مزامنة التغييرات لاحقاً.'
                    : 'You are offline. Cached news is available and changes will sync later.');
          return Column(
            children: [
              Material(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          online ? Icons.sync : Icons.cloud_off_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(message)),
                        if (!online)
                          TextButton(
                            onPressed: monitor.checkNow,
                            child: Text(arabic ? 'إعادة المحاولة' : 'Retry'),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(child: child),
            ],
          );
        },
      ),
    );
  }
}
