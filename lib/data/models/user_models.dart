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
    return SavedLocation(
      id: json['id'] as String,
      name: json['name'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      lastAqi: json['lastAqi'] as int?,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
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
    final healthSensitivityStr =
        json['healthSensitivity'] as String? ?? 'normal';
    final healthSensitivity = HealthSensitivity.values.firstWhere(
      (s) => s.name == healthSensitivityStr,
      orElse: () => HealthSensitivity.normal,
    );

    final notificationPrefsJson =
        json['notificationPrefs'] as Map<String, dynamic>? ?? {};
    final notificationPrefs = NotificationPreferences(
      highAqiAlerts: notificationPrefsJson['highAqiAlerts'] as bool? ?? true,
      dailyExposureSummary:
          notificationPrefsJson['dailyExposureSummary'] as bool? ?? true,
      weeklyInsights: notificationPrefsJson['weeklyInsights'] as bool? ?? true,
      tipOfDay: notificationPrefsJson['tipOfDay'] as bool? ?? true,
    );

    final savedLocationsJson = json['savedLocations'] as List<dynamic>? ?? [];
    final savedLocations = savedLocationsJson
        .map((l) => SavedLocation.fromJson(l as Map<String, dynamic>))
        .toList();

    return UserProfile(
      id: json['id'] as String,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      healthSensitivity: healthSensitivity,
      ageGroup: json['ageGroup'] as String?,
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
