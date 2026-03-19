/// Exposure tracking models - REQ-5.x
library;

import 'package:equatable/equatable.dart';

/// REQ-5.1: Exposure score 0-100
class ExposureRecord extends Equatable {
  final String id;
  final DateTime date;
  final double score; // 0-100
  final int maxAqi;
  final Duration outdoorMinutes;
  final List<LocationExposure> locationExposures;

  const ExposureRecord({
    required this.id,
    required this.date,
    required this.score,
    required this.maxAqi,
    this.outdoorMinutes = Duration.zero,
    this.locationExposures = const [],
  });

  @override
  List<Object?> get props => [id, date];
}

class LocationExposure extends Equatable {
  final double lat;
  final double lng;
  final String? name;
  final int aqi;
  final Duration duration;

  const LocationExposure({
    required this.lat,
    required this.lng,
    this.name,
    required this.aqi,
    required this.duration,
  });

  @override
  List<Object?> get props => [lat, lng, aqi];
}

enum ExposureAlertSeverity { advisory, warning, critical }

class ExposureAlert extends Equatable {
  final String title;
  final String message;
  final ExposureAlertSeverity severity;

  const ExposureAlert({
    required this.title,
    required this.message,
    required this.severity,
  });

  @override
  List<Object?> get props => [title, message, severity];
}

class FrequentLocationInsight extends Equatable {
  final String locationId;
  final String name;
  final int currentAqi;
  final double weeklyAverageAqi;
  final int worstAqi;
  final String insight;

  const FrequentLocationInsight({
    required this.locationId,
    required this.name,
    required this.currentAqi,
    required this.weeklyAverageAqi,
    required this.worstAqi,
    required this.insight,
  });

  @override
  List<Object?> get props =>
      [locationId, name, currentAqi, weeklyAverageAqi, worstAqi, insight];
}

class ExposureDashboardData extends Equatable {
  final ExposureRecord todayRecord;
  final List<ExposureRecord> weeklyExposure;
  final List<ExposureRecord> monthlyExposure;
  final int highAqiDays;
  final ExposureRecord bestDay;
  final ExposureRecord worstDay;
  final List<FrequentLocationInsight> locationInsights;
  final List<ExposureAlert> alerts;
  final List<String> suggestions;
  final String monthlyPatternInsight;
  final double safeLimit;

  const ExposureDashboardData({
    required this.todayRecord,
    required this.weeklyExposure,
    required this.monthlyExposure,
    required this.highAqiDays,
    required this.bestDay,
    required this.worstDay,
    required this.locationInsights,
    required this.alerts,
    required this.suggestions,
    required this.monthlyPatternInsight,
    required this.safeLimit,
  });

  @override
  List<Object?> get props => [
        todayRecord,
        weeklyExposure,
        monthlyExposure,
        highAqiDays,
        bestDay,
        worstDay,
        locationInsights,
        alerts,
        suggestions,
        monthlyPatternInsight,
        safeLimit,
      ];
}
