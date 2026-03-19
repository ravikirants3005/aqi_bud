/// AQI API - OpenAQ primary with Open-Meteo fallback
/// REQ-6.2: Cache, 30min interval, graceful API failure handling
library;

import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../core/config/runtime_config.dart';
import '../models/aqi_models.dart';

class AqiApi {
  AqiApi({RuntimeConfig? config}) : _config = config ?? RuntimeConfig.fallback;

  static const _openMeteoBaseUrl =
      'https://air-quality-api.open-meteo.com/v1/air-quality';
  static const _openAqBaseUrl = 'https://api.openaq.org/v3';
  static const _nominatimBaseUrl =
      'https://nominatim.openstreetmap.org/reverse';
  final RuntimeConfig _config;

  Map<String, String> get _openAqHeaders => {
        if (_config.aqiApiKey.isNotEmpty) 'X-API-Key': _config.aqiApiKey,
      };
  Map<String, String> get _reverseGeocodeHeaders => const {
        'User-Agent': 'AQIBuddy/1.0 (device-location reverse geocoding)',
        'Accept': 'application/json',
        'Accept-Language': 'en',
      };

  Future<AqiData?> fetchCurrentAqi(double lat, double lng) async {
    if (_config.aqiProvider == 'openaq' && _config.aqiApiKey.isNotEmpty) {
      final liveData = await _fetchCurrentAqiFromOpenAq(lat, lng);
      if (liveData != null) return liveData;
    }

    try {
      final uri = Uri.parse(
        '$_openMeteoBaseUrl?latitude=$lat&longitude=$lng&current=us_aqi,pm10,pm2_5',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final current = json['current'] as Map<String, dynamic>?;
      if (current == null) return null;

      final aqiRaw = current['us_aqi'];
      final aqi = aqiRaw is int
          ? aqiRaw
          : (aqiRaw is num ? aqiRaw.toInt() : 50);

      return AqiData(
        aqi: aqi.clamp(0, 500).toInt(),
        lat: lat,
        lng: lng,
        timestamp: DateTime.now(),
        pm25: _toDouble(current['pm2_5']),
        pm10: _toDouble(current['pm10']),
        locationName: await _resolveLocationName(lat, lng),
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, List<AqiTrendDay>>> fetchAqiTrends(
    double lat,
    double lng,
  ) async {
    final history = await fetchAqiHistory(lat, lng, days: 30);
    return _buildTrendBuckets(history);
  }

  Future<List<AqiHourlyPoint>> fetchAqiHistory(
    double lat,
    double lng, {
    int days = 30,
  }) async {
    if (_config.aqiProvider == 'openaq' && _config.aqiApiKey.isNotEmpty) {
      final liveHistory = await _fetchAqiHistoryFromOpenAq(
        lat,
        lng,
        days: days,
      );
      if (liveHistory.isNotEmpty) {
        return liveHistory;
      }
    }

    try {
      final today = DateTime.now();
      final startDate = _dateOnly(today.subtract(Duration(days: days - 1)));
      final endDate = _dateOnly(today);
      final uri = Uri.parse(
        '$_openMeteoBaseUrl?latitude=$lat&longitude=$lng&hourly=us_aqi&start_date=$startDate&end_date=$endDate&timezone=auto',
      );
      final resp = await http.get(uri).timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return const <AqiHourlyPoint>[];

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final hourly = json['hourly'] as Map<String, dynamic>?;
      if (hourly == null) return const <AqiHourlyPoint>[];

      final times = hourly['time'] as List<dynamic>? ?? [];
      final aqiList = hourly['us_aqi'] as List<dynamic>? ?? [];
      final points = <AqiHourlyPoint>[];

      for (var i = 0; i < times.length; i++) {
        final timestamp = DateTime.tryParse(times[i].toString());
        final aqi = _toInt(aqiList, i);
        if (timestamp == null || aqi == null) continue;
        points.add(
          AqiHourlyPoint(
            time: timestamp,
            aqi: aqi.clamp(0, 500).toInt(),
          ),
        );
      }

      points.sort((a, b) => a.time.compareTo(b.time));
      return points;
    } catch (_) {
      return const <AqiHourlyPoint>[];
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

  Future<AqiData?> _fetchCurrentAqiFromOpenAq(double lat, double lng) async {
    try {
      final candidates = await _fetchNearbyOpenAqLocations(lat, lng);

      for (final candidate in candidates) {
        final loc = candidate.data;
        final locationId = loc['id'] as int?;
        if (locationId == null) continue;

        final sensorsList = loc['sensors'] as List<dynamic>? ?? [];
        final sensorIdToParam = <int, String>{};
        for (final s in sensorsList) {
          final sensor = s as Map<String, dynamic>;
          final sid = sensor['id'] as int?;
          final param = sensor['parameter'] as Map<String, dynamic>?;
          final pname = param?['name'] as String?;
          if (sid != null && pname != null) {
            sensorIdToParam[sid] = pname;
          }
        }

        final latestUri = Uri.parse('$_openAqBaseUrl/locations/$locationId/latest');
        final latestResp = await http
            .get(latestUri, headers: _openAqHeaders)
            .timeout(const Duration(seconds: 10));
        if (latestResp.statusCode != 200) continue;

        final latestJson = jsonDecode(latestResp.body) as Map<String, dynamic>;
        final results = latestJson['results'] as List<dynamic>? ?? [];

        double? pm25;
        double? pm10;
        for (final r in results) {
          final row = r as Map<String, dynamic>;
          final sensorsId = row['sensorsId'] as int?;
          final paramName = sensorsId != null ? sensorIdToParam[sensorsId] : null;
          final value = _toDouble(row['value']);
          if (paramName == 'pm25' && value != null) pm25 = value;
          if (paramName == 'pm10' && value != null) pm10 = value;
        }

        final aqi = _pm25ToAqi(pm25) ?? _pm10ToAqi(pm10);
        if (aqi == null) {
          continue;
        }

        return AqiData(
          aqi: aqi.clamp(0, 500).toInt(),
          lat: lat,
          lng: lng,
          timestamp: DateTime.now(),
          pm25: pm25,
          pm10: pm10,
          locationName: await _resolveLocationName(lat, lng),
        );
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<List<AqiHourlyPoint>> _fetchAqiHistoryFromOpenAq(
    double lat,
    double lng,
    {
    required int days,
    }
  ) async {
    try {
      final candidates = await _fetchNearbyOpenAqLocations(lat, lng);
      final today = DateTime.now();
      final from =
          '${_dateOnly(today.subtract(Duration(days: days - 1)))}T00:00:00Z';
      final to = '${_dateOnly(today)}T23:59:59Z';
      List<AqiHourlyPoint> bestHistory = const <AqiHourlyPoint>[];

      for (final candidate in candidates) {
        final sensorsList = candidate.data['sensors'] as List<dynamic>? ?? [];
        final sensorsByParameter = <String, int>{};

        for (final sensorRaw in sensorsList.whereType<Map<String, dynamic>>()) {
          final sensorId = sensorRaw['id'] as int?;
          final parameter = sensorRaw['parameter'] as Map<String, dynamic>?;
          final parameterName = parameter?['name'] as String?;
          if (sensorId == null || parameterName == null) continue;
          if (parameterName == 'pm25' || parameterName == 'pm10') {
            sensorsByParameter.putIfAbsent(parameterName, () => sensorId);
          }
        }

        final pm25Hours = sensorsByParameter.containsKey('pm25')
            ? await _fetchOpenAqHourlySensorHistory(
                sensorId: sensorsByParameter['pm25']!,
                parameterName: 'pm25',
                from: from,
                to: to,
              )
            : const <DateTime, int>{};
        final pm10Hours = sensorsByParameter.containsKey('pm10')
            ? await _fetchOpenAqHourlySensorHistory(
                sensorId: sensorsByParameter['pm10']!,
                parameterName: 'pm10',
                from: from,
                to: to,
              )
            : const <DateTime, int>{};

        final merged = <DateTime, int>{};
        for (final entry in pm25Hours.entries) {
          merged[entry.key] = entry.value;
        }
        for (final entry in pm10Hours.entries) {
          final existing = merged[entry.key];
          merged[entry.key] =
              existing == null ? entry.value : (existing > entry.value ? existing : entry.value);
        }

        final history = merged.entries
            .map(
              (entry) => AqiHourlyPoint(
                time: entry.key,
                aqi: entry.value.clamp(0, 500).toInt(),
              ),
            )
            .toList()
          ..sort((a, b) => a.time.compareTo(b.time));

        if (history.length > bestHistory.length) {
          bestHistory = history;
        }
        if (history.length >= days * 12) {
          return history;
        }
      }

      return bestHistory;
    } catch (_) {
      return const <AqiHourlyPoint>[];
    }
  }

  Future<List<({Map<String, dynamic> data, double? distance})>>
      _fetchNearbyOpenAqLocations(
    double lat,
    double lng,
  ) async {
    final locationsUri = Uri.parse(
      '$_openAqBaseUrl/locations?coordinates=$lat,$lng&radius=20000&limit=10',
    );
    final locResp = await http
        .get(locationsUri, headers: _openAqHeaders)
        .timeout(const Duration(seconds: 10));
    if (locResp.statusCode != 200) return [];

    final locJson = jsonDecode(locResp.body) as Map<String, dynamic>;
    final locResults = locJson['results'] as List<dynamic>?;
    if (locResults == null || locResults.isEmpty) return [];

    final candidates = locResults
        .whereType<Map<String, dynamic>>()
        .map((location) => (
              data: location,
              distance: _distanceFromUser(
                userLat: lat,
                userLng: lng,
                location: location,
              ),
            ))
        .where((candidate) => candidate.distance != null)
        .toList()
      ..sort((a, b) => a.distance!.compareTo(b.distance!));

    return candidates;
  }

  Future<Map<DateTime, int>> _fetchOpenAqHourlySensorHistory({
    required int sensorId,
    required String parameterName,
    required String from,
    required String to,
  }) async {
    final uri = Uri.parse('$_openAqBaseUrl/sensors/$sensorId/hours')
        .replace(
      queryParameters: {
        'datetime_from': from,
        'datetime_to': to,
        'limit': '1000',
      },
    );
    final resp = await http
        .get(uri, headers: _openAqHeaders)
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) return const <DateTime, int>{};

    final json = jsonDecode(resp.body) as Map<String, dynamic>;
    final results = json['results'] as List<dynamic>? ?? const [];
    final output = <DateTime, int>{};

    for (final rowRaw in results.whereType<Map<String, dynamic>>()) {
      final time = _openAqPeriodDateTime(rowRaw);
      if (time == null) continue;
      final summary = rowRaw['summary'] as Map<String, dynamic>?;
      final avgConcentration = _toDouble(summary?['avg'] ?? rowRaw['value']);
      final avgAqi = _aqiFromParameter(parameterName, avgConcentration);
      if (avgAqi == null) continue;

      final existing = output[time];
      output[time] = existing == null ? avgAqi : (existing > avgAqi ? existing : avgAqi);
    }

    return output;
  }

  Map<String, List<AqiTrendDay>> _buildTrendBuckets(List<AqiHourlyPoint> history) {
    if (history.isEmpty) {
      return const {'week': [], 'month': []};
    }

    final groupedValues = <DateTime, List<int>>{};
    for (final point in history) {
      final day = DateTime(point.time.year, point.time.month, point.time.day);
      groupedValues.putIfAbsent(day, () => <int>[]).add(point.aqi);
    }

    final all = groupedValues.entries.map((entry) {
      final values = entry.value;
      final max = values.reduce((a, b) => a > b ? a : b);
      final avg = (values.reduce((a, b) => a + b) / values.length).round();
      return AqiTrendDay(date: entry.key, maxAqi: max, avgAqi: avg);
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    final month = all.length > 30 ? all.sublist(all.length - 30) : all;
    final week = month.length > 7 ? month.sublist(month.length - 7) : month;
    return {'week': week, 'month': month};
  }

  int? _pm25ToAqi(double? pm25) {
    if (pm25 == null) return null;
    const breakpoints = [
      (0.0, 12.0, 0, 50),
      (12.1, 35.4, 51, 100),
      (35.5, 55.4, 101, 150),
      (55.5, 150.4, 151, 200),
      (150.5, 250.4, 201, 300),
      (250.5, 500.4, 301, 500),
    ];
    for (final (bpLo, bpHi, aqiLo, aqiHi) in breakpoints) {
      if (pm25 >= bpLo && pm25 <= bpHi) {
        return (aqiLo + (aqiHi - aqiLo) * (pm25 - bpLo) / (bpHi - bpLo)).round();
      }
    }
    return pm25 > 500 ? 500 : null;
  }

  int? _pm10ToAqi(double? pm10) {
    if (pm10 == null) return null;
    const breakpoints = [
      (0.0, 54.0, 0, 50),
      (55.0, 154.0, 51, 100),
      (155.0, 254.0, 101, 150),
      (255.0, 354.0, 151, 200),
      (355.0, 424.0, 201, 300),
      (425.0, 604.0, 301, 500),
    ];
    for (final (bpLo, bpHi, aqiLo, aqiHi) in breakpoints) {
      if (pm10 >= bpLo && pm10 <= bpHi) {
        return (aqiLo + (aqiHi - aqiLo) * (pm10 - bpLo) / (bpHi - bpLo)).round();
      }
    }
    return pm10 > 604 ? 500 : null;
  }

  int? _aqiFromParameter(String parameterName, double? value) {
    switch (parameterName) {
      case 'pm25':
        return _pm25ToAqi(value);
      case 'pm10':
        return _pm10ToAqi(value);
      default:
        return null;
    }
  }

  Future<String?> _resolveLocationName(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isEmpty) return null;
      final place = placemarks.first;
      final resolved = _compactLocationLabel({
        'suburb': place.subLocality,
        'city': place.locality,
        'state_district': place.subAdministrativeArea,
        'state': place.administrativeArea,
        'country': place.country,
      });
      if (resolved != null) return resolved;
    } catch (_) {
      // Fall back to HTTP reverse geocoding on platforms without geocoding support.
    }

    return _resolveLocationNameFromNetwork(lat, lng);
  }

  Future<String?> _resolveLocationNameFromNetwork(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        '$_nominatimBaseUrl?lat=$lat&lon=$lng&format=jsonv2&addressdetails=1&zoom=14',
      );
      final resp = await http
          .get(uri, headers: _reverseGeocodeHeaders)
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode != 200) return null;

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      final address = json['address'] as Map<String, dynamic>?;
      final resolved = _compactLocationLabel(address);
      if (resolved != null) return resolved;

      final displayName = (json['display_name'] as String?)?.trim();
      if (displayName == null || displayName.isEmpty) return null;
      return displayName.split(',').take(3).join(', ').trim();
    } catch (_) {
      return null;
    }
  }

  String? _compactLocationLabel(Map<String, dynamic>? address) {
    if (address == null) return null;

    final candidates = <String?>[
      address['suburb']?.toString(),
      address['neighbourhood']?.toString(),
      address['hamlet']?.toString(),
      address['village']?.toString(),
      address['town']?.toString(),
      address['city']?.toString(),
      address['municipality']?.toString(),
      address['county']?.toString(),
      address['state_district']?.toString(),
      address['state']?.toString(),
      address['country']?.toString(),
    ];

    final parts = <String>[];
    for (final candidate in candidates) {
      final value = candidate?.trim();
      if (value == null || value.isEmpty) continue;
      final exists = parts.any(
        (part) => part.toLowerCase() == value.toLowerCase(),
      );
      if (!exists) {
        parts.add(value);
      }
      if (parts.length == 2) break;
    }

    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  String _dateOnly(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  DateTime? _openAqPeriodDateTime(Map<String, dynamic> row) {
    final period = row['period'] as Map<String, dynamic>?;
    final from = period?['datetimeFrom'] as Map<String, dynamic>?;
    final raw = from?['local'] as String? ?? from?['utc'] as String?;
    final parsed = raw == null ? null : DateTime.tryParse(raw);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day, parsed.hour);
  }

  double? _distanceFromUser({
    required double userLat,
    required double userLng,
    required Map<String, dynamic> location,
  }) {
    final coordinates = location['coordinates'] as Map<String, dynamic>?;
    final latValue = _toDouble(
      coordinates?['latitude'] ?? location['latitude'] ?? location['lat'],
    );
    final lngValue = _toDouble(
      coordinates?['longitude'] ?? location['longitude'] ?? location['lng'],
    );
    if (latValue == null || lngValue == null) {
      return null;
    }
    return Geolocator.distanceBetween(userLat, userLng, latValue, lngValue);
  }
}
