/// Loads saved auth on app start
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/providers/app_providers.dart';

class AuthLoader extends ConsumerStatefulWidget {
  final Widget child;

  const AuthLoader({super.key, required this.child});

  @override
  ConsumerState<AuthLoader> createState() => _AuthLoaderState();
}

class _AuthLoaderState extends ConsumerState<AuthLoader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadAuth());
      unawaited(_bootstrapLocation());
    });
  }

  Future<void> _loadAuth() async {
    final auth = ref.read(authRepositoryProvider);
    final user = await auth.getCurrentUser();
    if (user != null && mounted) {
      ref.read(userProfileProvider.notifier).setProfile(user);
    }
  }

  Future<void> _bootstrapLocation() async {
    final granted = await ensureLocationPermission(requestIfNeeded: true);
    if (!mounted || !granted) return;

    ref.invalidate(locationProvider);
    ref.invalidate(currentAqiProvider);
    ref.invalidate(aqiTrendsProvider);
    ref.invalidate(exposureDashboardProvider);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
