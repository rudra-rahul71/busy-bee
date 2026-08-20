import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dynamic_backend_bridge/dynamic_backend_bridge.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'features/account/presentation/pages/account.dart';
import 'features/auth/presentation/pages/sign_in.dart';
import 'features/auth/presentation/pages/hosting_wizard_page.dart';
import 'features/home/presentation/pages/home.dart';
import 'core/widgets/app_shell.dart';
import 'core/config/app_environment.dart';

final configServiceProvider = Provider((ref) => ConfigService());

class AppConfigNotifier extends Notifier<AppConfig?> {
  @override
  AppConfig? build() => null;
  void setConfig(AppConfig? config) => state = config;
}

final appConfigProvider = NotifierProvider<AppConfigNotifier, AppConfig?>(
  AppConfigNotifier.new,
);

Future<void> initializeBackend(
  AppConfig config, {
  ProviderContainer? container,
  WidgetRef? ref,
}) async {
  await DynamicBackendBridge.initialize(
    config: config,
    container: container,
    ref: ref,
    defaultSupabaseUrl: AppEnvironment.defaultSupabaseUrl,
    defaultSupabaseAnonKey: AppEnvironment.defaultSupabaseAnonKey,
    dbSchema: 'busy_bee',
    defaultNotificationChannelId: 'busy_bee',
    defaultNotificationChannelName: 'Busy Bee Notifications',
    defaultNotificationChannelDesc: 'Notifications for Busy Bee',
    enableRemoteNotifications: true,
    appId: 'busy_bee',
  );
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try to init firebase, ignore if missing config
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  final configService = ConfigService();
  final savedConfig = await configService.getSavedConfig();

  final container = ProviderContainer(
    overrides: [configServiceProvider.overrideWithValue(configService)],
  );

  if (savedConfig != null) {
    try {
      await initializeBackend(savedConfig, container: container);
    } catch (e) {
      debugPrint('Error initializing saved backend config: $e');
    }
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: MyApp(initialConfig: savedConfig),
    ),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: AppBannerService.navigatorKey,
    initialLocation: '/',
    redirect: (BuildContext context, GoRouterState state) {
      bool hasConfig = false;
      try {
        ref.read(authRepositoryProvider);
        hasConfig = true;
      } catch (_) {}

      final String goingTo = state.fullPath ?? '/';

      if (!hasConfig) {
        if (goingTo != '/hosting-wizard') {
          return '/hosting-wizard';
        }
        return null;
      }

      final auth = ref.read(authRepositoryProvider);
      final UserEntity? user = auth.currentUser;
      final bool loggedIn = user != null;

      if (loggedIn) {
        if (goingTo == '/' || goingTo == '/auth/sign-in' || goingTo == '/hosting-wizard') {
          return '/home';
        }
        return null;
      } else {
        if (goingTo != '/auth/sign-in' && goingTo != '/hosting-wizard') {
          return '/auth/sign-in';
        }
        return null;
      }
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/hosting-wizard',
        builder: (context, state) =>
            HostingWizardPage(configService: ref.read(configServiceProvider)),
      ),
      GoRoute(
        path: '/auth/sign-in',
        builder: (context, state) => const SignInPage(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return NavigatorScafold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/account',
                builder: (context, state) => const AccountPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class MyApp extends ConsumerStatefulWidget {
  final AppConfig? initialConfig;
  const MyApp({super.key, this.initialConfig});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialConfig != null) {
        ref.read(appConfigProvider.notifier).setConfig(widget.initialConfig);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.build(
      primarySeed: const Color(0xFFD4AF37),
      primary: const Color(0xFFD4AF37),
      onPrimary: Colors.black,
      secondary: const Color(0xFFE5A93C),
      tertiary: const Color(0xFF26A69A),
      onTertiary: Colors.black,
      error: const Color(0xFFEF5350),
      onError: Colors.white,
      surface: const Color(0xFF1E1E1E),
      onSurface: Colors.white,
      scaffoldBackgroundColor: const Color(0xFF121212),
    );

    // Watch auth changes so the router can rebuild its redirect logic
    try {
      ref.watch(currentUserProvider);
    } catch (_) {}

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Busy Bee',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: router,
    );
  }
}
