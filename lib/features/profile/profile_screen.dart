import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                child: Icon(Icons.person, size: 40, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'John Doe',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'john.doe@example.com',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 48),
          Text('Preferences', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSettingsTile(theme, Icons.location_city, 'Saved Locations'),
          _buildSettingsTile(theme, Icons.notifications, 'Push Notifications'),
          _buildSettingsTile(theme, Icons.dark_mode, 'App Appearance', trailing: Switch(value: true, onChanged: (v){}, activeColor: theme.colorScheme.primary)),
          const SizedBox(height: 32),
          Text('Account', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildSettingsTile(theme, Icons.help_outline, 'Help & Support'),
          _buildSettingsTile(theme, Icons.logout, 'Log Out', color: theme.colorScheme.error),
        ],
      ),
    );
  }

  Widget _buildSettingsTile(ThemeData theme, IconData icon, String title, {Widget? trailing, Color? color}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color ?? theme.colorScheme.onSurface),
      ),
      title: Text(title, style: theme.textTheme.titleMedium?.copyWith(color: color ?? theme.colorScheme.onSurface)),
      trailing: trailing ?? Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurfaceVariant),
      onTap: () {},
    );
  }
}
