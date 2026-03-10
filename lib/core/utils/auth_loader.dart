/// Loads saved auth on app start
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/providers/app_providers.dart';

class AuthLoader extends ConsumerStatefulWidget {
  final Widget child;

  const AuthLoader({super.key, required this.child});

  @override
  ConsumerState<AuthLoader> createState() => _AuthLoaderState();
}

class _AuthLoaderState extends ConsumerState<AuthLoader> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAuth());
  }

  Future<void> _loadAuth() async {
    final auth = ref.read(authRepositoryProvider);
    final user = await auth.getCurrentUser();
    if (user != null && mounted) {
      ref.read(userProfileProvider.notifier).setProfile(user);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
