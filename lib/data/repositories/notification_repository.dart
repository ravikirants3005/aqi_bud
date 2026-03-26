/// Notification repository - manages user notification preferences and scheduling
library;

import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/notifications/notification_service.dart';
import '../../data/models/user_models.dart';
import '../../data/models/exposure_models.dart';
import '../../data/models/aqi_models.dart';

class NotificationRepository {
  NotificationRepository({
    SharedPreferences? prefs,
    NotificationService? notificationService,
  }) : _prefs = prefs, _notificationService = notificationService ?? NotificationService();

  final SharedPreferences? _prefs;
  final NotificationService _notificationService;
  static const _prefsPrefix = 'notifications_';

  /// Initialize notification service and schedule recurring notifications
  Future<void> initialize() async {
    await _notificationService.initialize();
    
    // Schedule recurring notifications if enabled
    if (await _isNotificationEnabled('daily_summary')) {
      await _notificationService.scheduleDailySummary();
    }
    if (await _isNotificationEnabled('weekly_insights')) {
      await _notificationService.scheduleWeeklyInsights();
    }
  }

  /// Update notification preferences and reschedule if needed
  Future<void> updatePreferences(NotificationPreferences prefs) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    
    await p.setBool('${_prefsPrefix}high_aqi_alerts', prefs.highAqiAlerts);
    await p.setBool('${_prefsPrefix}daily_exposure_summary', prefs.dailyExposureSummary);
    await p.setBool('${_prefsPrefix}weekly_insights', prefs.weeklyInsights);
    await p.setBool('${_prefsPrefix}tip_of_day', prefs.tipOfDay);

    // Reschedule recurring notifications based on new preferences
    if (prefs.dailyExposureSummary) {
      await _notificationService.scheduleDailySummary();
    } else {
      await _notificationService.cancel(0); // Cancel daily summary
    }
    
    if (prefs.weeklyInsights) {
      await _notificationService.scheduleWeeklyInsights();
    } else {
      await _notificationService.cancel(1); // Cancel weekly insights
    }
  }

  /// Send high AQI alert if enabled
  Future<void> sendHighAqiAlert({
    required int aqi,
    required String location,
    required HealthSensitivity sensitivity,
  }) async {
    if (!await _isNotificationEnabled('high_aqi_alerts')) return;
    
    await _notificationService.sendHighAqiAlert(
      aqi: aqi,
      location: location,
      sensitivity: sensitivity,
    );
  }

  /// Send daily exposure summary if enabled
  Future<void> sendDailyExposureSummary({
    required ExposureRecord todayRecord,
    required double safeLimit,
    required HealthSensitivity sensitivity,
  }) async {
    if (!await _isNotificationEnabled('daily_exposure_summary')) return;
    
    await _notificationService.sendDailyExposureSummary(
      todayRecord: todayRecord,
      safeLimit: safeLimit,
      sensitivity: sensitivity,
    );
  }

  /// Send weekly insights if enabled
  Future<void> sendWeeklyInsights({
    required List<ExposureRecord> weeklyExposure,
    required int highAqiDays,
    required HealthSensitivity sensitivity,
  }) async {
    if (!await _isNotificationEnabled('weekly_insights')) return;
    
    await _notificationService.sendWeeklyInsights(
      weeklyExposure: weeklyExposure,
      highAqiDays: highAqiDays,
      sensitivity: sensitivity,
    );
  }

  /// Check if specific notification type is enabled
  Future<bool> _isNotificationEnabled(String type) async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    return p.getBool('${_prefsPrefix}$type') ?? _getDefaultEnabled(type);
  }

  /// Get default enabled status for notification types
  bool _getDefaultEnabled(String type) {
    switch (type) {
      case 'high_aqi_alerts':
        return true; // High AQI alerts are critical
      case 'daily_exposure_summary':
        return true;
      case 'weekly_insights':
        return true;
      case 'tip_of_day':
        return false; // Tips are optional
      default:
        return false;
    }
  }

  /// Load notification preferences from storage
  Future<NotificationPreferences> loadPreferences() async {
    final p = _prefs ?? await SharedPreferences.getInstance();
    
    return NotificationPreferences(
      highAqiAlerts: p.getBool('${_prefsPrefix}high_aqi_alerts') ?? true,
      dailyExposureSummary: p.getBool('${_prefsPrefix}daily_exposure_summary') ?? true,
      weeklyInsights: p.getBool('${_prefsPrefix}weekly_insights') ?? true,
      tipOfDay: p.getBool('${_prefsPrefix}tip_of_day') ?? false,
    );
  }

  /// Cancel all notifications (useful for sign out)
  Future<void> cancelAll() async {
    await _notificationService.cancelAll();
  }

  /// Process AQI data and trigger appropriate notifications
  Future<void> processAqiUpdate({
    required AqiData aqiData,
    required HealthSensitivity sensitivity,
    required NotificationPreferences prefs,
  }) async {
    // Check for high AQI conditions
    if (prefs.highAqiAlerts) {
      final threshold = switch (sensitivity) {
        HealthSensitivity.normal => 150,
        HealthSensitivity.sensitive => 100,
        HealthSensitivity.asthmatic => 75,
        HealthSensitivity.elderly => 75,
      };

      if (aqiData.aqi >= threshold) {
        await sendHighAqiAlert(
          aqi: aqiData.aqi,
          location: aqiData.locationName ?? 'Current location',
          sensitivity: sensitivity,
        );
      }
    }
  }

  /// Process daily exposure data and send summary
  Future<void> processDailyExposure({
    required ExposureRecord todayRecord,
    required HealthSensitivity sensitivity,
    required NotificationPreferences prefs,
  }) async {
    if (prefs.dailyExposureSummary) {
      final safeLimit = switch (sensitivity) {
        HealthSensitivity.normal => 65.0,
        HealthSensitivity.sensitive => 58.0,
        HealthSensitivity.asthmatic => 52.0,
        HealthSensitivity.elderly => 52.0,
      };

      await sendDailyExposureSummary(
        todayRecord: todayRecord,
        safeLimit: safeLimit,
        sensitivity: sensitivity,
      );
    }
  }

  /// Process weekly exposure data and send insights
  Future<void> processWeeklyInsights({
    required List<ExposureRecord> weeklyExposure,
    required HealthSensitivity sensitivity,
    required NotificationPreferences prefs,
  }) async {
    if (prefs.weeklyInsights) {
      final highAqiDays = weeklyExposure
          .where((record) => record.maxAqi >= 100)
          .length;

      await sendWeeklyInsights(
        weeklyExposure: weeklyExposure,
        highAqiDays: highAqiDays,
        sensitivity: sensitivity,
      );
    }
  }
}
