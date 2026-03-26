/// Backend Repository - integrates with Python FastAPI backend
library;

import 'dart:async';

import '../../core/api/backend_api.dart';
import '../../core/config/runtime_config.dart';
import '../models/user_models.dart';
import '../models/aqi_models.dart';
import '../models/exposure_models.dart';

class BackendRepository {
  BackendRepository({
    BackendApi? api,
    RuntimeConfig? config,
  }) : _api = api ?? BackendApi(config: config ?? RuntimeConfig.fallback);

  final BackendApi _api;

  // Health Check
  Future<bool> get isBackendHealthy async {
    return await _api.checkHealth();
  }

  // User Profile Management
  Future<UserProfile?> getUserProfile() async {
    return await _api.getUserProfile();
  }

  Future<bool> updateUserProfile(UserProfile profile) async {
    return await _api.updateUserProfile(profile);
  }

  Future<void> initializeUserProfile() async {
    await _api.initializeUserProfile();
  }

  // AQI Data (Backend Integration)
  Future<AqiData?> getCurrentAQIBackend(double lat, double lng) async {
    return await _api.getCurrentAQI(lat, lng);
  }

  Future<List<Map<String, dynamic>>> getAQIForecastBackend(double lat, double lng, {int days = 7}) async {
    return await _api.getAQIForecast(lat, lng, days: days);
  }

  // Exposure Tracking
  Future<bool> recordExposureBackend(ExposureRecord exposure) async {
    return await _api.recordExposure(exposure);
  }

  Future<List<ExposureRecord>> getExposureHistoryBackend({int days = 30}) async {
    return await _api.getExposureHistory(days: days);
  }

  // Location Management
  Future<bool> saveLocationBackend(SavedLocation location) async {
    return await _api.saveLocation(location);
  }

  Future<List<SavedLocation>> getSavedLocationsBackend() async {
    return await _api.getSavedLocations();
  }

  Future<bool> deleteLocationBackend(String locationId) async {
    return await _api.deleteLocation(locationId);
  }

  // Analytics
  Future<Map<String, dynamic>?> getAnalytics() async {
    return await _api.getAnalytics();
  }

  // Notifications
  Future<bool> testNotification(String type) async {
    return await _api.testNotification(type);
  }

  // Smart AQI fetching - tries backend first, falls back to direct API
  Future<AqiData?> getCurrentAQI(double lat, double lng) async {
    // Try backend first
    if (await isBackendHealthy) {
      final backendData = await getCurrentAQIBackend(lat, lng);
      if (backendData != null) {
        return backendData;
      }
    }
    
    // Fallback to null - let the existing AQI repository handle it
    return null;
  }

  // Smart exposure recording - tries backend first, falls back to local
  Future<bool> recordExposure(ExposureRecord exposure) async {
    // Try backend first
    if (await isBackendHealthy) {
      return await recordExposureBackend(exposure);
    }
    
    // Backend unavailable - this will be handled by the existing exposure repository
    return false;
  }

  // Smart location saving - tries backend first, falls back to local
  Future<bool> saveLocation(SavedLocation location) async {
    // Try backend first
    if (await isBackendHealthy) {
      return await saveLocationBackend(location);
    }
    
    // Backend unavailable - this will be handled by the existing auth repository
    return false;
  }

  // Smart location fetching - tries backend first, falls back to local
  Future<List<SavedLocation>> getSavedLocations() async {
    // Try backend first
    if (await isBackendHealthy) {
      return await getSavedLocationsBackend();
    }
    
    // Backend unavailable - return empty list, let existing repository handle it
    return [];
  }
}
