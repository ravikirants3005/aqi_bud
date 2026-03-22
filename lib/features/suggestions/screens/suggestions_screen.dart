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
      backgroundColor: const Color(0xFF060E20),
      appBar: AppBar(
        title: const Text('Suggestions', style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: const Color(0xFF060E20),
        elevation: 0,
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isSensitive && category.index >= AqiCategory.moderate.index)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF716A).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFFF716A).withValues(alpha: 0.3)),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.health_and_safety, color: Color(0xFFFF716A), size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Personalized for you: take extra care with outdoor activities.',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFFF716A),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: SegmentedButton<String>(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: const Color(0xFF091328),
                    selectedBackgroundColor: const Color(0xFF69F6B8).withValues(alpha: 0.15),
                    selectedForegroundColor: const Color(0xFF69F6B8),
                    foregroundColor: Colors.white70,
                    side: const BorderSide(color: Color(0xFF40485D)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F1930),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFF40485D).withValues(alpha: 0.2)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFF69F6B8).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(_phaseIcon(item.phase), color: const Color(0xFF69F6B8)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.description,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.7),
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF69F6B8))),
        error: (err, stackTrace) => const Center(child: Text('Could not load suggestions', style: TextStyle(color: Colors.white))),
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
