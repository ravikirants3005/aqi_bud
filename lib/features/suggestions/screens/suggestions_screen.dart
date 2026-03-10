/// Suggestions Screen - REQ-2.x
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/aqi_models.dart';
import '../../../domain/providers/app_providers.dart';

final _suggestionPhaseProvider = StateProvider<String>((_) => 'all');

class SuggestionsScreen extends ConsumerWidget {
  const SuggestionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aqiAsync = ref.watch(currentAqiProvider);
    final suggestions = ref.watch(suggestionsRepoProvider);
    final phase = ref.watch(_suggestionPhaseProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suggestions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: aqiAsync.when(
        data: (data) {
          final profile = ref.watch(userProfileProvider);
          final sensitivity = profile?.healthSensitivity;
          final category = data != null ? data.category : AqiCategory.good;
          final items = phase == 'all'
              ? suggestions.getAllSuggestions(category)
              : suggestions.getSuggestions(category, phase);

          final isSensitive = sensitivity == HealthSensitivity.sensitive ||
              sensitivity == HealthSensitivity.asthmatic ||
              sensitivity == HealthSensitivity.elderly;
          return Column(
            children: [
              if (isSensitive && category.index >= AqiCategory.moderate.index)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.health_and_safety,
                              color: Theme.of(context).colorScheme.onPrimaryContainer),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Personalized for you: take extra care with outdoor activities.',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(value: 'all', label: Text('All'), icon: Icon(Icons.list)),
                    ButtonSegment(value: 'pre', label: Text('Pre'), icon: Icon(Icons.upload)),
                    ButtonSegment(value: 'during', label: Text('During'), icon: Icon(Icons.directions_walk)),
                    ButtonSegment(value: 'post', label: Text('Post'), icon: Icon(Icons.download)),
                  ],
                  selected: {phase},
                  onSelectionChanged: (s) => ref.read(_suggestionPhaseProvider.notifier).state = s.first,
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(_phaseIcon(item.phase)),
                        ),
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(item.description),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stackTrace) => const Center(child: Text('Could not load suggestions')),
      ),
    );
  }

  IconData _phaseIcon(String phase) {
    switch (phase) {
      case 'pre': return Icons.upload;
      case 'during': return Icons.directions_walk;
      case 'post': return Icons.download;
      default: return Icons.lightbulb_outline;
    }
  }
}
