import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/router/app_router.dart';
import 'package:peraco/features/auth/providers/auth_provider.dart';

class DriverScaffold extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const DriverScaffold({super.key, required this.navigationShell});

  @override
  ConsumerState<DriverScaffold> createState() => _DriverScaffoldState();
}

class _DriverScaffoldState extends ConsumerState<DriverScaffold> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.unauthenticated && mounted) {
        context.go(AppRoutes.welcome);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: PeraCoColors.surface,
          boxShadow: [BoxShadow(color: PeraCoColors.shadow, blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 72,
            child: BottomNavigationBar(
              currentIndex: widget.navigationShell.currentIndex,
              onTap: (i) => widget.navigationShell.goBranch(i, initialLocation: i == widget.navigationShell.currentIndex),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.local_shipping_outlined), activeIcon: Icon(Icons.local_shipping), label: 'Entregas'),
                BottomNavigationBarItem(icon: Icon(Icons.map_outlined),            activeIcon: Icon(Icons.map),            label: 'Mapa'),
                BottomNavigationBarItem(icon: Icon(Icons.history_outlined),        activeIcon: Icon(Icons.history),        label: 'Historial'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline),          activeIcon: Icon(Icons.person),         label: 'Perfil'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
