/// Phone OTP verification dialog
library;

import 'package:flutter/material.dart';

import '../../../data/models/user_models.dart';

class PhoneOtpDialog extends StatefulWidget {
  final String verificationId;
  final Future<UserProfile?> Function(String otp) onVerify;

  const PhoneOtpDialog({
    super.key,
    required this.verificationId,
    required this.onVerify,
  });

  @override
  State<PhoneOtpDialog> createState() => _PhoneOtpDialogState();
}

class _PhoneOtpDialogState extends State<PhoneOtpDialog> {
  final _otpCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpCtrl.text.trim();
    if (otp.length < 6) {
      setState(() => _error = 'Enter the 6-digit code');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final profile = await widget.onVerify(otp);
    if (!mounted) return;
    setState(() => _loading = false);
    if (profile != null) {
      Navigator.pop(context, profile);
    } else {
      setState(() => _error = 'Invalid code');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Enter verification code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('We sent a 6-digit code to your phone. Enter it below.'),
          const SizedBox(height: 16),
          TextField(
            controller: _otpCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: InputDecoration(
              labelText: 'OTP',
              border: const OutlineInputBorder(),
              errorText: _error,
            ),
            enabled: !_loading,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _verify,
          child: _loading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verify'),
        ),
      ],
    );
  }
}
