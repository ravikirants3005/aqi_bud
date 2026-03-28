/// Push notification service for AQI alerts and insights
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../../data/models/exposure_models.dart';
import '../../core/constants/app_constants.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    await _requestPermissions();
    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

      // Request exact alarm permission for Android 12+
      await _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestExactAlarmsPermission();
    } else if (Platform.isIOS) {
      await _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap - navigate to relevant screen
    debugPrint('Notification tapped: ${response.payload}');
  }

  /// High AQI alert notification
  Future<void> sendHighAqiAlert({
    required int aqi,
    required String location,
    required HealthSensitivity sensitivity,
  }) async {
    if (!_initialized) await initialize();

    final category = _getAqiCategory(aqi);
    final severity = _getNotificationSeverity(aqi, sensitivity);

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      'High AQI Alert',
      'AQI $aqi ($category) detected at $location. ${_getHealthAdvice(aqi, sensitivity)}',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'high_aqi_channel',
          'High AQI Alerts',
          channelDescription: 'Alerts for unhealthy air quality',
          importance: severity.importance,
          priority: severity.priority,
          color: _getAqiColor(aqi),
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'high_aqi|$aqi|$location',
    );
  }

  /// Daily exposure summary notification
  Future<void> sendDailyExposureSummary({
    required ExposureRecord todayRecord,
    required double safeLimit,
    required HealthSensitivity sensitivity,
  }) async {
    if (!_initialized) await initialize();

    final score = todayRecord.score.toInt();
    final status = score > safeLimit ? 'above' : 'within';
    final message = score > safeLimit
        ? 'Your exposure score was $score, above your safe limit of ${safeLimit.toInt()}.'
        : 'Good news! Your exposure score was $score, within safe limits.';

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000) + 1,
      'Daily Exposure Summary',
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_summary_channel',
          'Daily Exposure Summary',
          channelDescription: 'Daily air quality exposure reports',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: false,
        ),
      ),
      payload: 'daily_summary|$score',
    );
  }

  /// Weekly insights notification
  Future<void> sendWeeklyInsights({
    required List<ExposureRecord> weeklyExposure,
    required int highAqiDays,
    required HealthSensitivity sensitivity,
  }) async {
    if (!_initialized) await initialize();

    final averageScore = weeklyExposure.isEmpty
        ? 0
        : weeklyExposure.map((r) => r.score).reduce((a, b) => a + b) /
              weeklyExposure.length;

    final message = highAqiDays > 2
        ? 'You had $highAqiDays high AQI days this week. Consider reducing outdoor time next week.'
        : 'Weekly average exposure: ${averageScore.toInt()}. ${highAqiDays == 0 ? 'Great job avoiding high pollution!' : 'Try to minimize high AQI exposure.'}';

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000) + 2,
      'Weekly Air Quality Insights',
      message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_insights_channel',
          'Weekly Insights',
          channelDescription: 'Weekly air quality patterns and recommendations',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: false,
        ),
      ),
      payload: 'weekly_insights|$averageScore',
    );
  }

  /// Schedule daily exposure summary at 8 PM
  Future<void> scheduleDailySummary() async {
    if (!_initialized) await initialize();

    try {
      await _notifications.zonedSchedule(
        0,
        'Daily Exposure Summary',
        'Check your daily air quality exposure summary',
        _nextInstanceOfTime(20, 0), // 8 PM
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_summary_channel',
            'Daily Exposure Summary',
            channelDescription: 'Daily air quality exposure reports',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: false,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      // Fallback to inexact scheduling if exact alarms aren't permitted
      await _notifications.zonedSchedule(
        0,
        'Daily Exposure Summary',
        'Check your daily air quality exposure summary',
        _nextInstanceOfTime(20, 0), // 8 PM
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_summary_channel',
            'Daily Exposure Summary',
            channelDescription: 'Daily air quality exposure reports',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: false,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  /// Schedule weekly insights on Sunday at 9 AM
  Future<void> scheduleWeeklyInsights() async {
    if (!_initialized) await initialize();

    try {
      await _notifications.zonedSchedule(
        1,
        'Weekly Air Quality Insights',
        'Review your weekly air quality patterns and recommendations',
        _nextInstanceOfDayTime(DateTime.sunday, 9, 0),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'weekly_insights_channel',
            'Weekly Insights',
            channelDescription:
                'Weekly air quality patterns and recommendations',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: false,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (e) {
      // Fallback to inexact scheduling if exact alarms aren't permitted
      await _notifications.zonedSchedule(
        1,
        'Weekly Air Quality Insights',
        'Review your weekly air quality patterns and recommendations',
        _nextInstanceOfDayTime(DateTime.sunday, 9, 0),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'weekly_insights_channel',
            'Weekly Insights',
            channelDescription:
                'Weekly air quality patterns and recommendations',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: false,
          ),
        ),
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfDayTime(int day, int hour, int minute) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);
    while (scheduledDate.weekday != day) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  String _getAqiCategory(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Unhealthy for Sensitive';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Unhealthy';
    return 'Hazardous';
  }

  _NotificationSeverity _getNotificationSeverity(
    int aqi,
    HealthSensitivity sensitivity,
  ) {
    final threshold = switch (sensitivity) {
      HealthSensitivity.normal => 150,
      HealthSensitivity.sensitive => 100,
      HealthSensitivity.asthmatic => 75,
      HealthSensitivity.elderly => 75,
    };

    if (aqi >= threshold + 50) {
      return _NotificationSeverity(Importance.high, Priority.high);
    } else if (aqi >= threshold) {
      return _NotificationSeverity(
        Importance.defaultImportance,
        Priority.defaultPriority,
      );
    }
    return _NotificationSeverity(Importance.low, Priority.low);
  }

  String _getHealthAdvice(int aqi, HealthSensitivity sensitivity) {
    if (aqi >= 200) return 'Avoid all outdoor activities.';
    if (aqi >= 150) return 'Avoid prolonged outdoor exertion.';
    if (aqi >= 100) return 'Limit prolonged outdoor exertion.';
    if (aqi >= 50)
      return 'Unusually sensitive people should consider reducing prolonged outdoor exertion.';
    return 'Air quality is satisfactory.';
  }

  Color _getAqiColor(int aqi) {
    if (aqi <= 50) return const Color(0xFF00E400); // Green
    if (aqi <= 100) return const Color(0xFFFFFD00); // Yellow
    if (aqi <= 150) return const Color(0xFFFF7E00); // Orange
    if (aqi <= 200) return const Color(0xFFFF0000); // Red
    if (aqi <= 300) return const Color(0xFF8F3F97); // Purple
    return const Color(0xFF7E0023); // Maroon
  }

  Future<void> cancelAll() async {
    await _notifications.cancelAll();
  }

  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
}

class _NotificationSeverity {
  final Importance importance;
  final Priority priority;

  _NotificationSeverity(this.importance, this.priority);
}
