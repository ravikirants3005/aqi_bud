/// App navigation - go_router
library;

import 'package:go_router/go_router.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/education/screens/education_screen.dart';
import '../../features/health_tips/screens/health_tips_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/insights/screens/insights_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/saved_locations_screen.dart';
import '../../features/suggestions/screens/suggestions_screen.dart';

final goRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/suggestions',
      builder: (context, state) => const SuggestionsScreen(),
    ),
    GoRoute(
      path: '/health-tips',
      builder: (context, state) => const HealthTipsScreen(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
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
      path: '/saved-locations',
      builder: (context, state) => const SavedLocationsScreen(),
    ),
  ],
);
