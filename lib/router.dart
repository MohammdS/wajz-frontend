import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/providers.dart';
import 'features/briefing/today_screen.dart';
import 'features/explore/explore_screen.dart';
import 'features/login/login_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/saved/saved_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/stories/story_detail_screen.dart';
import 'widgets/app_shell.dart';
import 'widgets/responsive_frame.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final path = state.matchedLocation;
      if (path == '/' || path == '/login') return null;

      final protected = path == '/today' || path == '/onboarding';
      if (protected && !session.authenticated) {
        return Uri(
          path: '/login',
          queryParameters: {'from': state.uri.toString()},
        ).toString();
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const ResponsiveWebFrame(child: SplashScreen()),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) =>
            const ResponsiveWebFrame(child: LoginScreen()),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) =>
            const ResponsiveWebFrame(child: OnboardingScreen()),
      ),
      GoRoute(
        path: '/story/:id',
        builder: (context, state) => ResponsiveWebFrame(
          child: StoryDetailScreen(storyId: state.pathParameters['id']!),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/today',
                builder: (context, state) => const TodayScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/explore',
                builder: (context, state) => const ExploreScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/saved',
                builder: (context, state) => const SavedScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
