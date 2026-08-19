import 'package:flutter/material.dart';
import 'package:dynamic_backend_bridge/dynamic_backend_bridge.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../main.dart';

class HostingWizardPage extends ConsumerWidget {
  final ConfigService configService;

  const HostingWizardPage({super.key, required this.configService});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: HostingWizard(
          configService: configService,
          onValidate: (AppConfig config) async {
            try {
              final tempContainer = ProviderContainer();
              await initializeBackend(config, container: tempContainer);
              final auth = tempContainer.read(authRepositoryProvider);
              final result = await auth.validateConnection();
              tempContainer.dispose();
              return result;
            } catch (e) {
              return e.toString();
            }
          },
          onComplete: (AppConfig config) async {
            await initializeBackend(config, ref: ref);
            ref.read(appConfigProvider.notifier).setConfig(config);
            if (context.mounted) {
              context.go('/auth/sign-in');
            }
          },
        ),
      ),
    );
  }
}
