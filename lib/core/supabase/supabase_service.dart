/// Supabase initialization and auth - Email/Password only
library;

import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/user_models.dart';
import '../../supabase_options.dart';

bool _supabaseInitialized = false;
bool get isSupabaseReady => _supabaseInitialized;

/// Initialize Supabase. Safe to call multiple times.
/// Returns true if Supabase is ready, false if not configured or init failed.
Future<bool> initSupabase() async {
  if (_supabaseInitialized) return true;
  try {
    await Supabase.initialize(
      url: SupabaseOptions.currentPlatform.url,
      anonKey: SupabaseOptions.currentPlatform.anonKey,
    );
    _supabaseInitialized = true;
    return true;
  } catch (e) {
    return false;
  }
}

/// Sign up with email and password
Future<SupabaseAuthResult> signUpWithEmail(
  String email,
  String password, {
  String? displayName,
}) async {
  if (!_supabaseInitialized) {
    final ok = await initSupabase();
    if (!ok)
      return SupabaseAuthResult.fail(
        'Supabase not configured. Add your Supabase credentials to supabase_options.dart',
      );
  }

  try {
    final response = await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: displayName != null ? {'display_name': displayName} : null,
    );

    if (response.user != null) {
      return SupabaseAuthResult.success(user: response.user!, isNewUser: true);
    } else {
      return SupabaseAuthResult.fail('Sign up failed');
    }
  } catch (e) {
    return SupabaseAuthResult.fail(e.toString());
  }
}

/// Sign in with email and password
Future<SupabaseAuthResult> signInWithEmail(
  String email,
  String password,
) async {
  if (!_supabaseInitialized) {
    final ok = await initSupabase();
    if (!ok)
      return SupabaseAuthResult.fail(
        'Supabase not configured. Add your Supabase credentials to supabase_options.dart',
      );
  }

  try {
    final response = await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    final user = response.user;
    if (user == null) return SupabaseAuthResult.fail('Sign in failed');

    return SupabaseAuthResult.success(user: user, isNewUser: false);
  } catch (e) {
    return SupabaseAuthResult.fail(e.toString());
  }
}

/// Sign out from Supabase
Future<void> signOutSupabase() async {
  await Supabase.instance.client.auth.signOut();
}

/// Get current Supabase user (for persistence)
User? get currentSupabaseUser => Supabase.instance.client.auth.currentUser;

class SupabaseAuthResult {
  final UserProfile? profile;
  final String? error;
  final String? verificationId;

  SupabaseAuthResult.success(this.profile)
    : error = null,
      verificationId = null;

  SupabaseAuthResult.fail(this.error) : profile = null, verificationId = null;

  SupabaseAuthResult.needOtp({required this.verificationId})
    : profile = null,
      error = null;

  bool get isSuccess => profile != null;
  bool get needOtp => verificationId != null;
}
