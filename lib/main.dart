/// AQI Buddy - Vayu Aarambh Innovations
/// Air Quality Awareness, Health Insights & Exposure Tracking
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/firebase/firebase_service.dart';
import 'core/utils/auth_loader.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initFirebase();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  runApp(
    ProviderScope(
      child: AuthLoader(
        child: const AqiBuddyApp(),
      ),
    ),
  );
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
