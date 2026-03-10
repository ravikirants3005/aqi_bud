/// Exposure tracking - REQ-5.x
/// REQ-5.1: Exposure score 0-100
library;

import 'package:shared_preferences/shared_preferences.dart';

import '../models/aqi_models.dart';
import '../models/exposure_models.dart';

class ExposureRepository {
  ExposureRepository({SharedPreferences? prefs}) : _prefs = prefs;

  final SharedPreferences? _prefs;
  static const _prefix = 'exp_';

  /// Calculate exposure score (0-100) from AQI + outdoor time
  /// Higher AQI + more time = higher score
  double calculateExposureScore({
    required int maxAqi,
    required Duration outdoorMinutes,
  }) {
    final aqiFactor = (maxAqi / 500).clamp(0.0, 1.0);
    final timeFactor = (outdoorMinutes.inMinutes / 480).clamp(0.0, 1.0);
    return (aqiFactor * 50 + timeFactor * 50).clamp(0.0, 100.0);
  }

  Future<void> recordExposure(ExposureRecord record) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    final key = '$_prefix${record.date.toIso8601String().split("T").first}';
    await p.setString(key, _encodeRecord(record));
  }

  Future<List<ExposureRecord>> getWeeklyExposure() async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    p.getKeys().where((k) => k.startsWith(_prefix));
    final records = <ExposureRecord>[];
    final now = DateTime.now();
    for (var i = 0; i < 7; i++) {
      final d = now.subtract(Duration(days: i));
      final key = '$_prefix${_dateStr(d)}';
      final raw = p.getString(key);
      if (raw != null) {
        final r = _decodeRecord(raw, d);
        if (r != null) records.add(r);
      }
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
      final key = '$_prefix${_dateStr(d)}';
      final raw = p.getString(key);
      if (raw != null) {
        final r = _decodeRecord(raw, d);
        if (r != null) records.add(r);
      }
    }
    records.sort((a, b) => a.date.compareTo(b.date));
    return records;
  }

  /// REQ-5.3: Warn after 7 days of high exposure
  Future<bool> hasHighExposureStreak() async {
    final week = await getWeeklyExposure();
    return week.where((r) => r.score >= 60).length >= 7;
  }

  /// REQ-5.4: Personalized recommendation
  Future<String?> getExposureRecommendation({
    required double todayScore,
    required List<AqiTrendDay> weekTrend,
    required int currentAqi,
  }) async {
    if (todayScore >= 70) {
      return 'Your exposure has been high today. Try to reduce outdoor time tomorrow and stay in well-ventilated areas.';
    }
    final highDays = weekTrend.where((d) => d.maxAqi >= 150).length;
    if (highDays >= 3) {
      return 'Your exposure has been high for $highDays days this week. Try to reduce outdoor time and visit a low AQI location when possible.';
    }
    if (currentAqi >= 120) {
      return 'AQI is elevated. Consider wearing a mask if you need to go outside.';
    }
    return null;
  }

  String _dateStr(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _encodeRecord(ExposureRecord r) =>
      '${r.id}|${r.score}|${r.maxAqi}|${r.outdoorMinutes.inMinutes}';
  ExposureRecord? _decodeRecord(String raw, DateTime date) {
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
