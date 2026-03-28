/// Notification Test Screen - Test push notifications
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/exposure_models.dart';
import '../../../data/models/user_models.dart';

class NotificationTestScreen extends ConsumerStatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  ConsumerState<NotificationTestScreen> createState() =>
      _NotificationTestScreenState();
}

class _NotificationTestScreenState
    extends ConsumerState<NotificationTestScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Error initializing notifications: $e');
    }
  }

  Future<void> _sendHighAqiAlert() async {
    if (!_isInitialized) return;

    try {
      await _notificationService.sendHighAqiAlert(
        aqi: 150,
        location: "New York City",
        sensitivity: HealthSensitivity.normal,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('High AQI alert sent!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _sendDailySummary() async {
    if (!_isInitialized) return;

    try {
      await _notificationService.sendDailyExposureSummary(
        todayRecord: ExposureRecord(
          id: 'test_${DateTime.now().millisecondsSinceEpoch}',
          date: DateTime.now(),
          score: 75.5,
          maxAqi: 120,
          outdoorMinutes: const Duration(minutes: 180),
          locationExposures: [
            LocationExposure(
              lat: 40.7128,
              lng: -74.0060,
              name: "Central Park",
              aqi: 120,
              duration: const Duration(minutes: 120),
            ),
          ],
        ),
        safeLimit: 100.0,
        sensitivity: HealthSensitivity.normal,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Daily summary sent!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _sendWeeklyInsights() async {
    if (!_isInitialized) return;

    try {
      await _notificationService.sendWeeklyInsights(
        weeklyExposure: [
          ExposureRecord(
            id: 'test_weekly_${DateTime.now().millisecondsSinceEpoch}',
            date: DateTime.now().subtract(const Duration(days: 1)),
            score: 65.5,
            maxAqi: 110,
            outdoorMinutes: const Duration(minutes: 150),
            locationExposures: const [],
          ),
        ],
        highAqiDays: 2,
        sensitivity: HealthSensitivity.normal,
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Weekly insights sent!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF060E20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060E20),
        foregroundColor: Colors.white,
        title: const Text('Test Notifications'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isInitialized
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.orange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isInitialized ? Colors.green : Colors.orange,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isInitialized ? Icons.check_circle : Icons.warning,
                    color: _isInitialized ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isInitialized
                        ? 'Notifications initialized'
                        : 'Initializing notifications...',
                    style: TextStyle(
                      color: _isInitialized ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Test buttons
            Expanded(
              child: ListView(
                children: [
                  _NotificationTestButton(
                    title: 'High AQI Alert',
                    description: 'Test high AQI warning notification',
                    icon: Icons.warning,
                    color: Colors.red,
                    onPressed: _sendHighAqiAlert,
                    enabled: _isInitialized,
                  ),

                  const SizedBox(height: 12),

                  _NotificationTestButton(
                    title: 'Daily Summary',
                    description: 'Test daily exposure summary',
                    icon: Icons.today,
                    color: Colors.blue,
                    onPressed: _sendDailySummary,
                    enabled: _isInitialized,
                  ),

                  const SizedBox(height: 12),

                  _NotificationTestButton(
                    title: 'Weekly Insights',
                    description: 'Test weekly insights notification',
                    icon: Icons.insights,
                    color: Colors.purple,
                    onPressed: _sendWeeklyInsights,
                    enabled: _isInitialized,
                  ),
                ],
              ),
            ),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How to test:',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Press any test button above\n'
                    '2. Check your phone\'s notification panel\n'
                    '3. You should see the test notification\n'
                    '4. Make sure notifications are enabled in settings',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTestButton extends StatelessWidget {
  const _NotificationTestButton({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.onPressed,
    required this.enabled,
  });

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: enabled ? onPressed : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.2),
        foregroundColor: color,
        disabledBackgroundColor: Colors.grey.withValues(alpha: 0.1),
        disabledForegroundColor: Colors.grey,
        padding: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: color.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: enabled ? color.withOpacity(0.8) : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: enabled ? color : Colors.grey,
          ),
        ],
      ),
    );
  }
}
