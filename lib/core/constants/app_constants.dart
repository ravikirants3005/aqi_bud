/// AQI Buddy - App Constants
/// REQ-1.3: AQI follows EPA/WHO categories
/// REQ-1.2: AQI update every 30 minutes
library;

/// EPA/WHO AQI categories (0-500 scale)
class AqiConstants {
  static const int updateIntervalMinutes = 30;
  static const int maxAqi = 500;
  
  static const int goodMax = 50;
  static const int moderateMax = 100;
  static const int unhealthySensitiveMax = 150;
  static const int unhealthyMax = 200;
  static const int veryUnhealthyMax = 300;
  static const int hazardousMax = 500;
}

/// Health sensitivity categories - REQ-4.2
enum HealthSensitivity {
  normal('Normal', 'General population'),
  sensitive('Sensitive', 'Allergies, mild respiratory issues'),
  asthmatic('Asthmatic', 'Asthma, respiratory conditions'),
  elderly('Elderly', 'Seniors 65+');

  final String label;
  final String description;
  const HealthSensitivity(this.label, this.description);
}

/// Notification preference keys - REQ-4.4
class NotificationPrefs {
  static const String highAqiAlerts = 'high_aqi_alerts';
  static const String dailyExposureSummary = 'daily_exposure_summary';
  static const String weeklyInsights = 'weekly_insights';
  static const String tipOfDay = 'tip_of_day';
}
