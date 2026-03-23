import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/app_constants.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/core/router/app_router.dart';
import 'package:peraco/features/auth/providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutBack));
    _animController.forward();
    _initialize();
  }

  @override
  void dispose() { _animController.dispose(); super.dispose(); }

  Future<void> _initialize() async {
    await Future.delayed(const Duration(seconds: AppConstants.splashDuration));
    if (!mounted) return;
    await ref.read(authProvider.notifier).checkCurrentSession();
    if (!mounted) return;
    final auth = ref.read(authProvider);
    if (auth.status == AuthStatus.authenticated) {
      switch (auth.role) {
        case UserRole.clienteB2C:
        case UserRole.clienteB2B:
          context.go(AppRoutes.clientHome);
        case UserRole.agricultor:
          context.go(AppRoutes.farmerDashboard);
        case UserRole.comerciante:
          context.go(AppRoutes.farmerDashboard);
        case UserRole.peragoger:
          context.go(AppRoutes.driverDeliveries);
        default:
          context.go(AppRoutes.welcome);
      }
    } else {
      context.go(AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
            stops: [0.0, 0.65, 1.0], colors: [Colors.white, Colors.white, Color(0xFFE8F5E9)]),
        ),
        child: FadeTransition(opacity: _fadeAnimation, child: ScaleTransition(scale: _scaleAnimation,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Image.asset('assets/images/logo_original.png', width: 280, fit: BoxFit.contain),
            const SizedBox(height: 50),
            const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(PeraCoColors.primary))),
          ]),
        )),
      ),
    );
  }
}
