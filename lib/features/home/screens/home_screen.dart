/// Home Dashboard - REQ 3.1, 4.1
/// Big AQI circle, 7-day trend, exposure score card, suggestions link
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/aqi_models.dart';
import '../../../domain/providers/app_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aqiAsync = ref.watch(currentAqiProvider);
    final trendsAsync = ref.watch(aqiTrendsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AQI Buddy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(currentAqiProvider);
          ref.invalidate(aqiTrendsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              aqiAsync.when(
                data: (data) {
                  if (data == null) {
                    return _locationDisabledCard(context);
                  }
                  return _aqiCircle(context, data, isDark);
                },
                loading: () => const _AqiLoadingCard(),
                error: (e, _) => _fallbackAqiCard(),
              ),
              const SizedBox(height: 24),
              trendsAsync.when(
                data: (trends) {
                  final week = trends['week'] ?? [];
                  return _sevenDayTrend(week);
                },
                loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                error: (err, stackTrace) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 16),
              _quickCards(context),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomNav(context),
    );
  }

  Widget _aqiCircle(BuildContext context, AqiData data, bool isDark) {
    final color = Color(data.category.colorValue);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: CircularProgressIndicator(
                    value: (data.aqi / 500).clamp(0.0, 1.0),
                    strokeWidth: 12,
                    backgroundColor: color.withValues(alpha: 0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${data.aqi}',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      data.category.label,
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              data.locationName ?? 'Your location',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sevenDayTrend(List<AqiTrendDay> week) {
    if (week.isEmpty) return const SizedBox.shrink();
    final worst = week.reduce((a, b) => a.maxAqi > b.maxAqi ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('7-Day AQI Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text(
                  'Worst: ${worst.maxAqi}',
                  style: TextStyle(
                    color: Color(aqiToCategory(worst.maxAqi).colorValue),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: week.map((d) {
                  final maxVal = week.map((x) => x.maxAqi).reduce((a, b) => a > b ? a : b);
                  final h = maxVal > 0 ? (d.maxAqi / maxVal) * 60.0 : 20.0;
                  final cat = aqiToCategory(d.maxAqi);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: h.clamp(8.0, 60.0),
                        decoration: BoxDecoration(
                          color: Color(cat.colorValue),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${d.date.day}',
                        style: const TextStyle(fontSize: 10),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickCards(BuildContext context) {
    return Column(
      children: [
        _QuickCard(
          title: 'Suggestions',
          subtitle: 'Pre, during & post outdoor tips',
          icon: Icons.lightbulb_outline,
          onTap: () => context.push('/suggestions'),
        ),
        const SizedBox(height: 12),
        _QuickCard(
          title: 'Exposure Insights',
          subtitle: 'Track your pollution exposure',
          icon: Icons.analytics_outlined,
          onTap: () => context.push('/insights'),
        ),
      ],
    );
  }

  Widget _locationDisabledCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.location_off, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 12),
            const Text(
              'Location access needed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enable location to see AQI for your area.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackAqiCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('50', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold)),
            Text('Good', style: TextStyle(color: Colors.green[700], fontSize: 16)),
            const Text('Using cached data', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _bottomNav(BuildContext context) {
    return NavigationBar(
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.favorite), label: 'Health'),
        NavigationDestination(icon: Icon(Icons.school), label: 'Learn'),
      ],
      selectedIndex: 0,
      onDestinationSelected: (i) {
        if (i == 1) context.push('/health-tips');
        if (i == 2) context.push('/education');
      },
    );
  }
}

class _AqiLoadingCard extends StatelessWidget {
  const _AqiLoadingCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary)),
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
