/// User profile & preference models - REQ-4.x
library;

import 'package:equatable/equatable.dart';

import '../../core/constants/app_constants.dart';

class SavedLocation extends Equatable {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final int? lastAqi;
  final DateTime? lastUpdated;

  const SavedLocation({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    this.lastAqi,
    this.lastUpdated,
  });

  SavedLocation copyWith({
    String? id,
    String? name,
    double? lat,
    double? lng,
    int? lastAqi,
    DateTime? lastUpdated,
  }) =>
      SavedLocation(
        id: id ?? this.id,
        name: name ?? this.name,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        lastAqi: lastAqi ?? this.lastAqi,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );

  @override
  List<Object?> get props => [id];
}

class UserProfile extends Equatable {
  final String id;
  final String? email;
  final String? phone;
  final String? displayName;
  final String? photoUrl;
  final HealthSensitivity healthSensitivity;
  final String? ageGroup;
  final List<SavedLocation> savedLocations;
  final NotificationPreferences notificationPrefs;

  const UserProfile({
    required this.id,
    this.email,
    this.phone,
    this.displayName,
    this.photoUrl,
    this.healthSensitivity = HealthSensitivity.normal,
    this.ageGroup,
    this.savedLocations = const [],
    this.notificationPrefs = const NotificationPreferences(),
  });

  UserProfile copyWith({
    String? id,
    String? email,
    String? phone,
    String? displayName,
    String? photoUrl,
    HealthSensitivity? healthSensitivity,
    String? ageGroup,
    List<SavedLocation>? savedLocations,
    NotificationPreferences? notificationPrefs,
  }) =>
      UserProfile(
        id: id ?? this.id,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        healthSensitivity: healthSensitivity ?? this.healthSensitivity,
        ageGroup: ageGroup ?? this.ageGroup,
        savedLocations: savedLocations ?? this.savedLocations,
        notificationPrefs: notificationPrefs ?? this.notificationPrefs,
      );

  @override
  List<Object?> get props => [id];
}

class NotificationPreferences extends Equatable {
  final bool highAqiAlerts;
  final bool dailyExposureSummary;
  final bool weeklyInsights;
  final bool tipOfDay;

  const NotificationPreferences({
    this.highAqiAlerts = true,
    this.dailyExposureSummary = true,
    this.weeklyInsights = true,
    this.tipOfDay = true,
  });

  NotificationPreferences copyWith({
    bool? highAqiAlerts,
    bool? dailyExposureSummary,
    bool? weeklyInsights,
    bool? tipOfDay,
  }) =>
      NotificationPreferences(
        highAqiAlerts: highAqiAlerts ?? this.highAqiAlerts,
        dailyExposureSummary: dailyExposureSummary ?? this.dailyExposureSummary,
        weeklyInsights: weeklyInsights ?? this.weeklyInsights,
        tipOfDay: tipOfDay ?? this.tipOfDay,
      );

  @override
  List<Object?> get props =>
      [highAqiAlerts, dailyExposureSummary, weeklyInsights, tipOfDay];
}
