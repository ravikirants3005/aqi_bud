/// Favorite Locations - add, view AQI, manage
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final locations = profile?.savedLocations ?? [];
    final aqiRepo = ref.watch(aqiRepoProvider);
    final notifier = ref.read(userProfileProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Locations'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: locations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.location_off,
                      size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  const Text('No saved locations yet'),
                  const SizedBox(height: 8),
                  Text(
                    'Add home, office, or school to track AQI',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: locations.length,
              itemBuilder: (context, i) {
                final loc = locations[i];
                return FutureBuilder(
                  future: aqiRepo.getCurrentAqi(loc.lat, loc.lng),
                  builder: (context, snap) {
                    final aqi = snap.data?.aqi ?? loc.lastAqi ?? 0;
                    final cat = aqiToCategory(aqi);
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(cat.colorValue).withValues(alpha: 0.3),
                          child: Text(
                            '$aqi',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        title: Text(loc.name),
                        subtitle: Text(cat.label),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeLocation(notifier, profile!, loc),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddLocation(context, notifier, profile),
        icon: const Icon(Icons.add_location),
        label: const Text('Add location'),
      ),
    );
  }

  void _removeLocation(
      UserProfileNotifier notifier, UserProfile profile, SavedLocation loc) {
    final updated =
        profile.savedLocations.where((l) => l.id != loc.id).toList();
    notifier.updateSavedLocations(updated);
  }

  Future<void> _showAddLocation(
    BuildContext context,
    UserProfileNotifier notifier,
    UserProfile? profile,
  ) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => _AddLocationDialog(
        getLocation: () => ref.read(locationProvider.future),
      ),
    );
    if (result == null || !context.mounted) return;

    final loc = SavedLocation(
      id: result['id'] as String,
      name: result['name'] as String,
      lat: result['lat'] as double,
      lng: result['lng'] as double,
    );
    final current = profile?.savedLocations ?? [];
    if (current.any((l) => l.id == loc.id)) return;
    notifier.updateSavedLocations([...current, loc]);
  }
}

class _AddLocationDialog extends StatefulWidget {
  final Future<dynamic> Function() getLocation;

  const _AddLocationDialog({required this.getLocation});

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
    widget.getLocation().then((pos) {
      if (pos != null && mounted) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
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
                onChanged: (v) => setState(() => _useCurrent = v ?? true),
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
                const SnackBar(content: Text('Enter a name')),
              );
              return;
            }
            double? lat = _lat;
            double? lng = _lng;
            if (_useCurrent) {
              final pos = await widget.getLocation();
              if (pos != null) {
                lat = pos.latitude;
                lng = pos.longitude;
              }
            }
            if (lat == null || lng == null) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Enable location to add current place')),
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
