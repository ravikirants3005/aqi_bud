/// Exposure tracking - REQ-5.x
/// REQ-5.1: Exposure score 0-100
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../models/aqi_models.dart';
import '../models/exposure_models.dart';
import '../models/user_models.dart';

class ExposureRepository {
  ExposureRepository({SharedPreferences? prefs}) : _prefs = prefs;

  final SharedPreferences? _prefs;
  static const _prefix = 'exp_';

  double calculateExposureScore({
    required int maxAqi,
    required Duration outdoorMinutes,
  }) {
    final aqiFactor = (maxAqi / 500).clamp(0.0, 1.0);
    final timeFactor = (outdoorMinutes.inMinutes / 480).clamp(0.0, 1.0);
    return (aqiFactor * 50 + timeFactor * 50).clamp(0.0, 100.0);
  }

  double safeExposureLimit(HealthSensitivity healthSensitivity) {
    switch (healthSensitivity) {
      case HealthSensitivity.normal:
        return 65;
      case HealthSensitivity.sensitive:
        return 58;
      case HealthSensitivity.asthmatic:
      case HealthSensitivity.elderly:
        return 52;
    }
  }

  Future<void> recordExposure(ExposureRecord record) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    final key = '$_prefix${record.date.toIso8601String().split("T").first}';
    await p.setString(key, _encodeRecord(record));
  }

  Future<List<ExposureRecord>> getWeeklyExposure() async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    final records = <ExposureRecord>[];
    final now = DateTime.now();
    for (var i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: i));
      final raw = p.getString('$_prefix${_dateStr(d)}');
      if (raw == null) continue;
      final record = _decodeRecord(raw, d);
      if (record != null) records.add(record);
    }
    records.sort((a, b) => a.date.compareTo(b.date));
    return records;
  }

  Future<List<ExposureRecord>> getMonthlyExposure() async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    final records = <ExposureRecord>[];
    final now = DateTime.now();
    for (var i = 0; i < 30; i++) {
      final d = now.subtract(Duration(days: i));
      final raw = p.getString('$_prefix${_dateStr(d)}');
      if (raw == null) continue;
      final record = _decodeRecord(raw, d);
      if (record != null) records.add(record);
    }
    records.sort((a, b) => a.date.compareTo(b.date));
    return records;
  }

  Future<bool> hasHighExposureStreak() async {
    final week = await getWeeklyExposure();
    return week.where((record) => record.score >= 60).length >= 7;
  }

  Future<ExposureDashboardData> buildDashboard({
    required AqiData currentAqi,
    required List<AqiTrendDay> weeklyTrend,
    required List<AqiTrendDay> monthlyTrend,
    required List<SavedLocation> savedLocations,
    required HealthSensitivity healthSensitivity,
    required Map<String, AqiData?> locationCurrentAqi,
    required Map<String, List<AqiTrendDay>> locationTrends,
  }) async {
    final todayExposures = <LocationExposure>[
      LocationExposure(
        lat: currentAqi.lat,
        lng: currentAqi.lng,
        name: currentAqi.locationName ?? 'Current location',
        aqi: currentAqi.aqi,
        duration: _baseOutdoorDuration(healthSensitivity, currentAqi.aqi),
      ),
    ];

    for (final location in savedLocations) {
      final locationAqi = locationCurrentAqi[location.id];
      if (locationAqi == null) continue;
      todayExposures.add(
        LocationExposure(
          lat: location.lat,
          lng: location.lng,
          name: location.name,
          aqi: locationAqi.aqi,
          duration: _frequentLocationDuration(locationAqi.aqi),
        ),
      );
    }

    final todayOutdoorMinutes = todayExposures.fold<Duration>(
      Duration.zero,
      (total, item) => total + item.duration,
    );
    final todayMaxAqi = todayExposures.fold<int>(
      currentAqi.aqi,
      (maxValue, item) => item.aqi > maxValue ? item.aqi : maxValue,
    );
    final todayRecord = ExposureRecord(
      id: 'day_${_dateStr(DateTime.now())}',
      date: DateTime.now(),
      score: calculateExposureScore(
        maxAqi: todayMaxAqi,
        outdoorMinutes: todayOutdoorMinutes,
      ),
      maxAqi: todayMaxAqi,
      outdoorMinutes: todayOutdoorMinutes,
      locationExposures: todayExposures,
    );
    await recordExposure(todayRecord);

    final weeklyExposure = _mergeTrendWithRecords(
      trend: weeklyTrend,
      existing: await getWeeklyExposure(),
      fallbackLocationCount: savedLocations.length,
      todayRecord: todayRecord,
    );
    final monthlyExposure = _mergeTrendWithRecords(
      trend: monthlyTrend,
      existing: await getMonthlyExposure(),
      fallbackLocationCount: savedLocations.length,
      todayRecord: todayRecord,
    );

    final highAqiDays = weeklyTrend.where((day) => day.maxAqi >= 150).length;
    final bestDay =
        weeklyExposure.reduce((a, b) => a.score <= b.score ? a : b);
    final worstDay =
        weeklyExposure.reduce((a, b) => a.score >= b.score ? a : b);
    final locationInsights = _buildLocationInsights(
      savedLocations: savedLocations,
      locationCurrentAqi: locationCurrentAqi,
      locationTrends: locationTrends,
    );
    final safeLimit = safeExposureLimit(healthSensitivity);

    return ExposureDashboardData(
      todayRecord: todayRecord,
      weeklyExposure: weeklyExposure,
      monthlyExposure: monthlyExposure,
      highAqiDays: highAqiDays,
      bestDay: bestDay,
      worstDay: worstDay,
      locationInsights: locationInsights,
      alerts: _buildAlerts(
        healthSensitivity: healthSensitivity,
        todayRecord: todayRecord,
        weeklyExposure: weeklyExposure,
        safeLimit: safeLimit,
      ),
      suggestions: _buildSuggestions(
        healthSensitivity: healthSensitivity,
        todayRecord: todayRecord,
        weeklyExposure: weeklyExposure,
        locationInsights: locationInsights,
        currentAqi: currentAqi.aqi,
      ),
      monthlyPatternInsight: _buildMonthlyPatternInsight(monthlyExposure),
      safeLimit: safeLimit,
    );
  }

  Duration _baseOutdoorDuration(
    HealthSensitivity healthSensitivity,
    int currentAqi,
  ) {
    final baseMinutes = switch (healthSensitivity) {
      HealthSensitivity.normal => 95,
      HealthSensitivity.sensitive => 80,
      HealthSensitivity.asthmatic => 65,
      HealthSensitivity.elderly => 60,
    };
    final adjustment = currentAqi >= 150
        ? 20
        : currentAqi >= 100
            ? 10
            : 0;
    return Duration(minutes: baseMinutes + adjustment);
  }

  Duration _frequentLocationDuration(int aqi) {
    if (aqi >= 150) return const Duration(minutes: 40);
    if (aqi >= 100) return const Duration(minutes: 30);
    return const Duration(minutes: 20);
  }

  List<ExposureRecord> _mergeTrendWithRecords({
    required List<AqiTrendDay> trend,
    required List<ExposureRecord> existing,
    required int fallbackLocationCount,
    required ExposureRecord todayRecord,
  }) {
    if (trend.isEmpty) {
      return [todayRecord];
    }

    final byDate = <String, ExposureRecord>{
      for (final record in existing) _dateStr(record.date): record,
    };

    return trend.map((day) {
      final dateKey = _dateStr(day.date);
      if (dateKey == _dateStr(todayRecord.date)) return todayRecord;

      final stored = byDate[dateKey];
      if (stored != null) return stored;

      final estimatedDuration = Duration(
        minutes: 55 +
            (fallbackLocationCount * 10) +
            (day.maxAqi >= 150
                ? 25
                : day.maxAqi >= 100
                    ? 15
                    : 0),
      );
      return ExposureRecord(
        id: 'estimated_$dateKey',
        date: day.date,
        score: calculateExposureScore(
          maxAqi: day.maxAqi,
          outdoorMinutes: estimatedDuration,
        ),
        maxAqi: day.maxAqi,
        outdoorMinutes: estimatedDuration,
      );
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  List<FrequentLocationInsight> _buildLocationInsights({
    required List<SavedLocation> savedLocations,
    required Map<String, AqiData?> locationCurrentAqi,
    required Map<String, List<AqiTrendDay>> locationTrends,
  }) {
    return savedLocations.map((location) {
      final current = locationCurrentAqi[location.id];
      final weekly = locationTrends[location.id] ?? const <AqiTrendDay>[];
      final weeklyAverage = weekly.isEmpty
          ? (current?.aqi ?? location.lastAqi ?? 0).toDouble()
          : weekly.map((day) => day.avgAqi).reduce((a, b) => a + b) /
              weekly.length;
      final worstAqi = weekly.isEmpty
          ? current?.aqi ?? location.lastAqi ?? 0
          : weekly.map((day) => day.maxAqi).reduce((a, b) => a > b ? a : b);

      return FrequentLocationInsight(
        locationId: location.id,
        name: location.name,
        currentAqi: current?.aqi ?? location.lastAqi ?? 0,
        weeklyAverageAqi: weeklyAverage,
        worstAqi: worstAqi,
        insight: _locationInsightText(
          name: location.name,
          currentAqi: current?.aqi ?? location.lastAqi ?? 0,
          weeklyAverageAqi: weeklyAverage,
          worstAqi: worstAqi,
        ),
      );
    }).toList()
      ..sort((a, b) => b.weeklyAverageAqi.compareTo(a.weeklyAverageAqi));
  }

  String _locationInsightText({
    required String name,
    required int currentAqi,
    required double weeklyAverageAqi,
    required int worstAqi,
  }) {
    if (weeklyAverageAqi >= 120) {
      return 'AQI in $name is consistently elevated. Plan shorter visits or use a mask.';
    }
    if (worstAqi >= 150) {
      return '$name has repeated unhealthy spikes. Avoid peak outdoor windows there.';
    }
    if (currentAqi <= 80 && weeklyAverageAqi <= 90) {
      return '$name is one of your safer regular locations this week.';
    }
    return '$name has moderate pollution levels. Check AQI before longer trips.';
  }

  List<ExposureAlert> _buildAlerts({
    required HealthSensitivity healthSensitivity,
    required ExposureRecord todayRecord,
    required List<ExposureRecord> weeklyExposure,
    required double safeLimit,
  }) {
    final alerts = <ExposureAlert>[];
    final highExposureMinutes = todayRecord.locationExposures
        .where((item) => item.aqi >= 150)
        .fold<int>(0, (total, item) => total + item.duration.inMinutes);

    if (todayRecord.score >= safeLimit) {
      alerts.add(
        ExposureAlert(
          title: 'Daily exposure above safe limit',
          message:
              'Your score is ${todayRecord.score.toStringAsFixed(0)} today, above the ${safeLimit.toStringAsFixed(0)} limit for ${healthSensitivity.label.toLowerCase()} users.',
          severity: todayRecord.score >= safeLimit + 12
              ? ExposureAlertSeverity.critical
              : ExposureAlertSeverity.warning,
        ),
      );
    }

    final highAqiDurationLimit = switch (healthSensitivity) {
      HealthSensitivity.normal => 90,
      HealthSensitivity.sensitive => 75,
      HealthSensitivity.asthmatic => 60,
      HealthSensitivity.elderly => 60,
    };
    if (highExposureMinutes >= highAqiDurationLimit) {
      alerts.add(
        ExposureAlert(
          title: 'Extended stay in AQI 150+ zone',
          message:
              'You spent about $highExposureMinutes minutes in unhealthy air today. Reduce outdoor time and recover indoors.',
          severity: ExposureAlertSeverity.critical,
        ),
      );
    }

    final lastThree = weeklyExposure.reversed.take(3).toList();
    if (lastThree.length == 3 &&
        lastThree.every((record) => record.score >= safeLimit)) {
      alerts.add(
        const ExposureAlert(
          title: '3-day high exposure streak',
          message:
              'Your exposure has been high for 3 days. Try to reduce outdoor time tomorrow.',
          severity: ExposureAlertSeverity.warning,
        ),
      );
    }

    return alerts;
  }

  List<String> _buildSuggestions({
    required HealthSensitivity healthSensitivity,
    required ExposureRecord todayRecord,
    required List<ExposureRecord> weeklyExposure,
    required List<FrequentLocationInsight> locationInsights,
    required int currentAqi,
  }) {
    final suggestions = <String>[];
    final recentHighDays = weeklyExposure
        .where((record) => record.score >= safeExposureLimit(healthSensitivity))
        .length;

    if (recentHighDays >= 3) {
      suggestions.add(
        'Your exposure has been high for $recentHighDays days. Try to reduce outdoor time tomorrow.',
      );
    }

    final riskyLocation = locationInsights
        .where((item) => item.weeklyAverageAqi >= 120)
        .cast<FrequentLocationInsight?>()
        .firstWhere((item) => item != null, orElse: () => null);
    if (riskyLocation != null) {
      suggestions.add(
        'AQI in your saved location "${riskyLocation.name}" is consistently above 120. Consider wearing a mask.',
      );
    }

    if (currentAqi >= 150) {
      suggestions.add(
        'Current AQI is unhealthy. Shift exercise indoors and keep windows closed during peak hours.',
      );
    } else if (currentAqi >= 100) {
      suggestions.add(
        'AQI is elevated right now. Prefer shorter outdoor trips and avoid heavy exertion.',
      );
    }

    if (todayRecord.outdoorMinutes.inMinutes >= 120) {
      suggestions.add(
        'You logged over ${todayRecord.outdoorMinutes.inMinutes} minutes outdoors today. Add an indoor recovery window this evening.',
      );
    }

    if (healthSensitivity == HealthSensitivity.asthmatic ||
        healthSensitivity == HealthSensitivity.elderly) {
      suggestions.add(
        'Because your health profile is ${healthSensitivity.label.toLowerCase()}, keep a well-fitted mask and medication ready on poor-air days.',
      );
    }

    return suggestions.take(4).toList();
  }

  String _buildMonthlyPatternInsight(List<ExposureRecord> monthlyExposure) {
    if (monthlyExposure.isEmpty) {
      return 'Not enough monthly exposure data yet.';
    }

    final weekend = monthlyExposure
        .where((record) =>
            record.date.weekday == DateTime.saturday ||
            record.date.weekday == DateTime.sunday)
        .toList();
    final weekday = monthlyExposure
        .where((record) =>
            record.date.weekday != DateTime.saturday &&
            record.date.weekday != DateTime.sunday)
        .toList();
    final monthlyAverage = monthlyExposure
            .map((record) => record.score)
            .reduce((a, b) => a + b) /
        monthlyExposure.length;

    if (weekend.isEmpty || weekday.isEmpty) {
      return 'Average monthly exposure score is ${monthlyAverage.toStringAsFixed(0)}.';
    }

    final weekendAverage =
        weekend.map((record) => record.score).reduce((a, b) => a + b) /
            weekend.length;
    final weekdayAverage =
        weekday.map((record) => record.score).reduce((a, b) => a + b) /
            weekday.length;
    final difference = (weekendAverage - weekdayAverage).abs();

    if (difference < 6) {
      return 'Exposure stayed fairly stable this month with an average score of ${monthlyAverage.toStringAsFixed(0)}.';
    }

    final direction =
        weekendAverage > weekdayAverage ? 'weekends' : 'weekdays';
    return 'Pollution cycles are visible this month: $direction are averaging ${difference.toStringAsFixed(0)} points higher exposure than the rest of the week.';
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _encodeRecord(ExposureRecord record) => jsonEncode({
        'id': record.id,
        'score': record.score,
        'maxAqi': record.maxAqi,
        'outdoorMinutes': record.outdoorMinutes.inMinutes,
        'locationExposures': record.locationExposures
            .map((item) => {
                  'lat': item.lat,
                  'lng': item.lng,
                  'name': item.name,
                  'aqi': item.aqi,
                  'duration': item.duration.inMinutes,
                })
            .toList(),
      });

  ExposureRecord? _decodeRecord(String raw, DateTime date) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return _decodeLegacyRecord(raw, date);
      }
      final exposureData = decoded['locationExposures'];
      final locationExposures = exposureData is List
          ? exposureData
              .whereType<Map>()
              .map(
                (item) => LocationExposure(
                  lat: (item['lat'] as num?)?.toDouble() ?? 0,
                  lng: (item['lng'] as num?)?.toDouble() ?? 0,
                  name: item['name'] as String?,
                  aqi: (item['aqi'] as num?)?.toInt() ?? 0,
                  duration: Duration(
                    minutes: (item['duration'] as num?)?.toInt() ?? 0,
                  ),
                ),
              )
              .toList()
          : const <LocationExposure>[];

      return ExposureRecord(
        id: decoded['id'] as String? ?? 'unknown',
        date: date,
        score: (decoded['score'] as num?)?.toDouble() ?? 0,
        maxAqi: (decoded['maxAqi'] as num?)?.toInt() ?? 0,
        outdoorMinutes: Duration(
          minutes: (decoded['outdoorMinutes'] as num?)?.toInt() ?? 0,
        ),
        locationExposures: locationExposures,
      );
    } catch (_) {
      return _decodeLegacyRecord(raw, date);
    }
  }

  ExposureRecord? _decodeLegacyRecord(String raw, DateTime date) {
    final parts = raw.split('|');
    if (parts.length < 4) return null;
    return ExposureRecord(
      id: parts[0],
      date: date,
      score: double.tryParse(parts[1]) ?? 0,
      maxAqi: int.tryParse(parts[2]) ?? 0,
      outdoorMinutes: Duration(minutes: int.tryParse(parts[3]) ?? 0),
    );
  }
}
