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
  }) => SavedLocation(
    id: id ?? this.id,
    name: name ?? this.name,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    lastAqi: lastAqi ?? this.lastAqi,
    lastUpdated: lastUpdated ?? this.lastUpdated,
  );

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'lat': lat,
      'lng': lng,
      'lastAqi': lastAqi,
      'lastUpdated': lastUpdated?.toIso8601String(),
    };
  }

  factory SavedLocation.fromJson(Map<String, dynamic> json) {
    // Handle both frontend and backend field names
    final lat = json['lat'] ?? json['latitude'];
    final lng = json['lng'] ?? json['longitude'];
    final lastAqi = json['lastAqi'] ?? json['last_aqi'];
    final lastUpdated = json['lastUpdated'] ?? json['last_updated'];

    return SavedLocation(
      id: json['id'] as String? ?? json['location_id'] as String? ?? '',
      name: json['name'] as String? ?? json['location_name'] as String? ?? 'Unknown',
      lat: (lat as num).toDouble(),
      lng: (lng as num).toDouble(),
      lastAqi: lastAqi as int?,
      lastUpdated: lastUpdated != null
          ? DateTime.parse(lastUpdated as String)
          : null,
    );
  }

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
  }) => UserProfile(
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

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'healthSensitivity': healthSensitivity.name,
      'ageGroup': ageGroup,
      'savedLocations': savedLocations.map((l) => l.toJson()).toList(),
      'notificationPrefs': {
        'highAqiAlerts': notificationPrefs.highAqiAlerts,
        'dailyExposureSummary': notificationPrefs.dailyExposureSummary,
        'weeklyInsights': notificationPrefs.weeklyInsights,
        'tipOfDay': notificationPrefs.tipOfDay,
      },
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Handle both frontend and backend field names
    final healthSensitivityStr =
        json['healthSensitivity'] ?? json['health_sensitivity'] ?? 'normal';
    final healthSensitivity = HealthSensitivity.values.firstWhere(
      (s) => s.name == healthSensitivityStr,
      orElse: () => HealthSensitivity.normal,
    );

    final notificationPrefsJson =
        json['notificationPrefs'] ?? json['notification_prefs'] ?? {};
    final notificationPrefs = NotificationPreferences(
      highAqiAlerts: notificationPrefsJson['highAqiAlerts'] ?? notificationPrefsJson['high_aqi_alerts'] ?? true,
      dailyExposureSummary:
          notificationPrefsJson['dailyExposureSummary'] ?? notificationPrefsJson['daily_exposure_summary'] ?? true,
      weeklyInsights: notificationPrefsJson['weeklyInsights'] ?? notificationPrefsJson['weekly_insights'] ?? true,
      tipOfDay: notificationPrefsJson['tipOfDay'] ?? notificationPrefsJson['tip_of_day'] ?? true,
    );

    final savedLocationsJson = json['savedLocations'] ?? json['saved_locations'] ?? [];
    final savedLocations = (savedLocationsJson as List)
        .map((l) => SavedLocation.fromJson(l as Map<String, dynamic>))
        .toList();

    return UserProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      displayName: json['displayName'] ?? json['display_name'] as String?,
      photoUrl: json['photoUrl'] ?? json['photo_url'] as String?,
      healthSensitivity: healthSensitivity,
      ageGroup: json['ageGroup'] ?? json['age_group'] as String?,
      savedLocations: savedLocations,
      notificationPrefs: notificationPrefs,
    );
  }

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
  }) => NotificationPreferences(
    highAqiAlerts: highAqiAlerts ?? this.highAqiAlerts,
    dailyExposureSummary: dailyExposureSummary ?? this.dailyExposureSummary,
    weeklyInsights: weeklyInsights ?? this.weeklyInsights,
    tipOfDay: tipOfDay ?? this.tipOfDay,
  );

  @override
  List<Object?> get props => [
    highAqiAlerts,
    dailyExposureSummary,
    weeklyInsights,
    tipOfDay,
  ];
}
