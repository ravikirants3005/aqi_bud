/// Exposure Insights Dashboard - REQ-5.x
library;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/models/aqi_models.dart';
import '../../../data/models/exposure_models.dart';
import '../../../domain/providers/app_providers.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(exposureDashboardProvider);
    final trendsAsync = ref.watch(aqiTrendsProvider);
    final currentAqiAsync = ref.watch(currentAqiProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF060E20),
      appBar: AppBar(
        backgroundColor: const Color(0xFF060E20),
        foregroundColor: Colors.white,
        title: const Text('Exposure Insights', style: TextStyle(fontWeight: FontWeight.w700)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF060E20),
        ),
        child: dashboardAsync.when(
          data: (dashboard) {
            if (dashboard == null) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Enable location access to generate your exposure dashboard.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final weeklyTrend =
                trendsAsync.valueOrNull?['week'] ?? const <AqiTrendDay>[];
            final monthlyTrend =
                trendsAsync.valueOrNull?['month'] ?? const <AqiTrendDay>[];
            final trackedLocation =
                _trackedLocationLabel(currentAqiAsync.valueOrNull);

            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(currentAqiProvider);
                ref.invalidate(aqiHourlyHistoryProvider);
                ref.invalidate(aqiTrendsProvider);
                ref.invalidate(exposureDashboardProvider);
              },
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      _TodayExposureCard(dashboard: dashboard),
                      const SizedBox(height: 16),
                      if (dashboard.alerts.isNotEmpty) ...[
                        _AlertsCard(alerts: dashboard.alerts),
                        const SizedBox(height: 16),
                      ],
                      _WeeklyPatternCard(
                        trend: weeklyTrend,
                        trackedLocation: trackedLocation,
                      ),
                      const SizedBox(height: 16),
                      _MonthlyTrendCard(
                        trend: monthlyTrend,
                        trackedLocation: trackedLocation,
                      ),
                      const SizedBox(height: 16),
                      _LocationInsightsCard(insights: dashboard.locationInsights),
                      const SizedBox(height: 16),
                      _SuggestionsCard(suggestions: dashboard.suggestions),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Unable to load exposure insights.\n$error',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayExposureCard extends StatelessWidget {
  const _TodayExposureCard({required this.dashboard});

  final ExposureDashboardData dashboard;

  @override
  Widget build(BuildContext context) {
    final score = dashboard.todayRecord.score;
    final scoreColor = score >= dashboard.safeLimit
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    final category = aqiToCategory(dashboard.todayRecord.maxAqi);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Pollution Exposure Score',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        score.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 46,
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                        ),
                      ),
                      Text(
                        'Safe limit: ${dashboard.safeLimit.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 94,
                  height: 94,
                  child: CircularProgressIndicator(
                    value: (score / 100).clamp(0.0, 1.0),
                    strokeWidth: 10,
                    color: scoreColor,
                    backgroundColor: scoreColor.withValues(alpha: 0.15),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricChip(
                  label: 'Max AQI',
                  value: '${dashboard.todayRecord.maxAqi}',
                  accent: Color(category.colorValue),
                ),
                _MetricChip(
                  label: 'Outdoor time',
                  value: '${dashboard.todayRecord.outdoorMinutes.inMinutes} min',
                  accent: Theme.of(context).colorScheme.primary,
                ),
                _MetricChip(
                  label: 'Tracked places',
                  value: '${dashboard.todayRecord.locationExposures.length}',
                  accent: Theme.of(context).colorScheme.secondary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyPatternCard extends StatelessWidget {
  const _WeeklyPatternCard({
    required this.trend,
    required this.trackedLocation,
  });

  final List<AqiTrendDay> trend;
  final String? trackedLocation;

  @override
  Widget build(BuildContext context) {
    if (trend.length < 2) {
      return _EmptyTrendCard(
        title: 'Weekly AQI Pattern',
        message: trackedLocation == null
            ? 'We need a bit more AQI history before the weekly pattern becomes meaningful.'
            : 'We need a bit more AQI history for $trackedLocation before the weekly pattern becomes meaningful.',
      );
    }

    final highAqiDays = trend.where((day) => day.maxAqi >= 150).length;
    final bestDay = trend.reduce((a, b) => a.maxAqi <= b.maxAqi ? a : b);
    final worstDay = trend.reduce((a, b) => a.maxAqi >= b.maxAqi ? a : b);
    final maxAqi = trend
        .map((day) => day.maxAqi)
        .reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly AQI Pattern',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (trackedLocation != null) ...[
              Text(
                'Tracking: $trackedLocation',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              '$highAqiDays high-AQI day${highAqiDays == 1 ? '' : 's'} in the last 7 days',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _SummaryStat(
                    label: 'Best day',
                    value:
                        '${DateFormat('EEE').format(bestDay.date)} | ${bestDay.maxAqi}',
                    color: const Color(0xFF69F6B8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SummaryStat(
                    label: 'Worst day',
                    value:
                        '${DateFormat('EEE').format(worstDay.date)} | ${worstDay.maxAqi}',
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 150,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: trend.map((day) {
                  final barHeight = maxAqi == 0
                      ? 18.0
                      : (day.maxAqi / maxAqi * 90).clamp(18.0, 90.0);
                  final barColor = Color(aqiToCategory(day.maxAqi).colorValue);
                  final isHighAqi = day.maxAqi >= 150;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${day.maxAqi}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            width: 28,
                            height: barHeight,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(10),
                              border: isHighAqi
                                  ? Border.all(color: Colors.black12, width: 1.5)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat('E').format(day.date),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
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
  const _MonthlyTrendCard({
    required this.trend,
    required this.trackedLocation,
  });

  final List<AqiTrendDay> trend;
  final String? trackedLocation;

  @override
  Widget build(BuildContext context) {
    if (trend.length < 2) {
      return _EmptyTrendCard(
        title: '30-Day AQI Trend',
        message: trackedLocation == null
            ? 'Monthly AQI history is not available yet.'
            : 'Monthly AQI history for $trackedLocation is not available yet.',
      );
    }

    final spots = <FlSpot>[];
    for (var i = 0; i < trend.length; i++) {
      spots.add(FlSpot(i.toDouble(), trend[i].avgAqi.toDouble()));
    }
    final maxAqi = trend.map((day) => day.maxAqi).reduce((a, b) => a > b ? a : b);
    final maxY =
        (((maxAqi + 24) ~/ 25) * 25).toDouble().clamp(100.0, 500.0).toDouble();
    final interval = maxY <= 100 ? 20.0 : (maxY / 5).ceilToDouble();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '30-Day AQI Trend',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (trackedLocation != null) ...[
              Text(
                'Tracking: $trackedLocation',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              _monthlyAqiInsight(trend),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context)
                          .colorScheme
                          .outlineVariant
                          .withValues(alpha: 0.35),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: interval,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 10),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 5,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= trend.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('d').format(trend[index].date),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) {
                          final record = trend[index];
                          return FlDotCirclePainter(
                            radius: 2.6,
                            color: Color(aqiToCategory(record.maxAqi).colorValue),
                            strokeWidth: 1,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationInsightsCard extends StatelessWidget {
  const _LocationInsightsCard({required this.insights});

  final List<FrequentLocationInsight> insights;

  @override
  Widget build(BuildContext context) {
    if (insights.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Frequent Location Insights',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Add saved locations to compare regular places like Home or Office.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Frequent Location Insights',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 14),
            ...insights.map((insight) {
              final color = Color(aqiToCategory(insight.currentAqi).colorValue);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              insight.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Text(
                            'AQI ${insight.currentAqi}',
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Weekly avg ${insight.weeklyAverageAqi.toStringAsFixed(0)} | Worst ${insight.worstAqi}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(insight.insight),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _AlertsCard extends StatelessWidget {
  const _AlertsCard({required this.alerts});

  final List<ExposureAlert> alerts;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'High-Exposure Alerts',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...alerts.map((alert) {
              final color = switch (alert.severity) {
                ExposureAlertSeverity.advisory =>
                  Theme.of(context).colorScheme.primary,
                ExposureAlertSeverity.warning => Colors.orange,
                ExposureAlertSeverity.critical =>
                  Theme.of(context).colorScheme.error,
              };

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded, color: color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(alert.message),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _SuggestionsCard extends StatelessWidget {
  const _SuggestionsCard({required this.suggestions});

  final List<String> suggestions;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Personalized Suggestions',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (suggestions.isEmpty)
              Text(
                'Your recent exposure looks stable. Keep checking AQI before long outdoor trips.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...suggestions.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(item)),
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: accent),
          ),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTrendCard extends StatelessWidget {
  const _EmptyTrendCard({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? _trackedLocationLabel(AqiData? data) {
  if (data == null) return null;
  final label = data.locationName?.trim();
  if (label != null && label.isNotEmpty) {
    return label;
  }
  return '${data.lat.toStringAsFixed(3)}, ${data.lng.toStringAsFixed(3)}';
}

String _monthlyAqiInsight(List<AqiTrendDay> trend) {
  if (trend.isEmpty) return 'Not enough AQI history yet.';

  final averageAqi =
      trend.map((day) => day.avgAqi).reduce((a, b) => a + b) / trend.length;
  final worstDay = trend.reduce((a, b) => a.maxAqi >= b.maxAqi ? a : b);
  final bestDay = trend.reduce((a, b) => a.maxAqi <= b.maxAqi ? a : b);

  return 'Average daily AQI is ${averageAqi.toStringAsFixed(0)}. Best day: ${DateFormat('d MMM').format(bestDay.date)} (${bestDay.maxAqi}), worst day: ${DateFormat('d MMM').format(worstDay.date)} (${worstDay.maxAqi}).';
}
