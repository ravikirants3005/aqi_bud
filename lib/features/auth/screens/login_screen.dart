/// Login - Email+Password, Phone OTP, Google
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/user_models.dart';
import '../../../domain/providers/app_providers.dart';
import '../widgets/phone_otp_dialog.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginWithEmail() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = ref.read(authRepositoryProvider);
    final result = await auth.signInWithEmail(
      _emailCtrl.text.trim(),
      _passCtrl.text,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.isSuccess && result.profile != null) {
      ref.read(userProfileProvider.notifier).setProfile(result.profile!);
      context.go('/');
    } else {
      setState(() => _error = result.error ?? 'Login failed');
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final auth = ref.read(authRepositoryProvider);
    final result = await auth.signInWithGoogleAuth();
    if (!mounted) return;
    setState(() => _loading = false);
    if (result.isSuccess && result.profile != null) {
      ref.read(userProfileProvider.notifier).setProfile(result.profile!);
      context.go('/');
    } else {
      setState(() => _error = result.error ?? 'Google sign in failed');
    }
  }

  Future<void> _loginWithPhone() async {
    final auth = ref.read(authRepositoryProvider);
    final phone = await showDialog<String>(
      context: context,
      builder: (ctx) => _PhoneInputDialog(),
    );
    if (phone == null || !mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final sendResult = await auth.sendPhoneOtpAuth(phone);
    if (!mounted) return;
    setState(() => _loading = false);
    if (sendResult.isSuccess && sendResult.profile != null) {
      ref.read(userProfileProvider.notifier).setProfile(sendResult.profile!);
      context.go('/');
      return;
    }
    if (sendResult.needOtp && sendResult.verificationId != null) {
      final vid = sendResult.verificationId!;
      final profile = await showDialog<UserProfile>(
        context: context,
        builder: (ctx) => PhoneOtpDialog(
          verificationId: vid,
          onVerify: (otp) async {
            final result = await auth.verifyPhoneOtpAuth(
              verificationId: vid,
              otp: otp,
            );
            return result.profile;
          },
        ),
      );
      if (profile != null && mounted) {
        ref.read(userProfileProvider.notifier).setProfile(profile);
        context.go('/');
      }
    } else {
      setState(() => _error = sendResult.error ?? 'Failed to send OTP');
    }
  }

  void _loginAsGuest() {
    ref.read(userProfileProvider.notifier).setProfile(
          const UserProfile(
            id: 'guest',
            displayName: 'Guest',
            healthSensitivity: HealthSensitivity.normal,
          ),
        );
    context.go('/');
  }

  void _register() => context.push('/register');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log in'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              enabled: !_loading,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passCtrl,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              obscureText: _obscure,
              enabled: !_loading,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loading ? null : _loginWithEmail,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Log in'),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loading ? null : _loginWithGoogle,
              icon: const Icon(Icons.g_mobiledata, size: 24),
              label: const Text('Continue with Google'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loading ? null : _loginWithPhone,
              icon: const Icon(Icons.phone),
              label: const Text('Sign in with Phone'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: _loading ? null : _register,
              child: const Text('Create account'),
            ),
            const SizedBox(height: 24),
            const Divider(),
            TextButton(
              onPressed: _loading ? null : _loginAsGuest,
              child: const Text('Continue as Guest'),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhoneInputDialog extends StatefulWidget {
  @override
  State<_PhoneInputDialog> createState() => _PhoneInputDialogState();
}

class _PhoneInputDialogState extends State<_PhoneInputDialog> {
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter phone number'),
      content: TextField(
        controller: _phoneCtrl,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          labelText: 'Phone (e.g. +919876543210)',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.phone),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final phone = _phoneCtrl.text.trim();
            if (phone.isNotEmpty) Navigator.pop(context, phone);
          },
          child: const Text('Send OTP'),
        ),
      ],
    );
  }
}
