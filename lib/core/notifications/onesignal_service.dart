library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

class OneSignalService {
  OneSignalService._();

  static final OneSignalService instance = OneSignalService._();

  bool _initialized = false;
  String? _currentExternalId;

  Future<void> Function(String? subscriptionId)? onPushSubscriptionChanged;

  Future<void> initialize(String appId) async {
    final trimmedAppId = appId.trim();
    if (_initialized || trimmedAppId.isEmpty) return;

    await OneSignal.initialize(trimmedAppId);

    if (!OneSignal.Notifications.permission) {
      await OneSignal.Notifications.requestPermission(true);
    }

    _attachObservers();

    debugPrint("OneSignal initialized");
    _initialized = true;
  }

  Future<void> syncUser(String externalId) async {
    if (!_initialized) return;

    final trimmedExternalId = externalId.trim();

    if (trimmedExternalId.isEmpty ||
        trimmedExternalId == _currentExternalId) {
      return;
    }

    await OneSignal.login(trimmedExternalId);

    debugPrint("OneSignal login: $trimmedExternalId");

    _currentExternalId = trimmedExternalId;
  }

  Future<void> logout() async {
    if (!_initialized) return;

    await OneSignal.logout();

    debugPrint("OneSignal logout");

    _currentExternalId = null;
  }

  String? get pushSubscriptionId =>
      OneSignal.User.pushSubscription.id;

  bool get hasPermission => OneSignal.Notifications.permission;

  String? get currentExternalId => _currentExternalId;

  void _attachObservers() {
    OneSignal.User.pushSubscription.addObserver((state) {
      final subscriptionId = state.current.id;

      if (subscriptionId == null) return;

      debugPrint(
        'OneSignal subscription changed: $subscriptionId',
      );

      unawaited(
        onPushSubscriptionChanged?.call(subscriptionId),
      );
    });
  }
}