/// AQI Buddy - Vayu Aarambh Innovations
/// Air Quality Awareness, Health Insights & Exposure Tracking
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import 'core/config/runtime_config.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/supabase/supabase_service.dart';
import 'core/utils/auth_loader.dart';
import 'domain/providers/app_providers.dart';

final runtimeConfigProvider = Provider<RuntimeConfig>(
  (_) => RuntimeConfig.fallback,
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initSupabase();
  final runtimeConfig = await RuntimeConfig.load();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  runApp(
    ProviderScope(
      overrides: [runtimeConfigProvider.overrideWithValue(runtimeConfig)],
      child: AuthLoader(child: const AqiBuddyApp()),
    ),
  );

  // Initialize notifications and backend after app is built
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final container = ProviderContainer();
    container.read(userProfileProvider.notifier).initializeNotifications();
    container.read(userProfileProvider.notifier).initializeBackendProfile();
  });
}

class AqiBuddyApp extends StatelessWidget {
  const AqiBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'AQI Buddy',
      theme: appLightTheme,
      darkTheme: appDarkTheme,
      themeMode: ThemeMode.system,
      routerConfig: goRouter,
    );
  }
}
