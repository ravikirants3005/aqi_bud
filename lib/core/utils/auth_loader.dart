/// Loads saved auth on app start
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../router/app_router.dart';
import '../../domain/providers/app_providers.dart';

class AuthLoader extends ConsumerStatefulWidget {
  final Widget child;

  const AuthLoader({super.key, required this.child});

  @override
  ConsumerState<AuthLoader> createState() => _AuthLoaderState();
}

class _AuthLoaderState extends ConsumerState<AuthLoader> {
  StreamSubscription<Position>? _locationSubscription;
  String? _lastPositionKey;
  bool _locationPromptOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_loadAuth());
      unawaited(_initializeLocationFlow());
    });
  }

  @override
  void dispose() {
    unawaited(_locationSubscription?.cancel());
    super.dispose();
  }

  Future<void> _loadAuth() async {
    final auth = ref.read(authRepositoryProvider);
    final user = await auth.getCurrentUser();
    if (user != null && mounted) {
      ref.read(userProfileProvider.notifier).setProfile(user);
    }
  }

  Future<void> _initializeLocationFlow() async {
    final approved = await _showStartupLocationPromptIfNeeded();
    if (!approved) return;
    await _bootstrapLocation();
    await _startLocationTracking();
  }

  Future<bool> _showStartupLocationPromptIfNeeded() async {
    if (!mounted || _locationPromptOpen) return false;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    final permission = await Geolocator.checkPermission();

    var dialogContext = rootNavigatorKey.currentContext;
    if (dialogContext == null) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
      dialogContext = rootNavigatorKey.currentContext;
    }
    if (dialogContext == null) {
      return serviceEnabled &&
          (permission == LocationPermission.whileInUse ||
              permission == LocationPermission.always);
    }

    _locationPromptOpen = true;
    final allow = await showDialog<bool>(
      context: dialogContext,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Allow location access'),
        content: const Text(
          'AQI Buddy uses your live device location to show AQI for where you are right now and label the exact place being tracked.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Not now'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Allow'),
          ),
        ],
      ),
    );
    _locationPromptOpen = false;

    if (!mounted || allow != true) return false;

    var servicesNowEnabled = serviceEnabled;
    if (!servicesNowEnabled) {
      await Geolocator.openLocationSettings();
      servicesNowEnabled = await Geolocator.isLocationServiceEnabled();
    }

    var updatedPermission = permission;
    if (updatedPermission == LocationPermission.denied) {
      updatedPermission = await Geolocator.requestPermission();
    }

    if (updatedPermission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
    }

    if (!mounted) return false;

    final granted = servicesNowEnabled &&
        (updatedPermission == LocationPermission.whileInUse ||
            updatedPermission == LocationPermission.always);
    if (!granted) {
      final messengerContext = rootNavigatorKey.currentContext;
      if (messengerContext == null) return false;
      ScaffoldMessenger.of(messengerContext).showSnackBar(
        const SnackBar(
          content: Text(
            'Location access is still off. Enable it to show AQI for your current place.',
          ),
        ),
      );
    }

    return granted;
  }

  Future<void> _bootstrapLocation() async {
    final granted = await ensureLocationPermission();
    if (!mounted || !granted) return;
    _refreshLocationDrivenData();
  }

  Future<void> _startLocationTracking() async {
    await _locationSubscription?.cancel();

    final granted = await ensureLocationPermission();
    if (!mounted || !granted) return;

    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 25,
      ),
    ).listen(
      (position) {
        if (!mounted) return;
        final nextKey =
            '${position.latitude.toStringAsFixed(4)},${position.longitude.toStringAsFixed(4)}';
        if (nextKey == _lastPositionKey) return;
        _lastPositionKey = nextKey;
        _refreshLocationDrivenData();
      },
      onError: (_) {},
    );
  }

  void _refreshLocationDrivenData() {
    ref.invalidate(locationProvider);
    ref.invalidate(currentAqiProvider);
    ref.invalidate(aqiTrendsProvider);
    ref.invalidate(exposureDashboardProvider);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
