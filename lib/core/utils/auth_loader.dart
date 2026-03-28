/// Loads saved auth on app start
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../router/app_router.dart';
import '../services/simple_location_service.dart';
import '../../domain/providers/app_providers.dart';

class AuthLoader extends ConsumerStatefulWidget {
  final Widget child;

  const AuthLoader({super.key, required this.child});

  @override
  ConsumerState<AuthLoader> createState() => _AuthLoaderState();
}

class _AuthLoaderState extends ConsumerState<AuthLoader> {
  Timer? _locationPollTimer;
  String? _lastPositionKey;
  bool _locationPromptOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runInitialFlow();
    });
  }

  Future<void> _runInitialFlow() async {
    // 1. Load auth first
    await _loadAuth();

    // 2. Then ensure location permission and fetch location
    await _initializeLocationFlow();
  }

  @override
  void dispose() {
    _locationPollTimer?.cancel();
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

    final granted =
        servicesNowEnabled &&
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
    final position = await SimpleLocationService.getCurrentLocation();
    if (!mounted || position == null) return;

    _refreshLocationDrivenData();
  }

  Future<void> _startLocationTracking() async {
    final position = await SimpleLocationService.getCurrentLocation();
    if (!mounted || position == null) return;
    _locationPollTimer?.cancel();
    await _pollLocationAndRefresh(forceRefresh: true);
    _locationPollTimer = Timer.periodic(
      const Duration(minutes: 3),
      (_) => unawaited(_pollLocationAndRefresh()),
    );
  }

  Future<void> _pollLocationAndRefresh({bool forceRefresh = false}) async {
    final position = await SimpleLocationService.getCurrentLocation();
    if (!mounted || position == null) return;

    try {
      if (!mounted) return;

      final nextKey =
          '${position.latitude.toStringAsFixed(4)},${position.longitude.toStringAsFixed(4)}';
      if (!forceRefresh && nextKey == _lastPositionKey) {
        _refreshLocationDrivenData();
        return;
      }

      _lastPositionKey = nextKey;
      _refreshLocationDrivenData();
    } catch (_) {
      if (forceRefresh) {
        _refreshLocationDrivenData();
      }
    }
  }

  void _refreshLocationDrivenData() {
    ref.invalidate(locationProvider);
    ref.invalidate(currentAqiProvider);
    ref.invalidate(aqiHourlyHistoryProvider);
    ref.invalidate(aqiTrendsProvider);
    ref.invalidate(exposureDashboardProvider);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
