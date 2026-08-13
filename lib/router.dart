import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/providers.dart';
import 'features/briefing/today_screen.dart';
import 'features/explore/explore_screen.dart';
import 'features/login/login_screen.dart';
import 'features/ongoing/ongoing_screen.dart';
import 'features/ongoing/ongoing_topic_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/saved/saved_screen.dart';
import 'features/splash/splash_screen.dart';
import 'features/stories/story_detail_screen.dart';
import 'widgets/app_shell.dart';
import 'widgets/responsive_frame.dart';

String? startupRedirect(Uri location, SessionState session) {
  if (location.path == '/') {
    if (!session.authenticated) return '/explore';
    return session.onboardingDone ? '/today' : '/onboarding';
  }
  if (location.path == '/onboarding' && !session.authenticated) {
    return Uri(
      path: '/login',
      queryParameters: {'from': location.toString()},
    ).toString();
  }
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      final path = state.matchedLocation;
      if (!session.authReady || path == '/' || path == '/login') return null;

      final protected = path == '/onboarding';
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
                path: '/ongoing',
                builder: (context, state) => const OngoingScreen(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => OngoingTopicScreen(
                      topicId: state.pathParameters['id']!,
                    ),
                  ),
                ],
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
