/// Auth - Email+Password, Phone OTP, Google. Uses Firebase when configured, else local.
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/firebase/firebase_service.dart';
import '../models/user_models.dart';

class AuthRepository {
  AuthRepository({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;
  static const _authKey = 'auth_user';
  static const _loggedInKey = 'auth_logged_in';

  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Register with email + password
  Future<AuthResult> registerWithEmail({
    required String email,
    required String password,
    required String displayName,
    required HealthSensitivity healthSensitivity,
  }) async {
    if (password.length < 6) {
      return AuthResult.failure('Password must be at least 6 characters');
    }

    final firebaseResult = await registerWithFirebaseEmail(
      email: email,
      password: password,
      displayName: displayName,
      healthSensitivity: healthSensitivity,
    );
    if (firebaseResult.isSuccess && firebaseResult.profile != null) {
      final profile = firebaseResult.profile!;
      await _persistProfile(profile);
      return AuthResult.success(profile);
    }

    final p = await _p;
    final existing = p.getString('auth_email_$email');
    if (existing != null) {
      return AuthResult.failure('An account with this email already exists');
    }

    final profile = UserProfile(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      email: email,
      displayName: displayName,
      healthSensitivity: healthSensitivity,
    );

    await p.setString('auth_email_$email', _hashPassword(password));
    await _saveProfileToStorage(profile);
    await p.setString(_authKey, _profileToJson(profile));
    await p.setBool(_loggedInKey, true);
    return AuthResult.success(profile);
  }

  /// Sign in with email + password
  Future<AuthResult> signInWithEmail(String email, String password) async {
    final firebaseResult = await signInWithFirebaseEmail(email, password);
    if (firebaseResult.isSuccess && firebaseResult.profile != null) {
      final profile = firebaseResult.profile!;
      await _persistProfile(profile);
      return AuthResult.success(profile);
    }

    final p = await _p;
    final storedHash = p.getString('auth_email_$email');
    if (storedHash == null) {
      return AuthResult.failure('No account found with this email');
    }
    if (storedHash != _hashPassword(password)) {
      return AuthResult.failure('Incorrect password');
    }

    final profile = await _loadProfileFromStorage('auth_profile_$email');
    if (profile == null) {
      return AuthResult.failure('Profile data corrupted');
    }
    await p.setString(_authKey, _profileToJson(profile));
    await p.setBool(_loggedInKey, true);
    await _persistProfile(profile);
    return AuthResult.success(profile);
  }

  /// Sign in with Google
  Future<AuthResult> signInWithGoogleAuth() async {
    final result = await signInWithGoogle();
    if (result.isSuccess && result.profile != null) {
      await _persistProfile(result.profile!);
      return AuthResult.success(result.profile!);
    }
    return AuthResult.failure(result.error ?? 'Google sign in failed');
  }

  /// Sign in with Phone OTP - step 1: send OTP. Returns FirebaseAuthResult (needOtp or success/fail).
  Future<FirebaseAuthResult> sendPhoneOtpAuth(String phoneNumber) async {
    return sendPhoneOtp(phoneNumber);
  }

  /// Sign in with Phone OTP - step 2: verify OTP
  Future<AuthResult> verifyPhoneOtpAuth({
    required String verificationId,
    required String otp,
  }) async {
    final result = await verifyPhoneOtp(
      verificationId: verificationId,
      otp: otp,
    );
    if (result.isSuccess && result.profile != null) {
      await _persistProfile(result.profile!);
      return AuthResult.success(result.profile!);
    }
    return AuthResult.failure(result.error ?? 'Verification failed');
  }

  /// Sign out
  Future<void> signOut() async {
    await signOutFirebase();
    final p = await _p;
    await p.setBool(_loggedInKey, false);
    await p.remove(_authKey);
  }

  /// Get current logged-in profile (or null if guest)
  Future<UserProfile?> getCurrentUser() async {
    final fbUser = currentFirebaseUser;
    if (fbUser != null) {
      final profile = UserProfile(
        id: fbUser.uid,
        email: fbUser.email,
        phone: fbUser.phoneNumber,
        displayName: fbUser.displayName ?? fbUser.email ?? 'User',
        photoUrl: fbUser.photoURL,
        healthSensitivity: HealthSensitivity.normal,
      );
      final existing = await _loadProfileFromStorage('auth_profile_${fbUser.email}');
      if (existing != null) {
        return existing.copyWith(
          id: fbUser.uid,
          email: fbUser.email,
          displayName: fbUser.displayName ?? existing.displayName,
          photoUrl: fbUser.photoURL ?? existing.photoUrl,
        );
      }
      await _persistProfile(profile);
      return profile;
    }
    final p = await _p;
    if (p.getBool(_loggedInKey) != true) return null;
    return _loadProfileFromStorage(_authKey);
  }

  Future<void> _persistProfile(UserProfile profile) async {
    final p = await _p;
    await p.setString(_authKey, _profileToJson(profile));
    if (profile.email != null) {
      await p.setString('auth_profile_${profile.email}', _profileToJson(profile));
    }
    await p.setBool(_loggedInKey, true);
  }

  String _profileToJson(UserProfile profile) {
    final json = {
      'id': profile.id,
      'email': profile.email,
      'phone': profile.phone,
      'displayName': profile.displayName,
      'photoUrl': profile.photoUrl,
      'healthSensitivity': profile.healthSensitivity.name,
      'ageGroup': profile.ageGroup,
      'savedLocations': profile.savedLocations
          .map((l) => {
                'id': l.id,
                'name': l.name,
                'lat': l.lat,
                'lng': l.lng,
                'lastAqi': l.lastAqi,
                'lastUpdated': l.lastUpdated?.toIso8601String(),
              })
          .toList(),
      'notificationPrefs': {
        'highAqiAlerts': profile.notificationPrefs.highAqiAlerts,
        'dailyExposureSummary': profile.notificationPrefs.dailyExposureSummary,
        'weeklyInsights': profile.notificationPrefs.weeklyInsights,
        'tipOfDay': profile.notificationPrefs.tipOfDay,
      },
    };
    return jsonEncode(json);
  }

  Future<void> _saveProfileToStorage(UserProfile profile) async {
    final p = await _p;
    final key = profile.email != null ? 'auth_profile_${profile.email}' : _authKey;
    await p.setString(key, _profileToJson(profile));
  }

  Future<UserProfile?> _loadProfileFromStorage(String key) async {
    final p = await _p;
    final raw = p.getString(key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final sensRaw = json['healthSensitivity'] as String? ?? 'normal';
      final sens = HealthSensitivity.values
              .cast<HealthSensitivity?>()
              .firstWhere(
                (s) => s?.name == sensRaw,
                orElse: () => HealthSensitivity.normal,
              ) ??
          HealthSensitivity.normal;

      final locsRaw = json['savedLocations'] as List<dynamic>? ?? [];
      final locs = locsRaw.map((e) {
        final m = e as Map<String, dynamic>;
        return SavedLocation(
          id: m['id'] as String,
          name: m['name'] as String,
          lat: (m['lat'] as num).toDouble(),
          lng: (m['lng'] as num).toDouble(),
          lastAqi: m['lastAqi'] as int?,
          lastUpdated: m['lastUpdated'] != null
              ? DateTime.tryParse(m['lastUpdated'] as String)
              : null,
        );
      }).toList();

      final np = json['notificationPrefs'] as Map<String, dynamic>? ?? {};
      final prefs = NotificationPreferences(
        highAqiAlerts: np['highAqiAlerts'] as bool? ?? true,
        dailyExposureSummary: np['dailyExposureSummary'] as bool? ?? true,
        weeklyInsights: np['weeklyInsights'] as bool? ?? true,
        tipOfDay: np['tipOfDay'] as bool? ?? true,
      );

      return UserProfile(
        id: json['id'] as String? ?? 'user',
        email: json['email'] as String?,
        phone: json['phone'] as String?,
        displayName: json['displayName'] as String?,
        photoUrl: json['photoUrl'] as String?,
        healthSensitivity: sens,
        ageGroup: json['ageGroup'] as String?,
        savedLocations: locs,
        notificationPrefs: prefs,
      );
    } catch (_) {
      return null;
    }
  }

  /// Persist profile changes (sensitivity, notifications, locations)
  Future<void> updateProfile(UserProfile profile) async {
    if (profile.id == 'guest') return;
    final p = await _p;
    if (p.getBool(_loggedInKey) != true) return;
    await p.setString(_authKey, _profileToJson(profile));
    if (profile.email != null) {
      await p.setString('auth_profile_${profile.email}', _profileToJson(profile));
    }
  }

  /// Check if user is logged in (not guest)
  Future<bool> get isLoggedIn async {
    final p = await _p;
    return p.getBool(_loggedInKey) == true;
  }
}

class AuthResult {
  final UserProfile? profile;
  final String? error;

  AuthResult.success(this.profile) : error = null;
  AuthResult.failure(this.error) : profile = null;

  bool get isSuccess => profile != null;
}
