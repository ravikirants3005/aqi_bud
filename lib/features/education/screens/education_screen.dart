/// Education Module - REQ-6.x
/// What is AQI, pollutants, health effects
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/repositories/education_repository.dart';
import '../../../domain/providers/app_providers.dart';

class EducationScreen extends ConsumerWidget {
  const EducationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.watch(educationRepoProvider);
    final topics = repo.getAll();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn About Air Quality'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: topics.length,
        itemBuilder: (_, i) {
          final t = topics[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                child: Icon(
                  t.id == 'what_is_aqi' ? Icons.help : Icons.science,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(
                t.content.length > 80 ? '${t.content.substring(0, 80)}...' : t.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
              isThreeLine: true,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _TopicDetailScreen(topic: t),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TopicDetailScreen extends StatelessWidget {
  final EducationTopic topic;

  const _TopicDetailScreen({required this.topic});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(topic.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (topic.kidFriendly)
              Chip(
                label: const Text('Kid-friendly'),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
            const SizedBox(height: 16),
            Text(
              topic.content,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }
}
