library;

import 'dart:convert';

import 'package:flutter/services.dart';

class RuntimeConfig {
  const RuntimeConfig({
    required this.aqiProvider,
    required this.aqiApiKey,
    required this.backendBaseUrl,
    required this.onesignalAppId,
  });

  final String aqiProvider;
  final String aqiApiKey;
  final String backendBaseUrl;
  final String onesignalAppId;

  static const RuntimeConfig fallback = RuntimeConfig(
    aqiProvider: String.fromEnvironment(
      'AQI_API_PROVIDER',
      defaultValue: 'open-meteo',
    ),
    aqiApiKey: String.fromEnvironment('AQI_API_KEY'),
    backendBaseUrl: String.fromEnvironment(
      'BACKEND_BASE_URL',
      defaultValue: 'http://localhost:8000',
    ),
    onesignalAppId: String.fromEnvironment('ONESIGNAL_APP_ID'),
  );

  static Future<RuntimeConfig> load() async {
    try {
      String raw;
      try {
        raw = await rootBundle.loadString('assets/config/runtime_config.json');
      } catch (_) {
        raw = await rootBundle.loadString('assets/runtime_config.json');
      }
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return fallback;

      return RuntimeConfig(
        aqiProvider:
            (decoded['aqiProvider'] as String?)?.trim().isNotEmpty == true
            ? (decoded['aqiProvider'] as String).trim()
            : fallback.aqiProvider,
        aqiApiKey:
            (decoded['aqiApiKey'] as String?)?.trim() ?? fallback.aqiApiKey,
        backendBaseUrl:
            (decoded['backendBaseUrl'] as String?)?.trim().isNotEmpty == true
            ? (decoded['backendBaseUrl'] as String).trim()
            : fallback.backendBaseUrl,
        onesignalAppId:
            (decoded['onesignalAppId'] as String?)?.trim().isNotEmpty == true
            ? (decoded['onesignalAppId'] as String).trim()
            : fallback.onesignalAppId,
      );
    } catch (_) {
      return fallback;
    }
  }
}
