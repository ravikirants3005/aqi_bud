import 'package:flutter/material.dart';

class EducationScreen extends StatelessWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Air Quality Education'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildArticleCard(
            theme,
            'Understanding PM2.5',
            'Learn why particulate matter smaller than 2.5 micrometers is dangerous and how to protect yourself.',
            '5 min read',
            'assets/images/placeholder_pm25.png',
          ),
          const SizedBox(height: 16),
          _buildArticleCard(
            theme,
            'The Ozone Layer & Ground Level Ozone',
            'Discover the difference between good ozone and bad ozone, and how it affects lung health.',
            '4 min read',
            'assets/images/placeholder_ozone.png',
          ),
          const SizedBox(height: 16),
          _buildArticleCard(
            theme,
            'Indoor vs Outdoor Defenses',
            'Best practices for maintaining safe indoor air quality when external elements are severe.',
            '7 min read',
            'assets/images/placeholder_indoor.png',
          ),
        ],
      ),
    );
  }

  Widget _buildArticleCard(ThemeData theme, String title, String snippet, String readTime, String imageUrl) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            color: theme.colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: Icon(Icons.menu_book, size: 48, color: theme.colorScheme.primary.withOpacity(0.5)),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  snippet,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      readTime,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
