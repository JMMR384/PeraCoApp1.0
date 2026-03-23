import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/core/router/app_router.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(children: [
            const Spacer(flex: 3),
            Image.asset('assets/images/logo_original.png', width: 280, fit: BoxFit.contain),
            const Spacer(flex: 2),
            ElevatedButton(onPressed: () => context.push(AppRoutes.login), child: const Text('Iniciar Sesion')),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: () => _showRoleSelector(context), child: const Text('Crear Cuenta')),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go(AppRoutes.clientHome),
              child: Text('Explorar sin cuenta', style: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.textSecondary)),
            ),
            const Spacer(flex: 1),
          ]),
        ),
      ),
    );
  }

  void _showRoleSelector(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: PeraCoColors.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            Text('Como quieres unirte?', style: PeraCoText.h2(context).copyWith(color: PeraCoColors.textPrimary)),
            const SizedBox(height: 8),
            Text('Selecciona tu rol en PeraCo', style: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.textSecondary)),
            const SizedBox(height: 24),
            _RoleCard(icon: Icons.shopping_bag_outlined, title: 'Quiero comprar', subtitle: 'Productos frescos del campo a tu mesa', color: PeraCoColors.primary,
              onTap: () { Navigator.pop(ctx); context.push(AppRoutes.signupClient); }),
            const SizedBox(height: 12),
            _RoleCard(icon: Icons.storefront_outlined, title: 'Quiero vender', subtitle: 'Vende como productor o comerciante', color: PeraCoColors.primaryLight,
              onTap: () { Navigator.pop(ctx); context.push(AppRoutes.signupFarmer); }),
            const SizedBox(height: 12),
            _RoleCard(icon: Icons.local_shipping_outlined, title: 'Quiero repartir', subtitle: 'Se un PeraGoger y genera ingresos', color: PeraCoColors.primaryDark,
              onTap: () { Navigator.pop(ctx); context.push(AppRoutes.signupDriver); }),
          ]),
        );
      },
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon; final String title; final String subtitle; final Color color; final VoidCallback onTap;
  const _RoleCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(14),
      child: Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: PeraCoColors.divider)),
        child: Row(children: [
          Container(width: 50, height: 50, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: color, size: 26)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: PeraCoText.bodyBold(context)),
            const SizedBox(height: 2),
            Text(subtitle, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
          ])),
          const Icon(Icons.chevron_right, color: PeraCoColors.textHint),
        ]),
      ),
    );
  }
}
