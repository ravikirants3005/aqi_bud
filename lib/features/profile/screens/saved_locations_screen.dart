/// Favorite Locations - add, view AQI, manage
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/models/aqi_models.dart';
import '../../../data/models/user_models.dart';
import '../../../domain/providers/app_providers.dart';

class SavedLocationsScreen extends ConsumerStatefulWidget {
  const SavedLocationsScreen({super.key});

  @override
  ConsumerState<SavedLocationsScreen> createState() =>
      _SavedLocationsScreenState();
}

class _SavedLocationsScreenState extends ConsumerState<SavedLocationsScreen> {
  int _refreshTick = 0;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final locations = profile?.savedLocations ?? [];
    final notifier = ref.read(userProfileProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Locations'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh live AQI',
            onPressed: _refreshDashboard,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _refreshDashboard(),
        child: locations.isEmpty
            ? _EmptyLocationsState(onAdd: () => _showAddLocation(context, notifier, profile))
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  _DashboardHeader(
                    locations: locations,
                    refreshTick: _refreshTick,
                  ),
                  const SizedBox(height: 16),
                  ...locations.map(
                    (location) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _FavoriteLocationCard(
                        key: ValueKey('${location.id}_$_refreshTick'),
                        location: location,
                        refreshTick: _refreshTick,
                        onDelete: () => _removeLocation(notifier, profile!, location),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80),
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLocation(context, notifier, profile),
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text('Add location'),
      ),
    );
  }

  void _refreshDashboard() {
    setState(() {
      _refreshTick++;
    });
  }

  void _removeLocation(
    UserProfileNotifier notifier,
    UserProfile profile,
    SavedLocation location,
  ) {
    final updated =
        profile.savedLocations.where((item) => item.id != location.id).toList();
    notifier.updateSavedLocations(updated);
  }

  Future<void> _showAddLocation(
    BuildContext context,
    UserProfileNotifier notifier,
    UserProfile? profile,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _AddLocationDialog(
        getLocation: () => ref.read(locationProvider.future),
      ),
    );
    if (result == null || !context.mounted) return;

    final location = SavedLocation(
      id: result['id'] as String,
      name: result['name'] as String,
      lat: result['lat'] as double,
      lng: result['lng'] as double,
    );
    final current = profile?.savedLocations ?? [];
    final duplicate = current.any(
      (item) =>
          item.name.toLowerCase() == location.name.toLowerCase() ||
          ((item.lat - location.lat).abs() < 0.001 &&
              (item.lng - location.lng).abs() < 0.001),
    );
    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That location is already saved.')),
      );
      return;
    }

    notifier.updateSavedLocations([...current, location]);
  }
}

class _DashboardHeader extends ConsumerWidget {
  const _DashboardHeader({
    required this.locations,
    required this.refreshTick,
  });

  final List<SavedLocation> locations;
  final int refreshTick;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aqiRepo = ref.watch(aqiRepoProvider);

    return FutureBuilder<List<AqiData?>>(
      future: Future.wait(
        locations.map((location) => aqiRepo.getCurrentAqi(location.lat, location.lng)),
      ),
      builder: (context, snapshot) {
        final data = snapshot.data?.whereType<AqiData>().toList() ?? const <AqiData>[];
        final averageAqi = data.isEmpty
            ? 0.0
            : data.map((item) => item.aqi).reduce((a, b) => a + b) / data.length;
        final highest = data.isEmpty
            ? null
            : data.reduce((a, b) => a.aqi >= b.aqi ? a : b);
        final lowest = data.isEmpty
            ? null
            : data.reduce((a, b) => a.aqi <= b.aqi ? a : b);

        return Container(
          key: ValueKey('header_$refreshTick'),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.18),
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_tethering, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Live favorites',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${locations.length} saved',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                averageAqi == 0 ? '--' : averageAqi.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Average AQI across your favorite places',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _SummaryChip(
                      label: 'Cleanest',
                      value: lowest == null ? '--' : '${lowest.aqi}',
                      detail: lowest?.locationName ?? 'Waiting for data',
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryChip(
                      label: 'Highest AQI',
                      value: highest == null ? '--' : '${highest.aqi}',
                      detail: highest?.locationName ?? 'Waiting for data',
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FavoriteLocationCard extends ConsumerWidget {
  const _FavoriteLocationCard({
    super.key,
    required this.location,
    required this.refreshTick,
    required this.onDelete,
  });

  final SavedLocation location;
  final int refreshTick;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aqiRepo = ref.watch(aqiRepoProvider);

    return FutureBuilder<AqiData>(
      future: aqiRepo.getCurrentAqi(location.lat, location.lng),
      builder: (context, snapshot) {
        final data = snapshot.data;
        final aqi = data?.aqi ?? location.lastAqi ?? 0;
        final category = aqiToCategory(aqi);
        final color = Color(category.colorValue);
        final pm25 = data?.pm25?.toStringAsFixed(1) ?? '--';
        final pm10 = data?.pm10?.toStringAsFixed(1) ?? '--';
        final updatedAt = data?.timestamp ?? location.lastUpdated;

        return Container(
          key: ValueKey('${location.id}_$refreshTick'),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.16),
                Theme.of(context).colorScheme.surfaceContainerHighest,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Card(
            margin: EdgeInsets.zero,
            color: Colors.transparent,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              location.name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              data?.locationName ?? _coordinateLabel(location),
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Remove favorite',
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.55),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '$aqi',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const Text(
                                'AQI',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.label,
                              style: TextStyle(
                                color: color,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                _MetricTile(label: 'PM2.5', value: pm25),
                                _MetricTile(label: 'PM10', value: pm10),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _advisoryText(aqi, location.name),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          updatedAt == null
                              ? 'Live reading pending.'
                              : 'Updated ${DateFormat('hh:mm a').format(updatedAt)}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _coordinateLabel(SavedLocation location) =>
      '${location.lat.toStringAsFixed(3)}, ${location.lng.toStringAsFixed(3)}';

  String _advisoryText(int aqi, String name) {
    if (aqi >= 150) {
      return '$name is unhealthy right now. Avoid long outdoor stays there.';
    }
    if (aqi >= 100) {
      return '$name has elevated pollution. Keep outdoor trips shorter.';
    }
    if (aqi >= 50) {
      return '$name is moderate right now. Check AQI before exercise.';
    }
    return '$name is one of your safer spots at the moment.';
  }
}

class _EmptyLocationsState extends StatelessWidget {
  const _EmptyLocationsState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                  Theme.of(context).colorScheme.secondary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.location_searching,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                const Text(
                  'No favorite locations yet',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add home, office, school, or any place you visit often to track live AQI in one dashboard.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Add first location'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.detail,
    required this.color,
  });

  final String label;
  final String value;
  final String detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            detail,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
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
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
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
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _AddLocationDialog extends StatefulWidget {
  const _AddLocationDialog({required this.getLocation});

  final Future<dynamic> Function() getLocation;

  @override
  State<_AddLocationDialog> createState() => _AddLocationDialogState();
}

class _AddLocationDialogState extends State<_AddLocationDialog> {
  final _nameCtrl = TextEditingController();
  bool _useCurrent = true;
  double? _lat;
  double? _lng;

  @override
  void initState() {
    super.initState();
    widget.getLocation().then((position) {
      if (position != null && mounted) {
        setState(() {
          _lat = position.latitude;
          _lng = position.longitude;
        });
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add location'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Name (e.g. Home, Office)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _useCurrent,
                onChanged: (value) => setState(() => _useCurrent = value ?? true),
              ),
              const Expanded(child: Text('Use current location')),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () async {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enter a location name')),
              );
              return;
            }

            double? lat = _lat;
            double? lng = _lng;
            if (_useCurrent) {
              final position = await widget.getLocation();
              if (position != null) {
                lat = position.latitude;
                lng = position.longitude;
              }
            }

            if (lat == null || lng == null) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enable location to add the current place'),
                  ),
                );
              }
              return;
            }

            if (context.mounted) {
              Navigator.pop(context, {
                'id': 'loc_${DateTime.now().millisecondsSinceEpoch}',
                'name': name,
                'lat': lat,
                'lng': lng,
              });
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
