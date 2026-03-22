library;

import 'dart:convert';

import 'package:flutter/services.dart';

class RuntimeConfig {
  const RuntimeConfig({
    required this.aqiProvider,
    required this.aqiApiKey,
  });

  final String aqiProvider;
  final String aqiApiKey;

  static const RuntimeConfig fallback = RuntimeConfig(
    aqiProvider: String.fromEnvironment(
      'AQI_API_PROVIDER',
      defaultValue: 'open-meteo',
    ),
    aqiApiKey: String.fromEnvironment('AQI_API_KEY'),
  );

  static Future<RuntimeConfig> load() async {
    try {
      final raw = await rootBundle.loadString('assets/config/runtime_config.json');
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return fallback;

      return RuntimeConfig(
        aqiProvider: (decoded['aqiProvider'] as String?)?.trim().isNotEmpty == true
            ? (decoded['aqiProvider'] as String).trim()
            : fallback.aqiProvider,
        aqiApiKey: (decoded['aqiApiKey'] as String?)?.trim() ?? fallback.aqiApiKey,
      );
    } catch (_) {
      return fallback;
    }
  }
}
