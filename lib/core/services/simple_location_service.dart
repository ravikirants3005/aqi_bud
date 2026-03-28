/// Simple Location Service - just for getting location to work
library;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class SimpleLocationService {
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
        final current = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 30),
          forceAndroidLocationManager: true,
        );

        debugPrint(
          'Real GPS position: ${current.latitude}, ${current.longitude}',
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
        return null; // No hardcoded fallback
      }
    } catch (e) {
      debugPrint('Error in location service: $e');
      return null; // No hardcoded fallback
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
