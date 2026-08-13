import 'package:flutter/material.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../wajz_logo.dart';
import 'desktop_story_reader.dart';

/// Shared desktop layout metrics. The mobile app is used below
/// [kDesktopBreakpoint]; at and above it Wajz switches to a dedicated desktop
/// experience (persistent sidebar + master–detail reading pane).
const double kDesktopBreakpoint = 900;
const double kSidebarWidth = 252;
const double kMasterPaneWidth = 360;

/// Minimum width of the *content area* (i.e. excluding the sidebar) needed to
/// show the master list and the reading pane side by side. Below this the
/// reader takes over the whole content area with a "back to list" affordance.
const double kTwoPaneMinWidth = 700;

/// Returns true when the current window should use the desktop layout.
bool isDesktopWidth(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kDesktopBreakpoint;

/// The five primary destinations, shared by the sidebar and the bottom nav.
class DesktopNavItem {
  const DesktopNavItem(this.icon, this.selectedIcon, this.label);
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

List<DesktopNavItem> desktopNavItems(BuildContext context) => [
  DesktopNavItem(Icons.summarize_outlined, Icons.summarize, context.l10n.today),
  DesktopNavItem(Icons.radar, Icons.radar, context.l10n.ongoing),
  DesktopNavItem(Icons.explore_outlined, Icons.explore, context.l10n.explore),
  DesktopNavItem(Icons.bookmark_outline, Icons.bookmark, context.l10n.saved),
  DesktopNavItem(Icons.person_outline, Icons.person, context.l10n.profile),
];

/// Persistent, branded left navigation for the desktop layout. Always rendered
/// on the deep-navy brand surface regardless of the app theme, so it reads as a
/// stable "frame" around the lighter content.
class DesktopSidebar extends StatelessWidget {
  const DesktopSidebar({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = desktopNavItems(context);
    final brand = context.brand;
    return Container(
      width: kSidebarWidth,
      decoration: BoxDecoration(
        gradient: brand.brandGradient,
        border: BorderDirectional(
          end: BorderSide(color: brand.accentBright.withValues(alpha: 0.10)),
        ),
      ),
      child: SafeArea(
        right: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                WajzSpacing.lg,
                WajzSpacing.lg,
                WajzSpacing.lg,
                WajzSpacing.md,
              ),
              child: WajzLogo(
                markSize: 38,
                fontSize: 24,
                color: brand.onBrand,
                subColor: brand.accentBright,
              ),
            ),
            const SizedBox(height: WajzSpacing.sm),
            for (var i = 0; i < items.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: WajzSpacing.sm + 4,
                  vertical: 3,
                ),
                child: _SidebarItem(
                  item: items[i],
                  selected: i == currentIndex,
                  onTap: () => onSelect(i),
                ),
              ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(WajzSpacing.lg),
              child: Text(
                context.l10n.versionTagline,
                style: TextStyle(
                  color: brand.onBrandFaint,
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final DesktopNavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final brand = context.brand;
    final color = selected ? brand.accentBright : brand.onBrandMuted;
    return Material(
      color: selected
          ? brand.accentBright.withValues(alpha: 0.14)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(WajzRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(WajzRadius.md),
        hoverColor: Colors.white.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: WajzSpacing.md,
            vertical: 13,
          ),
          child: Row(
            children: [
              Icon(
                selected ? item.selectedIcon : item.icon,
                size: 21,
                color: color,
              ),
              const SizedBox(width: WajzSpacing.md),
              Text(
                item.label,
                style: TextStyle(
                  color: selected ? brand.onBrand : color,
                  fontSize: 14.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two-pane master–detail container used by Today / Explore / Saved on desktop.
///
/// When the content area is wide enough the [master] list and the reading pane
/// sit side by side; otherwise the reader takes over and [onCloseDetail] shows a
/// back button so the user can return to the list.
class DesktopMasterDetail extends StatelessWidget {
  const DesktopMasterDetail({
    super.key,
    required this.master,
    required this.selectedStoryId,
    required this.onCloseDetail,
  });

  final Widget master;
  final String? selectedStoryId;
  final VoidCallback onCloseDetail;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoPane = constraints.maxWidth >= kTwoPaneMinWidth;
        final id = selectedStoryId;

        if (twoPane) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: kMasterPaneWidth,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: BorderDirectional(
                      end: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                  ),
                  child: master,
                ),
              ),
              Expanded(
                child: id == null
                    ? const ReadingPanePlaceholder()
                    : DesktopStoryReader(key: ValueKey(id), storyId: id),
              ),
            ],
          );
        }

        // Collapsed: list, or the reader full-width with a back button.
        if (id == null) return master;
        return DesktopStoryReader(
          key: ValueKey(id),
          storyId: id,
          onClose: onCloseDetail,
        );
      },
    );
  }
}

/// Calm empty state for the reading pane before a story is chosen.
class ReadingPanePlaceholder extends StatelessWidget {
  const ReadingPanePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(WajzSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(opacity: 0.5, child: const WajzLogoMark(size: 46)),
            const SizedBox(height: WajzSpacing.lg),
            Text(
              context.l10n.selectStoryPrompt,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: WajzSpacing.sm),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                context.l10n.selectStoryHint,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A desktop section header: a compact brand panel with a title and optional
/// subtitle/trailing, used at the top of the master list.
class DesktopPaneHeader extends StatelessWidget {
  const DesktopPaneHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        WajzSpacing.lg,
        WajzSpacing.lg,
        WajzSpacing.lg,
        WajzSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: wajzDisplayFont(
                    Localizations.localeOf(context),
                    textStyle: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: WajzSpacing.xs),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
