/// AQI repository - caches and throttles API (REQ-6.2)
library;

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/aqi_api.dart';
import '../models/aqi_models.dart';

class AqiRepository {
  AqiRepository({AqiApi? api, SharedPreferences? prefs})
    : _api = api ?? AqiApi(),
      _prefs = prefs;

  final AqiApi _api;
  final SharedPreferences? _prefs;

  static const _currentCachePrefix = 'aqi_cache_';
  static const _historyCachePrefix = 'aqi_history_';
  static const _historyCacheTimePrefix = 'aqi_history_time_';
  static const _trendCachePrefix = 'aqi_trends_';
  static const _trendCacheTimePrefix = 'aqi_trends_time_';
  static const _currentCacheIntervalMs = 2 * 60 * 1000; // 2 min
  static const _historyCacheIntervalMs = 10 * 60 * 1000; // 10 min
  static const _trendCacheIntervalMs = 10 * 60 * 1000; // 10 min

  final Map<String, AqiData> _memoryCurrentCache = {};
  final Map<String, List<AqiHourlyPoint>> _memoryHistoryCache = {};
  final Map<String, Map<String, List<AqiTrendDay>>> _memoryTrendCache = {};
  final Map<String, DateTime> _memoryCurrentFetchTimes = {};
  final Map<String, DateTime> _memoryHistoryFetchTimes = {};
  final Map<String, DateTime> _memoryTrendFetchTimes = {};

  Future<AqiData?> getCurrentAqi(double lat, double lng) async {
    final key = _locationKey(lat, lng);
    if (_shouldUseCurrentCache(key)) {
      debugPrint('AQI REPO: Using memory cache for $key');
      return _memoryCurrentCache[key];
    }

    debugPrint('AQI REPO: Fetching fresh data for $lat, $lng');
    final data = await _api.fetchCurrentAqi(lat, lng);
    if (data != null) {
      _memoryCurrentCache[key] = data;
      _memoryCurrentFetchTimes[key] = DateTime.now();
      await _saveCurrentToPrefs(key, data);
      return data;
    }

    debugPrint('AQI REPO: API failed, checking persistent cache for $key');
    final cached = await _readCurrentFromPrefs(key);
    if (cached != null) {
      _memoryCurrentCache[key] = cached;
      _memoryCurrentFetchTimes[key] = DateTime.now();
      return cached;
    }
    return null;
  }

  Future<Map<String, List<AqiTrendDay>>> getAqiTrends(
    double lat,
    double lng,
  ) async {
    final history = await getAqiHistory(lat, lng);
    if (history.isNotEmpty) {
      final derived = buildTrendsFromHistory(history);
      _memoryTrendCache[_locationKey(lat, lng)] = derived;
      _memoryTrendFetchTimes[_locationKey(lat, lng)] = DateTime.now();
      await _saveTrendsToPrefs(_locationKey(lat, lng), derived);
      return derived;
    }

    final key = _locationKey(lat, lng);
    if (_shouldUseTrendCache(key)) {
      return _memoryTrendCache[key]!;
    }

    final liveTrends = await _api.fetchAqiTrends(lat, lng);
    final hasLiveData =
        (liveTrends['week']?.isNotEmpty ?? false) ||
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
      _memoryTrendFetchTimes[key] = DateTime.now();
      return cached;
    }

    return const {'week': [], 'month': []};
  }

  Future<List<AqiHourlyPoint>> getAqiHistory(
    double lat,
    double lng, {
    int days = 30,
  }) async {
    final key = _locationKey(lat, lng);
    if (_shouldUseHistoryCache(key)) {
      return _memoryHistoryCache[key]!;
    }

    final liveHistory = await _api.fetchAqiHistory(lat, lng, days: days);
    if (liveHistory.isNotEmpty) {
      _memoryHistoryCache[key] = liveHistory;
      _memoryHistoryFetchTimes[key] = DateTime.now();
      await _saveHistoryToPrefs(key, liveHistory);
      return liveHistory;
    }

    final cached = await _readHistoryFromPrefs(key);
    if (cached != null) {
      _memoryHistoryCache[key] = cached;
      _memoryHistoryFetchTimes[key] = DateTime.now();
      return cached;
    }

    return const <AqiHourlyPoint>[];
  }

  Map<String, List<AqiTrendDay>> buildTrendsFromHistory(
    List<AqiHourlyPoint> history,
  ) {
    if (history.isEmpty) {
      return const {'week': [], 'month': []};
    }

    final grouped = <DateTime, List<int>>{};
    for (final point in history) {
      final day = DateTime(point.time.year, point.time.month, point.time.day);
      grouped.putIfAbsent(day, () => <int>[]).add(point.aqi);
    }

    final days = grouped.entries.map((entry) {
      final values = entry.value;
      final max = values.reduce((a, b) => a > b ? a : b);
      final avg = (values.reduce((a, b) => a + b) / values.length).round();
      return AqiTrendDay(date: entry.key, maxAqi: max, avgAqi: avg);
    }).toList()..sort((a, b) => a.date.compareTo(b.date));

    final month = days.length > 30 ? days.sublist(days.length - 30) : days;
    final week = month.length > 7 ? month.sublist(month.length - 7) : month;
    return {'week': week, 'month': month};
  }

  bool _shouldUseCurrentCache(String key) {
    final fetchedAt = _memoryCurrentFetchTimes[key];
    final current = _memoryCurrentCache[key];
    if (fetchedAt == null || current == null) {
      return false;
    }
    return DateTime.now().difference(fetchedAt).inMilliseconds <=
        _currentCacheIntervalMs;
  }

  bool _shouldUseTrendCache(String key) {
    final fetchedAt = _memoryTrendFetchTimes[key];
    final trends = _memoryTrendCache[key];
    if (fetchedAt == null || trends == null) {
      return false;
    }
    return DateTime.now().difference(fetchedAt).inMilliseconds <=
        _trendCacheIntervalMs;
  }

  bool _shouldUseHistoryCache(String key) {
    final fetchedAt = _memoryHistoryFetchTimes[key];
    final history = _memoryHistoryCache[key];
    if (fetchedAt == null || history == null) {
      return false;
    }
    return DateTime.now().difference(fetchedAt).inMilliseconds <=
        _historyCacheIntervalMs;
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
        DateTime.tryParse(decoded['timestamp'] as String? ?? '') ??
        DateTime.now();
    if (DateTime.now().difference(timestamp).inMilliseconds >
        _currentCacheIntervalMs) {
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
        'week':
            trends['week']?.map((day) => _encodeTrendDay(day)).toList() ??
            const [],
        'month':
            trends['month']?.map((day) => _encodeTrendDay(day)).toList() ??
            const [],
      }),
    );
    await p.setString(
      '$_trendCacheTimePrefix$key',
      DateTime.now().toIso8601String(),
    );
  }

  Future<void> _saveHistoryToPrefs(
    String key,
    List<AqiHourlyPoint> history,
  ) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    await p.setString(
      '$_historyCachePrefix$key',
      jsonEncode(
        history
            .map(
              (point) => {
                'time': point.time.toIso8601String(),
                'aqi': point.aqi,
              },
            )
            .toList(),
      ),
    );
    await p.setString(
      '$_historyCacheTimePrefix$key',
      DateTime.now().toIso8601String(),
    );
  }

  Future<Map<String, List<AqiTrendDay>>?> _readTrendsFromPrefs(
    String key,
  ) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    final raw = p.getString('$_trendCachePrefix$key');
    if (raw == null) {
      return null;
    }
    final fetchedAt = DateTime.tryParse(
      p.getString('$_trendCacheTimePrefix$key') ?? '',
    );
    if (fetchedAt == null ||
        DateTime.now().difference(fetchedAt).inMilliseconds >
            _trendCacheIntervalMs) {
      return null;
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return {
      'week': _decodeTrendList(decoded['week']),
      'month': _decodeTrendList(decoded['month']),
    };
  }

  Future<List<AqiHourlyPoint>?> _readHistoryFromPrefs(String key) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    final raw = p.getString('$_historyCachePrefix$key');
    if (raw == null) {
      return null;
    }
    final fetchedAt = DateTime.tryParse(
      p.getString('$_historyCacheTimePrefix$key') ?? '',
    );
    if (fetchedAt == null ||
        DateTime.now().difference(fetchedAt).inMilliseconds >
            _historyCacheIntervalMs) {
      return null;
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      return null;
    }

    return decoded
        .whereType<Map>()
        .map(
          (item) => AqiHourlyPoint(
            time:
                DateTime.tryParse(item['time'] as String? ?? '') ??
                DateTime.now(),
            aqi: (item['aqi'] as num?)?.toInt() ?? 0,
          ),
        )
        .toList()
      ..sort((a, b) => a.time.compareTo(b.time));
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
            date:
                DateTime.tryParse(item['date'] as String? ?? '') ??
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
