/// AQI data models - EPA/WHO compliant
library;

import 'package:equatable/equatable.dart';

/// REQ-1.3: AQI categories per EPA/WHO
enum AqiCategory {
  good,
  moderate,
  unhealthySensitive,
  unhealthy,
  veryUnhealthy,
  hazardous,
}

extension AqiCategoryX on AqiCategory {
  String get label {
    switch (this) {
      case AqiCategory.good:
        return 'Good';
      case AqiCategory.moderate:
        return 'Moderate';
      case AqiCategory.unhealthySensitive:
        return 'Unhealthy for Sensitive Groups';
      case AqiCategory.unhealthy:
        return 'Unhealthy';
      case AqiCategory.veryUnhealthy:
        return 'Very Unhealthy';
      case AqiCategory.hazardous:
        return 'Hazardous';
    }
  }

  int get colorValue {
    switch (this) {
      case AqiCategory.good:
        return 0xFF00E400; // Green
      case AqiCategory.moderate:
        return 0xFFFFF300; // Yellow
      case AqiCategory.unhealthySensitive:
        return 0xFFFF7E00; // Orange
      case AqiCategory.unhealthy:
        return 0xFFFF0000; // Red
      case AqiCategory.veryUnhealthy:
        return 0xFF8F3F97; // Purple
      case AqiCategory.hazardous:
        return 0xFF7E0023; // Maroon
    }
  }
}

AqiCategory aqiToCategory(int aqi) {
  if (aqi <= 50) return AqiCategory.good;
  if (aqi <= 100) return AqiCategory.moderate;
  if (aqi <= 150) return AqiCategory.unhealthySensitive;
  if (aqi <= 200) return AqiCategory.unhealthy;
  if (aqi <= 300) return AqiCategory.veryUnhealthy;
  return AqiCategory.hazardous;
}

class AqiData extends Equatable {
  final int aqi;
  final double lat;
  final double lng;
  final DateTime timestamp;
  final double? pm25;
  final double? pm10;
  final String? locationName;

  const AqiData({
    required this.aqi,
    required this.lat,
    required this.lng,
    required this.timestamp,
    this.pm25,
    this.pm10,
    this.locationName,
  });

  Map<String, dynamic> toJson() {
    return {
      'aqi': aqi,
      'lat': lat,
      'lng': lng,
      'timestamp': timestamp.toIso8601String(),
      'pm25': pm25,
      'pm10': pm10,
      'locationName': locationName,
    };
  }

  factory AqiData.fromJson(Map<String, dynamic> json) {
    // Handle both lat/lng (frontend) and latitude/longitude (backend) field names
    final lat = json['lat'] ?? json['latitude'];
    final lng = json['lng'] ?? json['longitude'];
    final locationName = json['locationName'] ?? json['location_name'];
    
    // Handle timestamp - could be String or DateTime
    final timestampRaw = json['timestamp'];
    DateTime timestamp;
    if (timestampRaw is String) {
      timestamp = DateTime.parse(timestampRaw);
    } else {
      timestamp = DateTime.now();
    }
    
    return AqiData(
      aqi: (json['aqi'] as num?)?.toInt() ?? 0,
      lat: (lat as num).toDouble(),
      lng: (lng as num).toDouble(),
      timestamp: timestamp,
      pm25: (json['pm25'] as num?)?.toDouble(),
      pm10: (json['pm10'] as num?)?.toDouble(),
      locationName: locationName as String?,
    );
  }

  AqiCategory get category => aqiToCategory(aqi);

  AqiData copyWith({
    int? aqi,
    double? lat,
    double? lng,
    DateTime? timestamp,
    double? pm25,
    double? pm10,
    String? locationName,
  }) {
    return AqiData(
      aqi: aqi ?? this.aqi,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      timestamp: timestamp ?? this.timestamp,
      pm25: pm25 ?? this.pm25,
      pm10: pm10 ?? this.pm10,
      locationName: locationName ?? this.locationName,
    );
  }

  @override
  List<Object?> get props => [aqi, lat, lng, timestamp];
}

/// REQ-1.4: 7-day AQI trend
class AqiTrendDay extends Equatable {
  final DateTime date;
  final int maxAqi;
  final int avgAqi;

  const AqiTrendDay({
    required this.date,
    required this.maxAqi,
    required this.avgAqi,
  });

  AqiCategory get category => aqiToCategory(maxAqi);

  @override
  List<Object?> get props => [date, maxAqi, avgAqi];
}

class AqiHourlyPoint extends Equatable {
  final DateTime time;
  final int aqi;

  const AqiHourlyPoint({required this.time, required this.aqi});

  AqiCategory get category => aqiToCategory(aqi);

  @override
  List<Object?> get props => [time, aqi];
}
