/// Exposure Insights Dashboard - REQ-5.x
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/aqi_models.dart';
import '../../../domain/providers/app_providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aqiAsync = ref.watch(currentAqiProvider);
    final trendsAsync = ref.watch(aqiTrendsProvider);
    final exposureRepo = ref.watch(exposureRepoProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exposure Insights'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: FutureBuilder(
        future: exposureRepo.getWeeklyExposure(),
        builder: (ctx, weeklySnap) {
          return FutureBuilder(
            future: exposureRepo.getMonthlyExposure(),
            builder: (ctx, monthlySnap) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    aqiAsync.when(
                      data: (aqi) {
                        if (aqi == null) return const SizedBox.shrink();
                        final score = exposureRepo.calculateExposureScore(
                          maxAqi: aqi.aqi,
                          outdoorMinutes: const Duration(minutes: 60),
                        );
                        return _ExposureScoreCard(score: score);
                      },
                      loading: () => const Card(child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      )),
                      error: (err, stackTrace) => _ExposureScoreCard(score: 0),
                    ),
                    const SizedBox(height: 16),
                    trendsAsync.when(
                      data: (trends) {
                        final week = trends['week'] ?? [];
                        final month = trends['month'] ?? [];
                        return Column(
                          children: [
                            if (week.isNotEmpty) _WeeklyPatternCard(days: week),
                            const SizedBox(height: 16),
                            if (month.isNotEmpty) _MonthlyTrendCard(days: month),
                            const SizedBox(height: 16),
                            FutureBuilder(
                              future: exposureRepo.hasHighExposureStreak(),
                              builder: (context, snap) {
                                if (snap.data == true) {
                                  return Card(
                                    color: Theme.of(context).colorScheme.errorContainer,
                                    child: const Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Icon(Icons.warning_amber, size: 40),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: Text(
                                              'High exposure for 7+ days. Consider reducing outdoor time and visiting low-AQI areas.',
                                              style: TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                          ],
                        );
                      },
                      loading: () => const SizedBox(height: 120, child: Center(child: CircularProgressIndicator())),
                      error: (err, stackTrace) => const SizedBox.shrink(),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ExposureScoreCard extends StatelessWidget {
  final double score;

  const _ExposureScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    final color = score >= 70 ? Colors.red : score >= 50 ? Colors.orange : Colors.green;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text('Today\'s Exposure Score', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text(
              score.toStringAsFixed(0),
              style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: color),
            ),
            Text('/ 100', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _WeeklyPatternCard extends StatelessWidget {
  final List<AqiTrendDay> days;

  const _WeeklyPatternCard({required this.days});

  @override
  Widget build(BuildContext context) {
    final worst = days.reduce((a, b) => a.maxAqi > b.maxAqi ? a : b);
    final best = days.reduce((a, b) => a.maxAqi < b.maxAqi ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Weekly AQI Pattern', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Best: ${best.maxAqi}', style: TextStyle(color: Colors.green[700])),
                Text('Worst: ${worst.maxAqi}', style: TextStyle(color: Color(aqiToCategory(worst.maxAqi).colorValue))),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: days.map((d) {
                  final maxVal = days.map((x) => x.maxAqi).reduce((a, b) => a > b ? a : b);
                  final h = maxVal > 0 ? (d.maxAqi / maxVal) * 70.0 : 20.0;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 20,
                        height: h.clamp(8.0, 70.0),
                        decoration: BoxDecoration(
                          color: Color(aqiToCategory(d.maxAqi).colorValue),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('${d.date.day}', style: const TextStyle(fontSize: 10)),
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
}

class _MonthlyTrendCard extends StatelessWidget {
  final List<AqiTrendDay> days;

  const _MonthlyTrendCard({required this.days});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('30-Day AQI Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: days.length,
                itemBuilder: (_, i) {
                  final d = days[i];
                  final maxVal = days.map((x) => x.maxAqi).reduce((a, b) => a > b ? a : b);
                  final h = maxVal > 0 ? (d.maxAqi / maxVal) * 60.0 : 16.0;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: h.clamp(4.0, 60.0),
                          decoration: BoxDecoration(
                            color: Color(aqiToCategory(d.maxAqi).colorValue),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        if (i % 5 == 0)
                          Text('${d.date.day}', style: const TextStyle(fontSize: 8)),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
