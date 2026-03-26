/// Backend API Client - communicates with Python FastAPI backend
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/runtime_config.dart';
import '../../data/models/user_models.dart';
import '../../data/models/aqi_models.dart';
import '../../data/models/exposure_models.dart';

class BackendApi {
  BackendApi({RuntimeConfig? config}) : _config = config ?? RuntimeConfig.fallback;

  final RuntimeConfig _config;
  
  // Backend URL - update this to match your backend server
  static const String _baseUrl = 'http://localhost:8000';
  
  // Get current JWT token from Supabase
  String? _getAuthToken() {
    try {
      return Supabase.instance.client.auth.currentSession?.accessToken;
    } catch (e) {
      return null;
    }
  }
  
  // Common headers with authentication
  Map<String, String> _getHeaders({bool includeAuth = true}) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    
    if (includeAuth) {
      final token = _getAuthToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }
  
  // Health check
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: _getHeaders(includeAuth: false),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  // User Profile Operations
  
  Future<UserProfile?> getUserProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/user/profile'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return UserProfile.fromJson(data);
      }
    } catch (e) {
      print('Error getting user profile: $e');
    }
    return null;
  }
  
  Future<bool> updateUserProfile(UserProfile profile) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/user/profile'),
        headers: _getHeaders(),
        body: jsonEncode(profile.toJson()),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating user profile: $e');
      return false;
    }
  }
  
  // AQI Operations
  
  Future<AqiData?> getCurrentAQI(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/aqi/current?lat=$lat&lng=$lng'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return AqiData.fromJson(data);
      }
    } catch (e) {
      print('Error getting current AQI: $e');
    }
    return null;
  }
  
  Future<List<Map<String, dynamic>>> getAQIForecast(double lat, double lng, {int days = 7}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/aqi/forecast?lat=$lat&lng=$lng&days=$days'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return List<Map<String, dynamic>>.from(data['forecast'] ?? []);
      }
    } catch (e) {
      print('Error getting AQI forecast: $e');
    }
    return [];
  }
  
  // Exposure Operations
  
  Future<bool> recordExposure(ExposureRecord exposure) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/exposure/record'),
        headers: _getHeaders(),
        body: jsonEncode(exposure.toJson()),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error recording exposure: $e');
      return false;
    }
  }
  
  Future<List<ExposureRecord>> getExposureHistory({int days = 30}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/exposure/history?days=$days'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final exposures = data['exposures'] as List<dynamic>;
        return exposures.map((e) => ExposureRecord.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      print('Error getting exposure history: $e');
    }
    return [];
  }
  
  // Location Operations
  
  Future<bool> saveLocation(SavedLocation location) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/locations/save'),
        headers: _getHeaders(),
        body: jsonEncode(location.toJson()),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error saving location: $e');
      return false;
    }
  }
  
  Future<List<SavedLocation>> getSavedLocations() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/locations/saved'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final locations = data['locations'] as List<dynamic>;
        return locations.map((l) => SavedLocation.fromJson(l as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      print('Error getting saved locations: $e');
    }
    return [];
  }
  
  Future<bool> deleteLocation(String locationId) async {
    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/locations/$locationId'),
        headers: _getHeaders(),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error deleting location: $e');
      return false;
    }
  }
  
  // Analytics
  
  Future<Map<String, dynamic>?> getAnalytics() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/analytics'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (e) {
      print('Error getting analytics: $e');
    }
    return null;
  }
  
  // Test Notifications
  
  Future<bool> testNotification(String type) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/notifications/test?notification_type=$type'),
        headers: _getHeaders(),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error testing notification: $e');
      return false;
    }
  }
  
  // Initialize user profile after authentication
  Future<void> initializeUserProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    
    // Check if profile exists in backend
    final existingProfile = await getUserProfile();
    if (existingProfile == null) {
      // Create profile from Supabase user data
      final newProfile = UserProfile(
        id: user.id,
        email: user.email,
        displayName: user.userMetadata?['display_name'] ?? user.email ?? 'User',
        photoUrl: user.userMetadata?['avatar_url'],
        healthSensitivity: HealthSensitivity.values.firstWhere(
          (s) => s.name == (user.userMetadata?['health_sensitivity'] ?? 'normal'),
          orElse: () => HealthSensitivity.normal,
        ),
      );
      
      await updateUserProfile(newProfile);
    }
  }
}
