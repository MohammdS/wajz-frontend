import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/l10n/app_localizations.dart';
import 'desktop/desktop_layout.dart';

List<NavigationDestination> mobileNavDestinations(BuildContext context) => [
  NavigationDestination(
    icon: const Icon(Icons.summarize_outlined),
    selectedIcon: const Icon(Icons.summarize),
    label: context.l10n.navToday,
  ),
  NavigationDestination(
    icon: const Icon(Icons.radar),
    selectedIcon: const Icon(Icons.radar),
    label: context.l10n.navOngoing,
  ),
  NavigationDestination(
    icon: const Icon(Icons.explore_outlined),
    selectedIcon: const Icon(Icons.explore),
    label: context.l10n.navExplore,
  ),
  NavigationDestination(
    icon: const Icon(Icons.bookmark_outline),
    selectedIcon: const Icon(Icons.bookmark),
    label: context.l10n.navSaved,
  ),
  NavigationDestination(
    icon: const Icon(Icons.person_outline),
    selectedIcon: const Icon(Icons.person),
    label: context.l10n.navProfile,
  ),
];

/// Adaptive navigation shell for the five main tabs (PRD 16.1).
///
/// Phones / narrow browsers keep the bottom [NavigationBar]. Desktop and wide
/// browsers get a persistent branded [DesktopSidebar] beside the content, which
/// drives the dedicated desktop layouts of each section.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) => navigationShell.goBranch(
    index,
    initialLocation: index == navigationShell.currentIndex,
  );

  @override
  Widget build(BuildContext context) {
    if (isDesktopWidth(context)) {
      return Scaffold(
        body: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DesktopSidebar(
              currentIndex: navigationShell.currentIndex,
              onSelect: _goBranch,
            ),
            Expanded(child: navigationShell),
          ],
        ),
      );
    }

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _goBranch,
        destinations: mobileNavDestinations(context),
      ),
    );
  }
}
