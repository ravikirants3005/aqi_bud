/// App providers - Riverpod
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/api/aqi_api.dart';
import '../../data/models/aqi_models.dart';
import '../../data/models/user_models.dart';
import '../../data/repositories/aqi_repository.dart';
import '../../data/repositories/education_repository.dart';
import '../../data/repositories/exposure_repository.dart';
import '../../data/repositories/health_tips_repository.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/suggestions_repository.dart';

final sharedPrefsProvider = FutureProvider<SharedPreferences>(
  (_) => SharedPreferences.getInstance(),
);

final aqiApiProvider = Provider<AqiApi>((_) => AqiApi());
final aqiRepoProvider = Provider<AqiRepository>((ref) {
  final prefs = ref.watch(sharedPrefsProvider).valueOrNull;
  return AqiRepository(api: ref.watch(aqiApiProvider), prefs: prefs);
});
final suggestionsRepoProvider = Provider<SuggestionsRepository>((_) => SuggestionsRepository());
final healthTipsRepoProvider = Provider<HealthTipsRepository>((_) => HealthTipsRepository());
final exposureRepoProvider = Provider<ExposureRepository>((ref) {
  final prefs = ref.watch(sharedPrefsProvider).valueOrNull;
  return ExposureRepository(prefs: prefs);
});
final educationRepoProvider = Provider<EducationRepository>((_) => EducationRepository());

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final prefs = ref.watch(sharedPrefsProvider).valueOrNull;
  return AuthRepository(prefs: prefs);
});

final locationProvider = FutureProvider<Position?>((_) async {
  final enabled = await Geolocator.isLocationServiceEnabled();
  if (!enabled) return null;
  final perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    final req = await Geolocator.requestPermission();
    if (req != LocationPermission.whileInUse && req != LocationPermission.always) return null;
  }
  return Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium));
});

final currentAqiProvider = FutureProvider<AqiData?>((ref) async {
  final pos = await ref.watch(locationProvider.future);
  if (pos == null) return null;
  final repo = ref.watch(aqiRepoProvider);
  return repo.getCurrentAqi(pos.latitude, pos.longitude);
});

final aqiTrendsProvider = FutureProvider<Map<String, List<AqiTrendDay>>>((ref) async {
  final pos = await ref.watch(locationProvider.future);
  if (pos == null) return {'week': [], 'month': []};
  final repo = ref.watch(aqiRepoProvider);
  return repo.getAqiTrends(pos.latitude, pos.longitude);
});

final userProfileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile?>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  return UserProfileNotifier(auth: auth);
});

class UserProfileNotifier extends StateNotifier<UserProfile?> {
  UserProfileNotifier({required AuthRepository auth}) : _auth = auth, super(_defaultGuest);

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
}
