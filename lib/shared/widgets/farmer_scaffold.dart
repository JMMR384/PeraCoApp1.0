import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/router/app_router.dart';
import 'package:peraco/features/auth/providers/auth_provider.dart';

class FarmerScaffold extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const FarmerScaffold({super.key, required this.navigationShell});

  @override
  ConsumerState<FarmerScaffold> createState() => _FarmerScaffoldState();
}

class _FarmerScaffoldState extends ConsumerState<FarmerScaffold> {
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
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined),   activeIcon: Icon(Icons.dashboard),   label: 'Dashboard'),
                BottomNavigationBarItem(icon: Icon(Icons.inventory_2_outlined), activeIcon: Icon(Icons.inventory_2), label: 'Productos'),
                BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Pedidos'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline),       activeIcon: Icon(Icons.person),      label: 'Perfil'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
