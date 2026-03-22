import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/home_screen.dart';
import '../../features/insights/insights_screen.dart';
import '../../features/education/education_screen.dart';
import '../../features/profile/profile_screen.dart';
import '../../features/suggestions/suggestions_screen.dart';
import '../../features/health_tips/health_tips_screen.dart';
import 'main_wrapper.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final GoRouter goRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) {
        return MainWrapper(child: child);
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const HomeScreen(),
          routes: [
            GoRoute(
              path: 'suggestions',
              builder: (context, state) => const SuggestionsScreen(),
            ),
            GoRoute(
              path: 'health-tips',
              builder: (context, state) => const HealthTipsScreen(),
            ),
          ],
        ),
        GoRoute(
          path: '/insights',
          builder: (context, state) => const InsightsScreen(),
        ),
        GoRoute(
          path: '/education',
          builder: (context, state) => const EducationScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
      ],
    ),
  ],
);
