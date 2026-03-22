import 'package:flutter/material.dart';

class HealthTipsScreen extends StatelessWidget {
  const HealthTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Tips'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('General Health Precautions', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildTipCard(theme, 'PM2.5 Awareness', 'Particles are extremely small and can be inhaled deep into the lungs.'),
          const SizedBox(height: 12),
          _buildTipCard(theme, 'Limit Outdoor Exertion', 'When AQI is above 100, sensitive groups should limit prolonged exertion.'),
          const SizedBox(height: 12),
          _buildTipCard(theme, 'Wear N95 Masks', 'Regular masks don\'t filter PM2.5. Use N95 masks when pollution is severe.'),
        ],
      ),
    );
  }

  Widget _buildTipCard(ThemeData theme, String title, String details) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
          const SizedBox(height: 8),
          Text(details, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface)),
        ],
      ),
    );
  }
}
