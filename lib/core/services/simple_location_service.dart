/// Simple Location Service - Fast GPS without buffering
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

      // FAST GPS - NO BUFFERING
      debugPrint('Getting GPS position quickly...');
      try {
        // Use fast settings to avoid buffering
        const locationSettings = LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 5), // Fast timeout
        );
        
        final current = await Geolocator.getCurrentPosition(
          locationSettings: locationSettings,
        );
        
        debugPrint('GPS position: ${current.latitude}, ${current.longitude}');
        return current;
        
      } catch (e) {
        debugPrint('Fast GPS failed, trying low accuracy: $e');
        
        // Quick fallback with low accuracy
        try {
          const fallbackSettings = LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 3),
          );
          
          final fallback = await Geolocator.getCurrentPosition(
            locationSettings: fallbackSettings,
          );
          
          debugPrint('GPS fallback: ${fallback.latitude}, ${fallback.longitude}');
          return fallback;
        } catch (fallbackError) {
          debugPrint('All GPS attempts failed: $fallbackError');
          return null;
        }
      }
    } catch (e) {
      debugPrint('Error in location service: $e');
      return null;
    }
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
        debugPrint('Location service is disabled');
        return false;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission permanently denied');
        return false;
      }

      debugPrint('Location permission granted');
      return true;
    } catch (e) {
      debugPrint('Error requesting permission: $e');
      return false;
    }
  }

  static Future<Position?> getRecentLastKnownPosition() async {
    try {
      final lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        final age = DateTime.now().difference(lastKnown.timestamp);
        if (age.inMinutes < 10) { // Only use if recent
          debugPrint('Using recent last known position (${age.inMinutes} mins old)');
          return lastKnown;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting last known position: $e');
      return null;
    }
  }
}
