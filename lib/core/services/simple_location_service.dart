/// Simple Location Service - just for getting location to work
library;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class SimpleLocationService {
  static const Duration _maxLastKnownAge = Duration(minutes: 10);
  static const double _maxLastKnownAccuracyMeters = 1000;
  static const double _targetCurrentAccuracyMeters = 100;
  static const double _maxAcceptableCurrentAccuracyMeters = 200;

  static Future<Position?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return null;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return null;
      }

      // GET REAL GPS POSITION - NO HARDCODED VALUES
      debugPrint('Getting real GPS position from device...');
      try {
        const locationSettings = LocationSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          timeLimit: Duration(seconds: 30),
        );
        final initial = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings,
        );

        final current = await _refineIfNeeded(initial);

        debugPrint(
          'Real GPS position: ${current.latitude}, ${current.longitude} (accuracy: ${current.accuracy.toStringAsFixed(0)}m)',
        );

        // Check if we got Mountain View coordinates (common emulator issue)
        if (_isMountainViewCoordinates(current.latitude, current.longitude)) {
          debugPrint(
            'Detected Mountain View coordinates - emulator default location',
          );
          debugPrint('This is likely because you are using an emulator');
          debugPrint(
            'On a real device, you would get your actual GPS coordinates',
          );
          // Return the real coordinates even if it's Mountain View - no hardcoded fallback
          return current;
        }

        // Return whatever GPS coordinates we get - real device location
        debugPrint('Using actual device GPS coordinates');
        return current;
      } catch (e) {
        debugPrint('Failed to get GPS: $e');
        debugPrint('Make sure location services are enabled on your device');
        return await getRecentLastKnownPosition();
      }
    } catch (e) {
      debugPrint('Error in location service: $e');
      return await getRecentLastKnownPosition();
    }
  }

  static Future<Position?> getRecentLastKnownPosition() async {
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown == null) return null;

      final age = DateTime.now().difference(lastKnown.timestamp);
      if (age > _maxLastKnownAge) {
        debugPrint('Ignoring stale last known location (${age.inMinutes} min old).');
        return null;
      }

      if (lastKnown.accuracy > _maxLastKnownAccuracyMeters) {
        debugPrint(
          'Ignoring low-accuracy last known location (${lastKnown.accuracy.toStringAsFixed(0)} m).',
        );
        return null;
      }

      debugPrint(
        'Using recent last known location: ${lastKnown.latitude}, ${lastKnown.longitude}',
      );
      return lastKnown;
    } catch (e) {
      debugPrint('Failed to get last known location fallback: $e');
      return null;
    }
  }

  static Future<Position> _refineIfNeeded(Position initial) async {
    if (initial.accuracy <= _maxAcceptableCurrentAccuracyMeters) {
      return initial;
    }

    debugPrint(
      'Initial GPS fix is coarse (${initial.accuracy.toStringAsFixed(0)}m). Waiting for a better fix...',
    );

    try {
      const streamSettings = LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 0,
      );

      Position best = initial;
      int attempts = 0;
      const maxAttempts = 10;
      
      await for (final sample in Geolocator.getPositionStream(
        locationSettings: streamSettings,
      ).timeout(const Duration(seconds: 15))) {
        attempts++;
        if (sample.accuracy < best.accuracy) {
          best = sample;
        }
        if (best.accuracy <= _targetCurrentAccuracyMeters || attempts >= maxAttempts) {
          break;
        }
      }

      debugPrint(
        'Refined GPS fix acquired (${best.accuracy.toStringAsFixed(0)}m).',
      );
      return best;
    } catch (_) {
      debugPrint(
        'Could not get a better GPS fix in time, using initial coarse fix.',
      );
      return initial;
    }
  }

  static bool _isMountainViewCoordinates(double lat, double lng) {
    // Mountain View, CA coordinates (Googleplex area)
    return (lat >= 37.4 && lat <= 37.5) && (lng >= -122.1 && lng <= -122.0);
  }

  static Future<bool> hasLocationPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return false;

      LocationPermission permission = await Geolocator.checkPermission();
      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      debugPrint('Error checking permission: $e');
      return false;
    }
  }

  static Future<bool> requestLocationPermission() async {
    try {
      // Enable location services if needed
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Try to open location settings
        await Geolocator.openLocationSettings();
        return false;
      }

      // Check current permission
      LocationPermission permission = await Geolocator.checkPermission();

      // Request permission if denied
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      return permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
    } catch (e) {
      debugPrint('Error requesting permission: $e');
      return false;
    }
  }
}
