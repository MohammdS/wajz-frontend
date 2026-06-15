import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/desktop/desktop_layout.dart';
import 'profile_screen.dart';

/// Profile, desktop layout: a single comfortable, centred settings column —
/// no master–detail (there is nothing to read alongside it).
class DesktopProfileView extends StatelessWidget {
  const DesktopProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DesktopPaneHeader(
          title: context.l10n.profile,
          subtitle: context.l10n.topicsHelp,
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: const ProfileSettingsList(
                padding: EdgeInsets.fromLTRB(
                  WajzSpacing.lg,
                  0,
                  WajzSpacing.lg,
                  WajzSpacing.xl,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
