/// App providers - Riverpod
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/constants/app_constants.dart';
import '../../main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/api/aqi_api.dart';
import '../../data/models/aqi_models.dart';
import '../../data/models/exposure_models.dart';
import '../../data/models/user_models.dart';
import '../../data/repositories/aqi_repository.dart';
import '../../data/repositories/education_repository.dart';
import '../../data/repositories/exposure_repository.dart';
import '../../data/repositories/health_tips_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/suggestions_repository.dart';
import '../../data/repositories/notification_repository.dart';
import '../../data/repositories/backend_repository.dart';

final sharedPrefsProvider = FutureProvider<SharedPreferences>(
  (_) => SharedPreferences.getInstance(),
);

final aqiApiProvider = Provider<AqiApi>((ref) {
  final config = ref.watch(runtimeConfigProvider);
  return AqiApi(config: config);
});
final aqiRepoProvider = Provider<AqiRepository>((ref) {
  final prefs = ref.watch(sharedPrefsProvider).valueOrNull;
  return AqiRepository(api: ref.watch(aqiApiProvider), prefs: prefs);
});
final suggestionsRepoProvider = Provider<SuggestionsRepository>(
  (_) => SuggestionsRepository(),
);
final healthTipsRepoProvider = Provider<HealthTipsRepository>(
  (_) => HealthTipsRepository(),
);
final exposureRepoProvider = Provider<ExposureRepository>((ref) {
  final prefs = ref.watch(sharedPrefsProvider).valueOrNull;
  return ExposureRepository(prefs: prefs);
});
final educationRepoProvider = Provider<EducationRepository>(
  (_) => EducationRepository(),
);

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final prefs = ref.watch(sharedPrefsProvider).valueOrNull;
  return AuthRepository(prefs: prefs);
});

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final prefs = ref.watch(sharedPrefsProvider).valueOrNull;
  return NotificationRepository(prefs: prefs);
});

final backendRepositoryProvider = Provider<BackendRepository>((ref) {
  final config = ref.watch(runtimeConfigProvider);
  return BackendRepository(config: config);
});

Future<bool> ensureLocationPermission({bool requestIfNeeded = false}) async {
  final enabled = await Geolocator.isLocationServiceEnabled();
  if (!enabled) return false;

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied && requestIfNeeded) {
    permission = await Geolocator.requestPermission();
  }

  return permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always;
}

final locationProvider = FutureProvider<Position?>((_) async {
  final hasPermission = await ensureLocationPermission();
  if (!hasPermission) return null;

  Position? lastKnown;
  try {
    lastKnown = await Geolocator.getLastKnownPosition();
  } catch (_) {
    lastKnown = null;
  }

  try {
    final current = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
    if (lastKnown == null) return current;
    return current.accuracy <= lastKnown.accuracy ? current : lastKnown;
  } catch (_) {
    return lastKnown;
  }
});

final currentAqiProvider = FutureProvider<AqiData?>((ref) async {
  final pos = await ref.watch(locationProvider.future);
  if (pos == null) return null;
  final repo = ref.watch(aqiRepoProvider);
  return repo.getCurrentAqi(pos.latitude, pos.longitude);
});

final aqiHourlyHistoryProvider = FutureProvider<List<AqiHourlyPoint>>((
  ref,
) async {
  final pos = await ref.watch(locationProvider.future);
  if (pos == null) return const <AqiHourlyPoint>[];
  final repo = ref.watch(aqiRepoProvider);
  return repo.getAqiHistory(pos.latitude, pos.longitude);
});

final aqiTrendsProvider = FutureProvider<Map<String, List<AqiTrendDay>>>((
  ref,
) async {
  final history = await ref.watch(aqiHourlyHistoryProvider.future);
  if (history.isEmpty) return {'week': [], 'month': []};
  final repo = ref.watch(aqiRepoProvider);
  return repo.buildTrendsFromHistory(history);
});

final exposureDashboardProvider = FutureProvider<ExposureDashboardData?>((
  ref,
) async {
  final currentAqi = await ref.watch(currentAqiProvider.future);
  if (currentAqi == null) return null;

  final trends = await ref.watch(aqiTrendsProvider.future);
  final profile = ref.watch(userProfileProvider);
  final savedLocations = profile?.savedLocations ?? const <SavedLocation>[];
  final sensitivity = profile?.healthSensitivity ?? HealthSensitivity.normal;
  final aqiRepo = ref.watch(aqiRepoProvider);
  final exposureRepo = ref.watch(exposureRepoProvider);

  final locationCurrentAqiEntries = await Future.wait(
    savedLocations.map((location) async {
      final data = await aqiRepo.getCurrentAqi(location.lat, location.lng);
      return MapEntry(location.id, data);
    }),
  );
  final locationTrendEntries = await Future.wait(
    savedLocations.map((location) async {
      final data = await aqiRepo.getAqiTrends(location.lat, location.lng);
      return MapEntry(location.id, data['week'] ?? const <AqiTrendDay>[]);
    }),
  );

  return exposureRepo.buildDashboard(
    currentAqi: currentAqi,
    weeklyTrend: trends['week'] ?? const <AqiTrendDay>[],
    monthlyTrend: trends['month'] ?? const <AqiTrendDay>[],
    savedLocations: savedLocations,
    healthSensitivity: sensitivity,
    locationCurrentAqi: {
      for (final entry in locationCurrentAqiEntries) entry.key: entry.value,
    },
    locationTrends: {
      for (final entry in locationTrendEntries) entry.key: entry.value,
    },
  );
});

final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile?>((ref) {
      final auth = ref.watch(authRepositoryProvider);
      return UserProfileNotifier(auth: auth);
    });

class UserProfileNotifier extends StateNotifier<UserProfile?> {
  UserProfileNotifier({required AuthRepository auth})
    : _auth = auth,
      super(_defaultGuest);

  final AuthRepository _auth;
  static final _defaultGuest = UserProfile(
    id: 'guest',
    displayName: 'Guest',
    healthSensitivity: HealthSensitivity.normal,
  );

  void setProfile(UserProfile p) {
    state = p;
    if (p.id != 'guest') _auth.updateProfile(p);
  }

  void clear() {
    state = _defaultGuest;
  }

  Future<void> signOut() async {
    await _auth.signOut();
    state = _defaultGuest;
  }

  void updateSensitivity(HealthSensitivity s) {
    final next = (state ?? _defaultGuest).copyWith(healthSensitivity: s);
    state = next;
    if (next.id != 'guest') _auth.updateProfile(next);
  }

  void updateSavedLocations(List<SavedLocation> locs) {
    final next = (state ?? _defaultGuest).copyWith(savedLocations: locs);
    state = next;
    if (next.id != 'guest') _auth.updateProfile(next);
  }

  void updateNotificationPrefs(NotificationPreferences p) {
    final next = (state ?? _defaultGuest).copyWith(notificationPrefs: p);
    state = next;
    if (next.id != 'guest') _auth.updateProfile(next);
  }

  Future<void> initializeNotifications() async {
    final notificationRepo = ref.read(notificationRepositoryProvider);
    await notificationRepo.initialize();
  }

  Future<void> updateNotificationPreferences(
    NotificationPreferences prefs,
  ) async {
    final notificationRepo = ref.read(notificationRepositoryProvider);
    await notificationRepo.updatePreferences(prefs);
    updateNotificationPrefs(prefs);
  }

  Future<void> initializeBackendProfile() async {
    final backendRepo = ref.read(backendRepositoryProvider);
    await backendRepo.initializeUserProfile();
  }
}
