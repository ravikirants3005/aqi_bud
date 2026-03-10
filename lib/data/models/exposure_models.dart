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
