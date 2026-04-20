import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/router/app_router.dart';
import 'package:peraco/features/auth/providers/auth_provider.dart';

class ClientScaffold extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const ClientScaffold({super.key, required this.navigationShell});

  @override
  ConsumerState<ClientScaffold> createState() => _ClientScaffoldState();
}

class _ClientScaffoldState extends ConsumerState<ClientScaffold> {
  @override
  void initState() {
    super.initState();
    // Escucha cambios de auth: si la sesión expira mientras el cliente navega,
    // redirige al welcome sin acción del usuario.
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
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
        ),
        child: SafeArea(
          child: SizedBox(
            height: 72,
            child: BottomNavigationBar(
              currentIndex: widget.navigationShell.currentIndex,
              onTap: (i) => widget.navigationShell.goBranch(i, initialLocation: i == widget.navigationShell.currentIndex),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_outlined),             activeIcon: Icon(Icons.home),             label: 'Inicio'),
                BottomNavigationBarItem(icon: Icon(Icons.search_outlined),           activeIcon: Icon(Icons.search),           label: 'Catalogo'),
                BottomNavigationBarItem(icon: Icon(Icons.shopping_basket_outlined),  activeIcon: Icon(Icons.shopping_basket),  label: 'Canasta'),
                BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined),     activeIcon: Icon(Icons.receipt_long),     label: 'Pedidos'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline),            activeIcon: Icon(Icons.person),           label: 'Perfil'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
