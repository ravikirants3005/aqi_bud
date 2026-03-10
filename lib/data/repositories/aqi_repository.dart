/// AQI repository - caches and throttles API (REQ-6.2)
library;

import 'package:shared_preferences/shared_preferences.dart';

import '../api/aqi_api.dart';
import '../models/aqi_models.dart';

class AqiRepository {
  AqiRepository({
    AqiApi? api,
    SharedPreferences? prefs,
  })  : _api = api ?? AqiApi(),
        _prefs = prefs;

  final AqiApi _api;
  final SharedPreferences? _prefs;

  static const _cacheKey = 'aqi_cache';
  static const _cacheTimeKey = 'aqi_cache_time';
  static const _cacheLatKey = 'aqi_cache_lat';
  static const _cacheLngKey = 'aqi_cache_lng';
  static const _cacheIntervalMs = 30 * 60 * 1000; // 30 min

  AqiData? _lastAqi;
  Map<String, List<AqiTrendDay>>? _lastTrends;
  DateTime? _lastFetch;

  Future<AqiData> getCurrentAqi(double lat, double lng) async {
    if (_shouldUseCache(lat, lng) && _lastAqi != null) {
      return _lastAqi!;
    }

    final data = await _api.fetchCurrentAqi(lat, lng);
    if (data != null) {
      _lastAqi = data;
      _lastFetch = DateTime.now();
      await _saveToPrefs(data);
    }
    return data ?? _lastAqi ?? _cachedFromPrefs(lat, lng);
  }

  Future<Map<String, List<AqiTrendDay>>> getAqiTrends(
    double lat,
    double lng,
  ) async {
    if (_lastTrends != null && _lastFetch != null) {
      final age = DateTime.now().difference(_lastFetch!).inMinutes;
      if (age < 60) return _lastTrends!;
    }

    _lastTrends = await _api.fetchAqiTrends(lat, lng);
    return _lastTrends!;
  }

  bool _shouldUseCache(double lat, double lng) {
    if (_lastFetch == null || _lastAqi == null) return false;
    final age = DateTime.now().difference(_lastFetch!).inMilliseconds;
    if (age > _cacheIntervalMs) return false;
    return (_lastAqi!.lat - lat).abs() < 0.01 && (_lastAqi!.lng - lng).abs() < 0.01;
  }

  Future<void> _saveToPrefs(AqiData d) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.setInt(_cacheKey, d.aqi);
    await p.setDouble(_cacheLatKey, d.lat);
    await p.setDouble(_cacheLngKey, d.lng);
    await p.setString(_cacheTimeKey, d.timestamp.toIso8601String());
  }

  AqiData _cachedFromPrefs(double lat, double lng) {
    final p = _prefs;
    if (p == null) {
      return AqiData(aqi: 50, lat: lat, lng: lng, timestamp: DateTime.now());
    }
    final aqi = p.getInt(_cacheKey) ?? 50;
    final cLat = p.getDouble(_cacheLatKey) ?? lat;
    final cLng = p.getDouble(_cacheLngKey) ?? lng;
    final ts = p.getString(_cacheTimeKey);
    return AqiData(
      aqi: aqi,
      lat: cLat,
      lng: cLng,
      timestamp: ts != null ? DateTime.tryParse(ts) ?? DateTime.now() : DateTime.now(),
    );
  }
}
