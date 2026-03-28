/// Location Service - handles location permissions and requests
library;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Future<bool> isLocationEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  static Future<bool> ensureLocationPermission({
    bool requestIfNeeded = true,
    BuildContext? context,
  }) async {
    // Check if location service is enabled
    final enabled = await isLocationEnabled();
    if (!enabled) {
      if (context != null && context.mounted) {
        _showLocationDisabledDialog(context);
      }
      return false;
    }

    // Check current permission
    var permission = await checkPermission();
    
    // Handle different permission states
    switch (permission) {
      case LocationPermission.denied:
        if (requestIfNeeded) {
          permission = await requestPermission();
          if (permission == LocationPermission.denied) {
            if (context != null && context.mounted) {
              _showPermissionDeniedDialog(context);
            }
            return false;
          }
        } else {
          return false;
        }
        break;
        
      case LocationPermission.deniedForever:
        if (context != null && context.mounted) {
          _showPermissionPermanentlyDeniedDialog(context);
        }
        return false;
        
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        return true;
        
      case LocationPermission.unableToDetermine:
        return false;
    }

    return permission == LocationPermission.whileInUse ||
           permission == LocationPermission.always;
  }

  static Future<Position?> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: locationSettings ?? const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }

  static Future<Position?> getLastKnownPosition() async {
    try {
      return await Geolocator.getLastKnownPosition();
    } catch (e) {
      print('Error getting last known position: $e');
      return null;
    }
  }

  static void _showLocationDisabledDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Services Disabled'),
        content: const Text(
          'Location services are disabled. Please enable them in your device settings to use AQI Buddy.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Denied'),
        content: const Text(
          'Location permission is required to show AQI data for your current location. Please grant permission to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void _showPermissionPermanentlyDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Permanently Denied'),
        content: const Text(
          'Location permission was permanently denied. Please enable it in your device settings to use location features.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  static Future<Position?> getBestPosition() async {
    // Try to get last known position first (faster)
    final lastKnown = await getLastKnownPosition();
    
    // Get current position
    final current = await getCurrentPosition();
    
    if (current == null) return lastKnown;
    if (lastKnown == null) return current;
    
    // Return the more accurate position
    return current.accuracy <= lastKnown.accuracy ? current : lastKnown;
  }
}
