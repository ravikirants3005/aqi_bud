/// User Profile & Preferences - REQ-4.x
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/disclaimer.dart';
import '../../../data/models/user_models.dart';
import '../../../domain/providers/app_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final isGuest = profile?.id == 'guest';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (!isGuest)
            TextButton(
              onPressed: () async {
                await ref.read(userProfileProvider.notifier).signOut();
                if (context.mounted) context.go('/');
              },
              child: const Text('Log out'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFF69F6B8).withValues(alpha: 0.15),
              child: profile?.photoUrl != null
                  ? null
                  : Text(
                      (profile?.displayName ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 36,
                        color: Color(0xFF69F6B8),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              profile?.displayName ?? 'Guest',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (profile?.email != null)
            Center(
              child: Text(
                profile!.email!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ),
          if (isGuest) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.push('/login'),
              icon: const Icon(Icons.login),
              label: const Text('Log in / Register'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Text(
            'Health Sensitivity',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: HealthSensitivity.values.map((s) {
              final selected = profile?.healthSensitivity == s;
              return FilterChip(
                label: Text(s.label),
                selected: selected,
                backgroundColor: const Color(0xFF0F1930),
                selectedColor: const Color(0xFF69F6B8).withValues(alpha: 0.15),
                checkmarkColor: const Color(0xFF69F6B8),
                labelStyle: TextStyle(
                  color: selected ? const Color(0xFF69F6B8) : Colors.white70,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                ),
                side: BorderSide(
                  color: selected
                      ? const Color(0xFF69F6B8).withValues(alpha: 0.5)
                      : const Color(0xFF40485D).withValues(alpha: 0.15),
                ),
                onSelected: (_) {
                  ref.read(userProfileProvider.notifier).updateSensitivity(s);
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          Text(
            (profile?.healthSensitivity ?? HealthSensitivity.normal)
                .description,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Notifications',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _NotificationSwitch(
            title: 'High AQI alerts',
            value: profile?.notificationPrefs.highAqiAlerts ?? true,
            onChanged: (v) {
              final p =
                  profile?.notificationPrefs ?? const NotificationPreferences();
              ref
                  .read(userProfileProvider.notifier)
                  .updateNotificationPreferences(p.copyWith(highAqiAlerts: v));
            },
          ),
          _NotificationSwitch(
            title: 'Daily exposure summary',
            value: profile?.notificationPrefs.dailyExposureSummary ?? true,
            onChanged: (v) {
              final p =
                  profile?.notificationPrefs ?? const NotificationPreferences();
              ref
                  .read(userProfileProvider.notifier)
                  .updateNotificationPreferences(
                    p.copyWith(dailyExposureSummary: v),
                  );
            },
          ),
          _NotificationSwitch(
            title: 'Weekly insights',
            value: profile?.notificationPrefs.weeklyInsights ?? true,
            onChanged: (v) {
              final p =
                  profile?.notificationPrefs ?? const NotificationPreferences();
              ref
                  .read(userProfileProvider.notifier)
                  .updateNotificationPreferences(p.copyWith(weeklyInsights: v));
            },
          ),
          _NotificationSwitch(
            title: 'Tip of the day',
            value: profile?.notificationPrefs.tipOfDay ?? true,
            onChanged: (v) {
              final p =
                  profile?.notificationPrefs ?? const NotificationPreferences();
              ref
                  .read(userProfileProvider.notifier)
                  .updateNotificationPreferences(p.copyWith(tipOfDay: v));
            },
          ),
          const SizedBox(height: 24),
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                medicalDisclaimer,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Saved locations'),
            subtitle: Text(
              '${profile?.savedLocations.length ?? 0} places saved',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/saved-locations'),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.notifications_active_outlined),
            title: const Text('Test local notification'),
            subtitle: const Text(
              'Send a local test notification on this device',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/notification-test'),
          ),
        ],
      ),
    );
  }
}

class _NotificationSwitch extends StatelessWidget {
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationSwitch({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}
