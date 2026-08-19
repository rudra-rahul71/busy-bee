import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:dynamic_backend_bridge/dynamic_backend_bridge.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward().then((_) {
      if (mounted) {
        try {
          final authRepo = ref.read(authRepositoryProvider);
          final UserEntity? user = authRepo.currentUser;
          if (user != null) {
            context.go('/home');
          } else {
            context.go('/auth/sign-in');
          }
        } catch (_) {
          // If the backend isn't initialized, the router will catch the redirect and send to wizard
          context.go('/auth/sign-in');
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Icon(
            Icons.hive_outlined,
            size: 150,
            color: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }
}
