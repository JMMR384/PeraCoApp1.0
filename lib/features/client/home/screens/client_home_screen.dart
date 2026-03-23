import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/core/router/app_router.dart';
import 'package:peraco/features/auth/providers/auth_provider.dart';
import 'package:peraco/features/client/cart/providers/cart_provider.dart';
import 'package:peraco/features/client/catalog/providers/products_provider.dart';

class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final name = auth.userName;
    final isGuest = auth.status != AuthStatus.authenticated;
    final productsAsync = ref.watch(productsProvider);

    String greeting = 'Hola!';
    final hour = DateTime.now().hour;
    if (hour < 12) { greeting = 'Buenos dias'; }
    else if (hour < 18) { greeting = 'Buenas tardes'; }
    else { greeting = 'Buenas noches'; }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: PeraCoColors.divider, width: 0.5))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(isGuest ? 'Hola! Bienvenido' : '$greeting, ${name ?? "Usuario"}',
                        style: PeraCoText.h2(context).copyWith(color: PeraCoColors.textPrimary)),
                    const SizedBox(height: 2),
                    Text(isGuest ? 'Explora nuestros productos frescos' : 'Que quieres pedir hoy?',
                        style: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.textSecondary)),
                  ])),
                  const SizedBox(width: 8),
                  Image.asset('assets/images/icono_peraco.png', height: 48, fit: BoxFit.contain),
                ]),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () => context.go(AppRoutes.clientCatalog),
                  child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(color: PeraCoColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
                      child: Row(children: [
                        const Icon(Icons.search, color: PeraCoColors.textHint, size: 20),
                        const SizedBox(width: 10),
                        Text('Buscar productos frescos...', style: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.textHint)),
                      ])),
                ),
              ]),
            ),

            const SizedBox(height: 16),

            // Categorias
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Categorias', style: PeraCoText.h3(context))),
            const SizedBox(height: 10),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _CategoryChip(icon: Icons.grass, label: 'Frutas', color: PeraCoColors.primary),
                  _CategoryChip(icon: Icons.eco, label: 'Verduras', color: PeraCoColors.primaryLight),
                  _CategoryChip(icon: Icons.set_meal, label: 'Carnes y\npescados', color: const Color(0xFFE54435)),
                  _CategoryChip(icon: Icons.spa, label: 'Hierbas y\nlegumbres', color: PeraCoColors.primaryDark),
                ])),

            const SizedBox(height: 20),

            // Banner
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(width: double.infinity, padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [PeraCoColors.primary, PeraCoColors.primaryDark]),
                        borderRadius: BorderRadius.circular(14)),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Del campo a tu mesa', style: PeraCoText.h3(context).copyWith(color: Colors.white)),
                        const SizedBox(height: 6),
                        Text('Productos 100% frescos\nentregados por PeraGogers',
                            style: PeraCoText.caption(context).copyWith(color: Colors.white70, height: 1.4)),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => context.go(AppRoutes.clientCatalog),
                          child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                              child: Text('Explorar', style: PeraCoText.label(context).copyWith(color: PeraCoColors.primary))),
                        ),
                      ])),
                      const SizedBox(width: 20),
                      Image.asset('assets/images/logo_blanco.png', width: 150, height: 150, fit: BoxFit.contain),
                    ]))),

            const SizedBox(height: 20),

            // Productos destacados
            Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Productos destacados', style: PeraCoText.h3(context)),
                  TextButton(onPressed: () => context.go(AppRoutes.clientCatalog),
                      child: Text('Ver todo', style: PeraCoText.label(context).copyWith(color: PeraCoColors.primary))),
                ])),
            const SizedBox(height: 6),

            // Grid con productos reales
            productsAsync.when(
              data: (products) {
                final featured = products.take(4).toList();
                return Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: LayoutBuilder(builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final crossAxisCount = width > 600 ? 3 : 2;
                      final cardWidth = (width - (10 * (crossAxisCount - 1))) / crossAxisCount;
                      final cardHeight = cardWidth * 1.15;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount, crossAxisSpacing: 10, mainAxisSpacing: 10,
                            childAspectRatio: cardWidth / cardHeight),
                        itemCount: featured.length,
                        itemBuilder: (ctx, i) => _ProductCard(product: featured[i]),
                      );
                    }));
              },
              loading: () => const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
              error: (_, __) => Padding(padding: const EdgeInsets.all(40),
                  child: Center(child: Text('Error cargando productos', style: PeraCoText.body(context).copyWith(color: PeraCoColors.textSecondary)))),
            ),
            const SizedBox(height: 20),
          ]),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final IconData icon; final String label; final Color color;
  const _CategoryChip({required this.icon, required this.label, required this.color});
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(width: 56, height: 56,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
          child: Icon(icon, color: color, size: 26)),
      const SizedBox(height: 6),
      Text(label, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textPrimary), textAlign: TextAlign.center),
    ]);
  }
}

class _ProductCard extends ConsumerWidget {
  final Product product;
  const _ProductCard({required this.product});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: PeraCoColors.divider, width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 5,
              child: Container(width: double.infinity,
                  decoration: BoxDecoration(color: PeraCoColors.greenPastel, borderRadius: const BorderRadius.vertical(top: Radius.circular(10))),
                  child: product.imagenUrl != null
                      ? ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(10)), child: Image.network(product.imagenUrl!, fit: BoxFit.cover))
                      : Center(child: Icon(Icons.eco, size: 32, color: PeraCoColors.primary.withOpacity(0.3))))),
          Expanded(flex: 4,
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(product.nombre, style: PeraCoText.label(context), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(product.displayFarm, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Flexible(child: Text(product.displayPrice, style: PeraCoText.price(context).copyWith(color: PeraCoColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      GestureDetector(
                          onTap: () {
                            ref.read(cartProvider.notifier).addProduct(product);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                content: Text('${product.nombre} agregado a la canasta'),
                                duration: const Duration(seconds: 1),
                                behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
                          },
                          child: Container(width: 24, height: 24, decoration: BoxDecoration(color: PeraCoColors.primary, borderRadius: BorderRadius.circular(6)),
                              child: const Icon(Icons.add, color: Colors.white, size: 14))),
                    ]),
                  ]))),
        ]));
  }
}