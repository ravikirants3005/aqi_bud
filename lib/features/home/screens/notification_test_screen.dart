/// Notification Test Screen - Test local notifications
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/exposure_models.dart';
import '../../../domain/providers/app_providers.dart';

class NotificationTestScreen extends ConsumerStatefulWidget {
  const NotificationTestScreen({super.key});

  @override
  ConsumerState<NotificationTestScreen> createState() =>
      _NotificationTestScreenState();
}

class _NotificationTestScreenState
    extends ConsumerState<NotificationTestScreen> {
  bool _isSending = false;

  Future<void> _sendTestNotification(String type) async {
    if (_isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final notificationRepo = ref.read(notificationRepositoryProvider);
      switch (type) {
        case 'high_aqi':
          await notificationRepo.sendHighAqiAlert(
            aqi: 178,
            location: 'Current location',
            sensitivity: HealthSensitivity.sensitive,
          );
          break;
        case 'daily_summary':
          await notificationRepo.sendDailyExposureSummary(
            todayRecord: ExposureRecord(
              id: 'test-daily',
              date: DateTime.now(),
              score: 69,
              maxAqi: 142,
            ),
            safeLimit: 58,
            sensitivity: HealthSensitivity.sensitive,
          );
          break;
        case 'weekly_insights':
          await notificationRepo.sendWeeklyInsights(
            weeklyExposure: [
              ExposureRecord(
                id: 'test-week-1',
                date: DateTime(2026, 1, 1),
                score: 72,
                maxAqi: 160,
              ),
              ExposureRecord(
                id: 'test-week-2',
                date: DateTime(2026, 1, 2),
                score: 64,
                maxAqi: 122,
              ),
            ],
            highAqiDays: 3,
            sensitivity: HealthSensitivity.sensitive,
          );
          break;
        default:
          throw StateError('Unknown notification type: $type');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Local test notification sent. Check your device notification tray.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
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
        title: const Text('Test Local Notifications'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Using flutter_local_notifications for on-device alerts.',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Tap any button below to trigger a local test notification.',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 24),

            // Test buttons
            Expanded(
              child: ListView(
                children: [
                  _NotificationTestButton(
                    title: 'High AQI Alert',
                    description:
                        'Trigger a local high AQI alert on this device',
                    icon: Icons.warning,
                    color: Colors.red,
                    onPressed: () => _sendTestNotification('high_aqi'),
                    enabled: !_isSending,
                  ),

                  const SizedBox(height: 12),

                  _NotificationTestButton(
                    title: 'Daily Summary',
                    description: 'Trigger a local daily summary notification',
                    icon: Icons.today,
                    color: Colors.blue,
                    onPressed: () => _sendTestNotification('daily_summary'),
                    enabled: !_isSending,
                  ),

                  const SizedBox(height: 12),

                  _NotificationTestButton(
                    title: 'Weekly Insights',
                    description: 'Trigger a local weekly insights notification',
                    icon: Icons.insights,
                    color: Colors.purple,
                    onPressed: () => _sendTestNotification('weekly_insights'),
                    enabled: !_isSending,
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
                    '1. Log in on the phone you want to test\n'
                    '2. Allow notification permission\n'
                    '3. Press a test button above to show a local notification\n'
                    '4. Check the notification tray on that phone',
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
