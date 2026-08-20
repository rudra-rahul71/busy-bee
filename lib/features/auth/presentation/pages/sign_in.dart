import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dynamic_backend_bridge/dynamic_backend_bridge.dart';
import '../../../../main.dart';

class SignInPage extends ConsumerWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: DynamicSignInPage(
          appName: 'BUSY BEE',
          appIcon: Icon(
            Icons.hive_outlined,
            size: 120,
            color: theme.colorScheme.primary,
          ),
          onSignInSuccess: () {
            context.go('/home'); // Routing directly to home
          },
          onResetBackend: () async {
            final router = GoRouter.of(context);
            final configService = ref.read(configServiceProvider);
            await configService.clearConfig();
            ref.read(appConfigProvider.notifier).setConfig(null);
            // The router redirect will handle kicking us back to /hosting-wizard
            router.go('/hosting-wizard');
          },
        ),
      ),
    );
  }
}
