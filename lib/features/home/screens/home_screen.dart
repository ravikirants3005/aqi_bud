/// Home Dashboard - REQ 3.1, 4.1
/// Big AQI circle, 7-day trend, exposure score card, suggestions link
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/aqi_models.dart';
import '../../../data/models/user_models.dart';
import '../../../domain/providers/app_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aqiAsync = ref.watch(currentAqiProvider);
    final trendsAsync = ref.watch(aqiTrendsProvider);
    final profile = ref.watch(userProfileProvider);
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
          ref.invalidate(locationProvider);
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
                    return _locationDisabledCard(context, ref);
                  }
                  return _aqiCircle(context, ref, profile, data, isDark);
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
                loading: () => const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
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

  Widget _aqiCircle(
    BuildContext context,
    WidgetRef ref,
    UserProfile? profile,
    AqiData data,
    bool isDark,
  ) {
    final color = Color(data.category.colorValue);
    final savedLocations = profile?.savedLocations ?? const <SavedLocation>[];
    final alreadySaved = savedLocations.any(
      (location) =>
          (location.lat - data.lat).abs() < 0.001 &&
          (location.lng - data.lng).abs() < 0.001,
    );

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: isDark ? 0.28 : 0.16),
            Theme.of(context).colorScheme.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Card(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _InfoPill(
                    icon: Icons.wifi_tethering,
                    label: 'Live AQI',
                    color: color,
                  ),
                  const SizedBox(width: 10),
                  _InfoPill(
                    icon: Icons.place_outlined,
                    label: data.locationName ?? 'Current location',
                    color: Theme.of(context).colorScheme.primary,
                    expand: true,
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current air quality',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          data.category.label,
                          style: TextStyle(
                            color: color,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _StatTag(
                              label: 'PM2.5',
                              value: data.pm25?.toStringAsFixed(1) ?? '--',
                            ),
                            _StatTag(
                              label: 'PM10',
                              value: data.pm10?.toStringAsFixed(1) ?? '--',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 168,
                        height: 168,
                        child: CircularProgressIndicator(
                          value: (data.aqi / 500).clamp(0.0, 1.0),
                          strokeWidth: 14,
                          backgroundColor: color.withValues(alpha: 0.18),
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${data.aqi}',
                            style: const TextStyle(
                              fontSize: 46,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'US AQI',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor:
                        alreadySaved ? color.withValues(alpha: 0.7) : color,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: alreadySaved
                      ? null
                      : () => _saveCurrentLocation(context, ref, profile, data),
                  icon: Icon(
                    alreadySaved ? Icons.check_circle_outline : Icons.favorite_border,
                  ),
                  label: Text(
                    alreadySaved
                        ? 'Saved in favorites'
                        : 'Save current location',
                  ),
                ),
              ),
            ],
          ),
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
                const Text(
                  '7-Day AQI Trend',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
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
                children: week.map((day) {
                  final maxVal =
                      week.map((item) => item.maxAqi).reduce((a, b) => a > b ? a : b);
                  final height = maxVal > 0 ? (day.maxAqi / maxVal) * 60.0 : 20.0;
                  final cat = aqiToCategory(day.maxAqi);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: height.clamp(8.0, 60.0),
                        decoration: BoxDecoration(
                          color: Color(cat.colorValue),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${day.date.day}',
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

  Widget _locationDisabledCard(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.location_off,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            const Text(
              'Location access needed',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Allow device location so the app can fetch AQI for your current area.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _requestLocationAccess(context, ref),
              icon: const Icon(Icons.my_location),
              label: const Text('Allow location access'),
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
            const Text(
              '50',
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            Text(
              'Good',
              style: TextStyle(color: Colors.green[700], fontSize: 16),
            ),
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

  Future<void> _requestLocationAccess(BuildContext context, WidgetRef ref) async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Turn on device location services and try again.'),
          ),
        );
      }
      return;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      await Geolocator.openAppSettings();
      return;
    }

    if (permission == LocationPermission.denied) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission denied. AQI cannot be loaded.'),
          ),
        );
      }
      return;
    }

    ref.invalidate(locationProvider);
    ref.invalidate(currentAqiProvider);
    ref.invalidate(aqiTrendsProvider);
  }

  Future<void> _saveCurrentLocation(
    BuildContext context,
    WidgetRef ref,
    UserProfile? profile,
    AqiData data,
  ) async {
    final notifier = ref.read(userProfileProvider.notifier);
    final current = profile?.savedLocations ?? const <SavedLocation>[];
    final locationName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController(
          text: data.locationName ?? 'Current location',
        );
        return AlertDialog(
          title: const Text('Save favorite location'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Location name',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) return;
                Navigator.pop(dialogContext, name);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (!context.mounted || locationName == null || locationName.isEmpty) {
      return;
    }

    final duplicate = current.any(
      (location) =>
          location.name.toLowerCase() == locationName.toLowerCase() ||
          ((location.lat - data.lat).abs() < 0.001 &&
              (location.lng - data.lng).abs() < 0.001),
    );
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This location is already in favorites.')),
      );
      return;
    }

    final saved = SavedLocation(
      id: 'loc_${DateTime.now().millisecondsSinceEpoch}',
      name: locationName,
      lat: data.lat,
      lng: data.lng,
      lastAqi: data.aqi,
      lastUpdated: data.timestamp,
    );
    notifier.updateSavedLocations([...current, saved]);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$locationName added to favorite locations.')),
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
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
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

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
    this.expand = false,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
    );

    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          if (expand) Expanded(child: text) else Flexible(child: text),
        ],
      ),
    );
    return expand ? Expanded(child: child) : child;
  }
}

class _StatTag extends StatelessWidget {
  const _StatTag({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
