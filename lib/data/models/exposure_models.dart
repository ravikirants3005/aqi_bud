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

  ExposureRecord copyWith({
    String? id,
    DateTime? date,
    double? score,
    int? maxAqi,
    Duration? outdoorMinutes,
    List<LocationExposure>? locationExposures,
  }) => ExposureRecord(
    id: id ?? this.id,
    date: date ?? this.date,
    score: score ?? this.score,
    maxAqi: maxAqi ?? this.maxAqi,
    outdoorMinutes: outdoorMinutes ?? this.outdoorMinutes,
    locationExposures: locationExposures ?? this.locationExposures,
  );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'score': score,
      'maxAqi': maxAqi,
      'outdoorMinutes': outdoorMinutes.inMinutes,
      'locationExposures': locationExposures.map((l) => l.toJson()).toList(),
    };
  }

  factory ExposureRecord.fromJson(Map<String, dynamic> json) {
    final locationExposuresJson =
        json['locationExposures'] ?? json['location_exposures'] ?? [];
    final locationExposures = (locationExposuresJson as List)
        .map((l) => LocationExposure.fromJson(l as Map<String, dynamic>))
        .toList();

    // Handle both frontend and backend field names
    final dateStr = json['date'] ?? json['record_date'];
    final score = json['score'] ?? json['total_exposure_score'] ?? 0.0;
    final maxAqi = json['maxAqi'] ?? json['max_aqi'] ?? 0;
    final outdoorMins = json['outdoorMinutes'] ?? json['outdoor_minutes'] ?? 0;

    return ExposureRecord(
      id: json['id'] as String? ?? 'exp_${DateTime.now().millisecondsSinceEpoch}',
      date: dateStr != null ? DateTime.parse(dateStr as String) : DateTime.now(),
      score: (score as num).toDouble(),
      maxAqi: maxAqi as int,
      outdoorMinutes: Duration(minutes: outdoorMins as int),
      locationExposures: locationExposures,
    );
  }

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

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      'name': name,
      'aqi': aqi,
      'duration': duration.inMinutes,
    };
  }

  factory LocationExposure.fromJson(Map<String, dynamic> json) {
    // Handle both frontend and backend field names
    final lat = json['lat'] ?? json['latitude'];
    final lng = json['lng'] ?? json['longitude'];
    final name = json['name'] ?? json['location_name'];
    final duration = json['duration'] ?? json['duration_minutes'] ?? 0;

    return LocationExposure(
      lat: (lat as num).toDouble(),
      lng: (lng as num).toDouble(),
      name: name as String?,
      aqi: (json['aqi'] as num?)?.toInt() ?? 0,
      duration: Duration(minutes: duration as int),
    );
  }

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
  List<Object?> get props => [
    locationId,
    name,
    currentAqi,
    weeklyAverageAqi,
    worstAqi,
    insight,
  ];
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
