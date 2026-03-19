/// AQI repository - caches and throttles API (REQ-6.2)
library;

import 'dart:convert';

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

  static const _currentCachePrefix = 'aqi_cache_';
  static const _trendCachePrefix = 'aqi_trends_';
  static const _trendCacheTimePrefix = 'aqi_trends_time_';
  static const _cacheIntervalMs = 30 * 60 * 1000; // 30 min

  final Map<String, AqiData> _memoryCurrentCache = {};
  final Map<String, Map<String, List<AqiTrendDay>>> _memoryTrendCache = {};
  final Map<String, DateTime> _memoryCurrentFetchTimes = {};
  final Map<String, DateTime> _memoryTrendFetchTimes = {};

  Future<AqiData?> getCurrentAqi(double lat, double lng) async {
    final key = _locationKey(lat, lng);
    if (_shouldUseCurrentCache(key)) {
      return _memoryCurrentCache[key];
    }

    final data = await _api.fetchCurrentAqi(lat, lng);
    if (data != null) {
      _memoryCurrentCache[key] = data;
      _memoryCurrentFetchTimes[key] = DateTime.now();
      await _saveCurrentToPrefs(key, data);
      return data;
    }

    final cached = await _readCurrentFromPrefs(key);
    if (cached != null) {
      _memoryCurrentCache[key] = cached;
      return cached;
    }
    return null;
  }

  Future<Map<String, List<AqiTrendDay>>> getAqiTrends(
    double lat,
    double lng,
  ) async {
    final key = _locationKey(lat, lng);
    if (_shouldUseTrendCache(key)) {
      return _memoryTrendCache[key]!;
    }

    final liveTrends = await _api.fetchAqiTrends(lat, lng);
    final hasLiveData = (liveTrends['week']?.isNotEmpty ?? false) ||
        (liveTrends['month']?.isNotEmpty ?? false);
    if (hasLiveData) {
      _memoryTrendCache[key] = liveTrends;
      _memoryTrendFetchTimes[key] = DateTime.now();
      await _saveTrendsToPrefs(key, liveTrends);
      return liveTrends;
    }

    final cached = await _readTrendsFromPrefs(key);
    if (cached != null) {
      _memoryTrendCache[key] = cached;
      return cached;
    }

    return const {'week': [], 'month': []};
  }

  bool _shouldUseCurrentCache(String key) {
    final fetchedAt = _memoryCurrentFetchTimes[key];
    final current = _memoryCurrentCache[key];
    if (fetchedAt == null || current == null) {
      return false;
    }
    return DateTime.now().difference(fetchedAt).inMilliseconds <= _cacheIntervalMs;
  }

  bool _shouldUseTrendCache(String key) {
    final fetchedAt = _memoryTrendFetchTimes[key];
    final trends = _memoryTrendCache[key];
    if (fetchedAt == null || trends == null) {
      return false;
    }
    return DateTime.now().difference(fetchedAt).inMilliseconds <= _cacheIntervalMs;
  }

  Future<void> _saveCurrentToPrefs(String key, AqiData data) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.setString(
      '$_currentCachePrefix$key',
      jsonEncode({
        'aqi': data.aqi,
        'lat': data.lat,
        'lng': data.lng,
        'timestamp': data.timestamp.toIso8601String(),
        'pm25': data.pm25,
        'pm10': data.pm10,
        'locationName': data.locationName,
      }),
    );
  }

  Future<AqiData?> _readCurrentFromPrefs(String key) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    final raw = p.getString('$_currentCachePrefix$key');
    if (raw == null) {
      return null;
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final timestamp =
        DateTime.tryParse(decoded['timestamp'] as String? ?? '') ?? DateTime.now();
    if (DateTime.now().difference(timestamp).inMilliseconds > _cacheIntervalMs) {
      return null;
    }
    return AqiData(
      aqi: (decoded['aqi'] as num?)?.toInt() ?? 0,
      lat: (decoded['lat'] as num?)?.toDouble() ?? 0,
      lng: (decoded['lng'] as num?)?.toDouble() ?? 0,
      timestamp: timestamp,
      pm25: (decoded['pm25'] as num?)?.toDouble(),
      pm10: (decoded['pm10'] as num?)?.toDouble(),
      locationName: decoded['locationName'] as String?,
    );
  }

  Future<void> _saveTrendsToPrefs(
    String key,
    Map<String, List<AqiTrendDay>> trends,
  ) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.setString(
      '$_trendCachePrefix$key',
      jsonEncode({
        'week': trends['week']
                ?.map((day) => _encodeTrendDay(day))
                .toList() ??
            const [],
        'month': trends['month']
                ?.map((day) => _encodeTrendDay(day))
                .toList() ??
            const [],
      }),
    );
    await p.setString(
      '$_trendCacheTimePrefix$key',
      DateTime.now().toIso8601String(),
    );
  }

  Future<Map<String, List<AqiTrendDay>>?> _readTrendsFromPrefs(String key) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    final raw = p.getString('$_trendCachePrefix$key');
    if (raw == null) {
      return null;
    }
    final fetchedAt = DateTime.tryParse(
      p.getString('$_trendCacheTimePrefix$key') ?? '',
    );
    if (fetchedAt == null ||
        DateTime.now().difference(fetchedAt).inMilliseconds > _cacheIntervalMs) {
      return null;
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return {
      'week': _decodeTrendList(decoded['week']),
      'month': _decodeTrendList(decoded['month']),
    };
  }

  Map<String, dynamic> _encodeTrendDay(AqiTrendDay day) => {
        'date': day.date.toIso8601String(),
        'maxAqi': day.maxAqi,
        'avgAqi': day.avgAqi,
      };

  List<AqiTrendDay> _decodeTrendList(dynamic rawList) {
    if (rawList is! List) {
      return const <AqiTrendDay>[];
    }
    return rawList
        .whereType<Map>()
        .map(
          (item) => AqiTrendDay(
            date: DateTime.tryParse(item['date'] as String? ?? '') ??
                DateTime.now(),
            maxAqi: (item['maxAqi'] as num?)?.toInt() ?? 0,
            avgAqi: (item['avgAqi'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList();
  }

  String _locationKey(double lat, double lng) =>
      '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
}
