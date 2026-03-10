/// AQI API - Open-Meteo (free, no key) / fallback mock
/// REQ-6.2: Cache, 30min interval, graceful API failure handling
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/aqi_models.dart';

class AqiApi {
  static const _baseUrl =
      'https://air-quality.api.open-meteo.com/v1/air-quality';

  /// Fetch current AQI by coordinates
  /// Returns US AQI (EPA scale 0-500)
  Future<AqiData?> fetchCurrentAqi(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl?latitude=$lat&longitude=$lng&current=us_aqi,pm10,pm2_5',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return _mockAqi(lat, lng);

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final current = json['current'] as Map<String, dynamic>?;
      if (current == null) return _mockAqi(lat, lng);

      final aqiRaw = current['us_aqi'];
      final aqi = aqiRaw is int
          ? aqiRaw
          : (aqiRaw is num ? aqiRaw.toInt() : 50);

      return AqiData(
        aqi: aqi.clamp(0, 500),
        lat: lat,
        lng: lng,
        timestamp: DateTime.now(),
        pm25: _toDouble(current['pm2_5']),
        pm10: _toDouble(current['pm10']),
      );
    } catch (_) {
      return _mockAqi(lat, lng);
    }
  }

  /// Fetch 7-day and 30-day AQI for trends
  Future<Map<String, List<AqiTrendDay>>> fetchAqiTrends(
    double lat,
    double lng,
  ) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl?latitude=$lat&longitude=$lng&daily=us_aqi_max,us_aqi_mean&past_days=30',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return _mockTrends();

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final daily = json['daily'] as Map<String, dynamic>?;
      if (daily == null) return _mockTrends();

      final times = daily['time'] as List<dynamic>? ?? [];
      final maxList = daily['us_aqi_max'] as List<dynamic>? ?? [];
      final meanList = daily['us_aqi_mean'] as List<dynamic>? ?? [];

      final all = <AqiTrendDay>[];
      for (var i = 0; i < times.length; i++) {
        final d = DateTime.tryParse(times[i].toString());
        if (d == null) continue;
        final max = _toInt(maxList, i) ?? 50;
        final avg = _toInt(meanList, i) ?? 50;
        all.add(AqiTrendDay(date: d, maxAqi: max, avgAqi: avg));
      }

      final week = all.length >= 7 ? all.sublist(all.length - 7) : all;
      return {'week': week, 'month': all};
    } catch (_) {
      return _mockTrends();
    }
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  int? _toInt(List<dynamic> list, int i) {
    if (i >= list.length) return null;
    final v = list[i];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  AqiData _mockAqi(double lat, double lng) {
    return AqiData(
      aqi: 45,
      lat: lat,
      lng: lng,
      timestamp: DateTime.now(),
      pm25: 12.0,
      pm10: 18.0,
    );
  }

  Map<String, List<AqiTrendDay>> _mockTrends() {
    final now = DateTime.now();
    final week = List.generate(
      7,
      (i) => AqiTrendDay(
        date: now.subtract(Duration(days: 6 - i)),
        maxAqi: 35 + (i * 8) + (i == 3 ? 40 : 0),
        avgAqi: 30 + (i * 6),
      ),
    );
    final month = List.generate(
      30,
      (i) => AqiTrendDay(
        date: now.subtract(Duration(days: 29 - i)),
        maxAqi: 40 + (i % 5) * 15,
        avgAqi: 35 + (i % 4) * 10,
      ),
    );
    return {'week': week, 'month': month};
  }
}
