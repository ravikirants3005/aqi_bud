/// Firebase initialization and auth - Google, Phone, Email
library;

import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/user_models.dart';
import '../../firebase_options.dart';

bool _firebaseInitialized = false;
bool get isFirebaseReady => _firebaseInitialized;

/// Initialize Firebase. Safe to call multiple times.
/// Returns true if Firebase is ready, false if not configured or init failed.
Future<bool> initFirebase() async {
  if (_firebaseInitialized) return true;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _firebaseInitialized = true;
    return true;
  } catch (e) {
    return false;
  }
}

/// Sign in with Google
Future<FirebaseAuthResult> signInWithGoogle() async {
  if (!_firebaseInitialized) {
    final ok = await initFirebase();
    if (!ok) return FirebaseAuthResult.fail('Firebase not configured. Run: flutterfire configure');
  }

  try {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) return FirebaseAuthResult.fail('Sign in cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = firebase_auth.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCred = await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);
    final fbUser = userCred.user;
    if (fbUser == null) return FirebaseAuthResult.fail('Sign in failed');

    final profile = UserProfile(
      id: fbUser.uid,
      email: fbUser.email,
      displayName: fbUser.displayName ?? fbUser.email ?? 'User',
      photoUrl: fbUser.photoURL,
      healthSensitivity: HealthSensitivity.normal,
    );
    return FirebaseAuthResult.success(profile);
  } on firebase_auth.FirebaseAuthException catch (e) {
    return FirebaseAuthResult.fail(e.message ?? e.code);
  } catch (e) {
    return FirebaseAuthResult.fail(e.toString());
  }
}

/// Send OTP to phone number. Returns verificationId when SMS is sent.
Future<FirebaseAuthResult> sendPhoneOtp(String phoneNumber) async {
  if (!_firebaseInitialized) {
    final ok = await initFirebase();
    if (!ok) return FirebaseAuthResult.fail('Firebase not configured. Run: flutterfire configure');
  }

  try {
    final auth = firebase_auth.FirebaseAuth.instance;
    final fullNumber = phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';

    final completer = Completer<FirebaseAuthResult>();

    auth.verifyPhoneNumber(
      phoneNumber: fullNumber,
      verificationCompleted: (cred) async {
        if (!completer.isCompleted) {
          try {
            final userCred = await auth.signInWithCredential(cred);
            final fbUser = userCred.user;
            if (fbUser != null) {
              completer.complete(FirebaseAuthResult.success(UserProfile(
                id: fbUser.uid,
                phone: fbUser.phoneNumber,
                displayName: 'User',
                healthSensitivity: HealthSensitivity.normal,
              )));
            } else {
              completer.complete(FirebaseAuthResult.fail('Verification failed'));
            }
          } catch (e) {
            completer.complete(FirebaseAuthResult.fail(e.toString()));
          }
        }
      },
      verificationFailed: (e) {
        if (!completer.isCompleted) {
          completer.complete(FirebaseAuthResult.fail(e.message ?? e.code));
        }
      },
      codeSent: (verificationId, _) {
        if (!completer.isCompleted) {
          completer.complete(FirebaseAuthResult.needOtp(verificationId: verificationId));
        }
      },
      codeAutoRetrievalTimeout: (_) {},
    );

    return completer.future;
  } catch (e) {
    return FirebaseAuthResult.fail(e.toString());
  }
}

/// Verify phone OTP and sign in
Future<FirebaseAuthResult> verifyPhoneOtp({
  required String verificationId,
  required String otp,
}) async {
  if (!_firebaseInitialized) {
    final ok = await initFirebase();
    if (!ok) return FirebaseAuthResult.fail('Firebase not configured');
  }

  try {
    final credential = firebase_auth.PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: otp,
    );
    final userCred = await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);
    final fbUser = userCred.user;
    if (fbUser == null) return FirebaseAuthResult.fail('Verification failed');

    final profile = UserProfile(
      id: fbUser.uid,
      phone: fbUser.phoneNumber,
      displayName: 'User',
      healthSensitivity: HealthSensitivity.normal,
    );
    return FirebaseAuthResult.success(profile);
  } on firebase_auth.FirebaseAuthException catch (e) {
    return FirebaseAuthResult.fail(e.message ?? e.code);
  } catch (e) {
    return FirebaseAuthResult.fail(e.toString());
  }
}

/// Sign in with Firebase Email + Password
Future<FirebaseAuthResult> signInWithFirebaseEmail(String email, String password) async {
  if (!_firebaseInitialized) {
    final ok = await initFirebase();
    if (!ok) return FirebaseAuthResult.fail('Firebase not configured');
  }

  try {
    final userCred = await firebase_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final fbUser = userCred.user;
    if (fbUser == null) return FirebaseAuthResult.fail('Sign in failed');

    final profile = UserProfile(
      id: fbUser.uid,
      email: fbUser.email,
      displayName: fbUser.displayName ?? fbUser.email ?? 'User',
      photoUrl: fbUser.photoURL,
      healthSensitivity: HealthSensitivity.normal,
    );
    return FirebaseAuthResult.success(profile);
  } on firebase_auth.FirebaseAuthException catch (e) {
    return FirebaseAuthResult.fail(e.message ?? e.code);
  } catch (e) {
    return FirebaseAuthResult.fail(e.toString());
  }
}

/// Register with Firebase Email + Password
Future<FirebaseAuthResult> registerWithFirebaseEmail({
  required String email,
  required String password,
  required String displayName,
  required HealthSensitivity healthSensitivity,
}) async {
  if (!_firebaseInitialized) {
    final ok = await initFirebase();
    if (!ok) return FirebaseAuthResult.fail('Firebase not configured');
  }

  try {
    final userCred = await firebase_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final fbUser = userCred.user;
    if (fbUser == null) return FirebaseAuthResult.fail('Registration failed');

    await fbUser.updateDisplayName(displayName);

    final profile = UserProfile(
      id: fbUser.uid,
      email: fbUser.email,
      displayName: displayName,
      healthSensitivity: healthSensitivity,
    );
    return FirebaseAuthResult.success(profile);
  } on firebase_auth.FirebaseAuthException catch (e) {
    return FirebaseAuthResult.fail(e.message ?? e.code);
  } catch (e) {
    return FirebaseAuthResult.fail(e.toString());
  }
}

/// Sign out from Firebase
Future<void> signOutFirebase() async {
  await firebase_auth.FirebaseAuth.instance.signOut();
  await GoogleSignIn().signOut();
}

/// Get current Firebase user (for persistence)
firebase_auth.User? get currentFirebaseUser => firebase_auth.FirebaseAuth.instance.currentUser;

class FirebaseAuthResult {
  final UserProfile? profile;
  final String? error;
  final String? verificationId;

  FirebaseAuthResult.success(this.profile)
      : error = null,
        verificationId = null;

  FirebaseAuthResult.fail(this.error)
      : profile = null,
        verificationId = null;

  FirebaseAuthResult.needOtp({required this.verificationId})
      : profile = null,
        error = null;

  bool get isSuccess => profile != null;
  bool get needOtp => verificationId != null;
}
