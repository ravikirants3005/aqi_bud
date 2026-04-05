/// Home Dashboard - live AQI command center
library;

import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/models/aqi_models.dart';
import '../../../data/models/user_models.dart';
import '../../../domain/providers/app_providers.dart';
import '../../../core/services/simple_location_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aqiAsync = ref.watch(currentAqiProvider);
    final historyAsync = ref.watch(aqiHourlyHistoryProvider);
    final trendsAsync = ref.watch(aqiTrendsProvider);
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF081217),
      appBar: AppBar(
        backgroundColor: const Color(0xFF12242B),
        foregroundColor: Colors.white,
        title: const Text('AQI Buddy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push('/profile'),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF081217), Color(0xFF0D1A21), Color(0xFF122A34)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(locationProvider);
            ref.invalidate(currentAqiProvider);
            ref.invalidate(aqiHourlyHistoryProvider);
            ref.invalidate(aqiTrendsProvider);
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1180),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      aqiAsync.when(
                        data: (data) => data == null
                            ? _LocationDisabledCard(ref: ref)
                            : _HeroCard(
                                data: data,
                                profile: profile,
                                onSave: () => _saveCurrentLocation(
                                  context,
                                  ref,
                                  profile,
                                  data,
                                ),
                              ),
                        loading: () => const _LoadingPanel(height: 320),
                        error: (error, _) => const _MessagePanel(
                          title: 'Live AQI snapshot unavailable',
                          message:
                              'The dashboard will refresh as soon as the current AQI feed responds.',
                        ),
                      ),
                      const SizedBox(height: 20),
                      historyAsync.when(
                        data: (history) => _HourlyHistoryCard(
                          currentData: aqiAsync.valueOrNull,
                          history: history,
                        ),
                        loading: () => const _LoadingPanel(height: 300),
                        error: (error, _) => const _MessagePanel(
                          title: '24-Hour AQI Wave',
                          message:
                              'Live hourly history could not be loaded right now.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomNav(context),
    );
  }

  Widget _bottomNav(BuildContext context) {
    return NavigationBarTheme(
      data: NavigationBarThemeData(
        backgroundColor: const Color(0xFF091328),
        indicatorColor: const Color(0xFF192540),
        labelTextStyle: MaterialStatePropertyAll(
          TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: NavigationBar(
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.favorite_rounded),
            label: 'Health',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_rounded),
            label: 'Learn',
          ),
        ],
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 1) context.push('/health-tips');
          if (index == 2) context.push('/education');
        },
    ),
    );
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
        final controller = TextEditingController(text: _locationLabel(data));
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

    final savedLocation = SavedLocation(
      id: 'loc_${DateTime.now().millisecondsSinceEpoch}',
      name: locationName,
      lat: data.lat,
      lng: data.lng,
      lastAqi: data.aqi,
      lastUpdated: data.timestamp,
    );

    try {
      await notifier.updateSavedLocations([...current, savedLocation]);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$locationName saved to backend!')),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving location: $e')),
      );
    }
  }
}

class _HeroCard extends ConsumerWidget {
  const _HeroCard({
    required this.data,
    required this.profile,
    required this.onSave,
  });

  final AqiData data;
  final UserProfile? profile;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = Color(data.category.colorValue);
    final savedLocations = profile?.savedLocations ?? const <SavedLocation>[];
    final alreadySaved = savedLocations.any(
      (location) =>
          (location.lat - data.lat).abs() < 0.001 &&
          (location.lng - data.lng).abs() < 0.001,
    );

    return _Panel(
      gradient: LinearGradient(
        colors: [
          const Color(0xFF0F1930),
          accent.withValues(alpha: 0.10),
          const Color(0xFF192540),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;
            final info = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _Pill(
                      icon: Icons.radar_rounded,
                      label: 'Live AQI',
                      color: accent,
                    ),
                    _Pill(
                      icon: Icons.place_outlined,
                      label: _locationLabel(data),
                      color: const Color(0xFF69F6B8),
                      onTap: () => _correctLocation(context, ref, data),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Current air quality',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data.category.label,
                  style: TextStyle(
                    color: accent,
                    fontSize: compact ? 30 : 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _headline(data.aqi),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _MetricTile(
                      label: 'PM2.5',
                      value: data.pm25?.toStringAsFixed(1) ?? '--',
                    ),
                    _MetricTile(
                      label: 'PM10',
                      value: data.pm10?.toStringAsFixed(1) ?? '--',
                    ),
                    _MetricTile(
                      label: 'Updated',
                      value: DateFormat('hh:mm a').format(data.timestamp),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: alreadySaved ? null : onSave,
                  style: FilledButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                  ),
                  icon: Icon(
                    alreadySaved
                        ? Icons.check_circle_outline
                        : Icons.favorite_border,
                  ),
                  label: Text(
                    alreadySaved
                        ? 'Saved in favorites'
                        : 'Save current location',
                  ),
                ),
              ],
            );

            final gauge = Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.12),
                    blurRadius: 40,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: (data.aqi / 500).clamp(0.0, 1.0),
                      strokeWidth: 8,
                      backgroundColor: accent.withValues(alpha: 0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(accent),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${data.aqi}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 56,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        'US AQI',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          letterSpacing: 1.1,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  info,
                  const SizedBox(height: 24),
                  Center(child: gauge),
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: info),
                const SizedBox(width: 24),
                gauge,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HourlyHistoryCard extends StatelessWidget {
  const _HourlyHistoryCard({required this.currentData, required this.history});

  final AqiData? currentData;
  final List<AqiHourlyPoint> history;

  @override
  Widget build(BuildContext context) {
    final last24 = _recent24Hours(history);
    if (last24.length < 3) {
      return _MessagePanel(
        title: '24-Hour AQI Wave',
        message: currentData == null
            ? 'Live hourly history is not available until the current location is loaded.'
            : 'Hourly history for ${_locationLabel(currentData!)} is still loading.',
      );
    }

    final minAqi = last24.map((point) => point.aqi).reduce(math.min);
    final maxAqi = last24.map((point) => point.aqi).reduce(math.max);
    final avgAqi =
        (last24.map((point) => point.aqi).reduce((a, b) => a + b) /
                last24.length)
            .round();
    final maxY = math.max(100, (((maxAqi + 24) ~/ 25) * 25)).toDouble();
    final interval = maxY <= 100 ? 20.0 : (maxY / 5).ceilToDouble();

    return _Panel(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '24-Hour AQI Wave',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currentData == null
                  ? 'Live hourly AQI history'
                  : 'Tracking ${_locationLabel(currentData!)} with live hourly sensor history',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatChip(
                  label: 'Now',
                  value: '${last24.last.aqi}',
                  accent: Color(aqiToCategory(last24.last.aqi).colorValue),
                ),
                _StatChip(
                  label: '24h Avg',
                  value: '$avgAqi',
                  accent: const Color(0xFF69F6B8),
                ),
                _StatChip(
                  label: '24h Max',
                  value: '$maxAqi',
                  accent: Color(aqiToCategory(maxAqi).colorValue),
                ),
                _StatChip(
                  label: '24h Min',
                  value: '$minAqi',
                  accent: Color(aqiToCategory(minAqi).colorValue),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 240,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: interval,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white.withValues(alpha: 0.08),
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
                        reservedSize: 34,
                        interval: interval,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.58),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: _xInterval(last24.length),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= last24.length)
                            return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('ha').format(last24[index].time),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.58),
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF141F38),
                      getTooltipItems: (spots) => spots.map((spot) {
                        final point = last24[spot.x.toInt()];
                        return LineTooltipItem(
                          '${DateFormat('dd MMM, hh:mm a').format(point.time)}\nAQI ${point.aqi}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < last24.length; i++)
                          FlSpot(i.toDouble(), last24[i].aqi.toDouble()),
                      ],
                      isCurved: true,
                      curveSmoothness: 0.28,
                      color: const Color(0xFF20C5D8),
                      barWidth: 3.5,
                      belowBarData: BarAreaData(
                        show: true,
                        color: const Color(0xFF20C5D8).withValues(alpha: 0.12),
                      ),
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, bar, index) =>
                            FlDotCirclePainter(
                              radius: 3,
                              color: Color(
                                aqiToCategory(last24[index].aqi).colorValue,
                              ),
                              strokeWidth: 1.2,
                              strokeColor: Colors.white,
                            ),
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

class _SevenDayCard extends StatelessWidget {
  const _SevenDayCard({required this.currentData, required this.week});

  final AqiData? currentData;
  final List<AqiTrendDay> week;

  @override
  Widget build(BuildContext context) {
    if (week.length < 2) {
      return _MessagePanel(
        title: '7-Day AQI Pattern',
        message: currentData == null
            ? 'Weekly AQI history will appear after the live location loads.'
            : 'Weekly AQI history for ${_locationLabel(currentData!)} is still loading.',
      );
    }

    final worst = week.reduce((a, b) => a.maxAqi >= b.maxAqi ? a : b);
    final best = week.reduce((a, b) => a.maxAqi <= b.maxAqi ? a : b);
    final average =
        (week.map((day) => day.avgAqi).reduce((a, b) => a + b) / week.length)
            .round();
    final maxY = math
        .max(
          100,
          (((week.map((day) => day.maxAqi).reduce(math.max) + 24) ~/ 25) * 25),
        )
        .toDouble();

    return _Panel(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '7-Day AQI Pattern',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currentData == null
                  ? 'Daily AQI maxima for the last 7 days'
                  : 'Daily AQI maxima for ${_locationLabel(currentData!)}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _StatChip(
                  label: 'Best day',
                  value:
                      '${DateFormat('EEE').format(best.date)} ${best.maxAqi}',
                  accent: Color(aqiToCategory(best.maxAqi).colorValue),
                ),
                _StatChip(
                  label: 'Worst day',
                  value:
                      '${DateFormat('EEE').format(worst.date)} ${worst.maxAqi}',
                  accent: Color(aqiToCategory(worst.maxAqi).colorValue),
                ),
                _StatChip(
                  label: '7d Avg',
                  value: '$average',
                  accent: const Color(0xFF69F6B8),
                ),
              ],
            ),
            const SizedBox(height: 22),
            SizedBox(
              height: 240,
              child: BarChart(
                BarChartData(
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxY <= 100 ? 20 : maxY / 5,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Colors.white.withValues(alpha: 0.08),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => const Color(0xFF141F38),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final day = week[group.x.toInt()];
                        return BarTooltipItem(
                          '${DateFormat('EEE, dd MMM').format(day.date)}\nMax ${day.maxAqi} | Avg ${day.avgAqi}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        );
                      },
                    ),
                  ),
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
                        reservedSize: 34,
                        interval: maxY <= 100 ? 20 : maxY / 5,
                        getTitlesWidget: (value, meta) => Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.58),
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= week.length)
                            return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('E').format(week[index].date),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.62),
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < week.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: week[i].maxAqi.toDouble(),
                            width: 26,
                            borderRadius: BorderRadius.circular(10),
                            color: Color(
                              aqiToCategory(week[i].maxAqi).colorValue,
                            ),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxY,
                              color: Colors.white.withValues(alpha: 0.04),
                            ),
                          ),
                        ],
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

class _ActionDeck extends StatelessWidget {
  const _ActionDeck();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stacked = constraints.maxWidth < 800;
        final suggestions = _ActionCard(
          title: 'Suggestions',
          subtitle: 'Practical pre, during and post outdoor guidance.',
          icon: Icons.tips_and_updates_outlined,
          accent: const Color(0xFF69F6B8),
          onTap: () => context.push('/suggestions'),
        );
        final insights = _ActionCard(
          title: 'Exposure Insights',
          subtitle: 'Break down weekly and monthly AQI history in detail.',
          icon: Icons.insights_outlined,
          accent: const Color(0xFFF8A010),
          onTap: () => context.push('/insights'),
        );

        if (stacked) {
          return Column(
            children: [suggestions, const SizedBox(height: 14), insights],
          );
        }

        return Row(
          children: [
            Expanded(child: suggestions),
            const SizedBox(width: 14),
            Expanded(child: insights),
          ],
        );
      },
    );
  }
}

class _LocationDisabledCard extends StatelessWidget {
  const _LocationDisabledCard({
    required this.ref,
    this.permissionGranted = false,
  });

  final WidgetRef ref;
  final bool permissionGranted;

  @override
  Widget build(BuildContext context) {
    final title = permissionGranted
        ? 'Still seeking location...'
        : 'Location access needed';
    final message = permissionGranted
        ? 'Permission is granted, but we haven\'t received a GPS signal yet. Make sure your device has a clear view of the sky or is near a window.'
        : 'Allow device location so AQI Buddy can fetch live AQI and real trend history for wherever you are.';
    final buttonLabel = permissionGranted
        ? 'Try refreshing'
        : 'Allow location access';

    return _Panel(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              permissionGranted
                  ? Icons.location_searching
                  : Icons.location_off_outlined,
              size: 52,
              color: permissionGranted
                  ? Colors.blue
                  : Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => _requestLocationAccess(context, ref),
              icon: Icon(permissionGranted ? Icons.refresh : Icons.my_location),
              label: Text(buttonLabel),
            ),
            if (!permissionGranted) ...[
              const SizedBox(height: 10),
              Text(
                'On Windows, the system may ask through Privacy & security > Location settings.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child, this.gradient});

  final Widget child;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: gradient == null ? const Color(0xFF0F1930) : null,
        gradient: gradient,
        border: Border.all(
          color: const Color(0xFF40485D).withValues(alpha: 0.15),
        ),
      ),
      child: child,
    );
  }
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel({required this.height, this.message});

  final double height;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: SizedBox(
        height: height,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: [const Color(0xFF0F1930), accent.withValues(alpha: 0.10)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFF40485D).withValues(alpha: 0.15),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.68),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_rounded, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label, required this.color, this.onTap});

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: color.withValues(alpha: 0.12),
          border: Border.all(
            color: const Color(0xFF40485D).withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 260),
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.black.withValues(alpha: 0.24),
        border: Border.all(
          color: const Color(0xFF40485D).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.64),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ForecastCard extends StatelessWidget {
  const _ForecastCard({required this.currentData, required this.forecast});

  final AqiData? currentData;
  final List<Map<String, dynamic>> forecast;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.white.withValues(alpha: 0.72),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  '7-Day AQI Forecast',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (forecast.isEmpty)
              Text(
                'No forecast data available',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              )
            else
              Column(
                children: forecast.take(7).map((day) {
                  final date = day['date'] ?? 'Unknown';
                  final aqi = day['aqi'] ?? 0;
                  final pm25 = day['pm25'] ?? 0;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            date,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.84),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'AQI: $aqi',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.84),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'PM2.5: $pm25',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.84),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF40485D).withValues(alpha: 0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

List<AqiHourlyPoint> _recent24Hours(List<AqiHourlyPoint> history) {
  if (history.isEmpty) return const <AqiHourlyPoint>[];
  final cutoff = DateTime.now().subtract(const Duration(hours: 24));
  final recent = history.where((point) => point.time.isAfter(cutoff)).toList();
  if (recent.length >= 3) return recent;
  return history.length > 24 ? history.sublist(history.length - 24) : history;
}

double _xInterval(int pointCount) {
  if (pointCount <= 6) return 1;
  if (pointCount <= 12) return 2;
  if (pointCount <= 18) return 3;
  return 4;
}

String _headline(int aqi) {
  if (aqi <= 50)
    return 'Air looks clear right now. Outdoor plans are in a safe zone.';
  if (aqi <= 100)
    return 'Conditions are manageable, but sensitive groups should stay alert.';
  if (aqi <= 150)
    return 'Sensitive groups may feel the impact. Keep long outdoor time short.';
  if (aqi <= 200) return 'Air is unhealthy. Reduce strenuous outdoor activity.';
  if (aqi <= 300)
    return 'Air quality is very unhealthy. Protective steps are strongly advised.';
  return 'Hazardous air conditions. Staying indoors is the safer choice.';
}

String _locationLabel(AqiData data) {
  final label = data.locationName?.trim();
  if (label != null && label.isNotEmpty) {
    return label;
  }

  // If no location name, provide a more user-friendly coordinate display
  return 'Location: ${data.lat.toStringAsFixed(3)}, ${data.lng.toStringAsFixed(3)}';
}

void _correctLocation(BuildContext context, WidgetRef ref, AqiData data) async {
  final controller = TextEditingController(text: _locationLabel(data));
  
  final correctedName = await showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Correct Location'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Current location detected:'),
          const SizedBox(height: 8),
          Text(
            'GPS: ${data.lat.toStringAsFixed(6)}, ${data.lng.toStringAsFixed(6)}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          const Text('Enter correct location name:'),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'e.g., Your Area, Bengaluru',
              border: OutlineInputBorder(),
            ),
            maxLength: 50,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
          child: const Text('Update'),
        ),
      ],
    ),
  );
  
  if (correctedName != null && correctedName.isNotEmpty) {
    // Set the location name override
    ref.read(locationNameOverrideProvider.notifier).state = correctedName;
    
    // Invalidate the AQI provider to refresh with the new name
    ref.invalidate(currentAqiProvider);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location updated to: $correctedName'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
}

Future<void> _requestLocationAccess(BuildContext context, WidgetRef ref) async {
  // Use SimpleLocationService for straightforward permission handling
  final hasPermission = await SimpleLocationService.requestLocationPermission();

  if (hasPermission) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission granted!')),
      );
    }
    // Refresh the providers to get new location data
    ref.invalidate(locationProvider);
    ref.invalidate(currentAqiProvider);
    ref.invalidate(aqiForecastProvider);
  } else {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permission denied. Please enable it in settings.',
          ),
        ),
      );
    }
  }
}
