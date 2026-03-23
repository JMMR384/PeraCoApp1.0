import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/core/router/app_router.dart';
import 'package:peraco/features/client/cart/providers/cart_provider.dart';

class ClientCartScreen extends ConsumerWidget {
  const ClientCartScreen({super.key});

  String _formatPrice(double price) {
    return 'COP ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(cartProvider);
    final cart = ref.read(cartProvider.notifier);

    if (items.isEmpty) return _buildEmptyCart(context);

    return Scaffold(
      backgroundColor: PeraCoColors.surfaceVariant,
      appBar: AppBar(
        title: Row(children: [
          const Icon(Icons.shopping_basket, color: PeraCoColors.primary),
          const SizedBox(width: 8),
          const Text('Mi Canasta'),
          const SizedBox(width: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: PeraCoColors.greenPastel, borderRadius: BorderRadius.circular(12)),
              child: Text('${cart.totalItems}', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.primary, fontWeight: FontWeight.bold))),
        ]),
        actions: [
          TextButton(onPressed: () => ref.read(cartProvider.notifier).clear(),
              child: Text('Vaciar', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.error))),
        ],
      ),
      body: Column(children: [
        Expanded(child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Dismissible(
              key: ValueKey(item.product.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) {
                ref.read(cartProvider.notifier).removeProduct(item.product.id);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('${item.product.nombre} eliminado'),
                    behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
              },
              background: Container(margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(color: PeraCoColors.error, borderRadius: BorderRadius.circular(14)),
                  alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete_outline, color: Colors.white, size: 28)),
              child: Container(
                  margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
                  child: Row(children: [
                    Container(width: 68, height: 68,
                        decoration: BoxDecoration(color: PeraCoColors.greenPastel, borderRadius: BorderRadius.circular(12)),
                        child: item.product.imagenUrl != null
                            ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(item.product.imagenUrl!, fit: BoxFit.cover))
                            : Icon(Icons.eco, color: PeraCoColors.primary.withOpacity(0.4), size: 30)),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.product.nombre, style: PeraCoText.bodyBold(context), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(item.product.displayFarm, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
                      const SizedBox(height: 6),
                      Text('${item.product.displayPrice}/${item.product.unidad}',
                          style: PeraCoText.price(context).copyWith(color: PeraCoColors.primary)),
                    ])),
                    Container(
                        decoration: BoxDecoration(color: PeraCoColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
                        child: Column(children: [
                          InkWell(onTap: () => ref.read(cartProvider.notifier).updateCantidad(item.product.id, 1),
                              child: Container(width: 36, height: 32, alignment: Alignment.center,
                                  child: const Icon(Icons.add, size: 18, color: PeraCoColors.primary))),
                          Container(width: 36, height: 30, alignment: Alignment.center, color: Colors.white,
                              child: Text('${item.cantidad}', style: PeraCoText.bodyBold(context))),
                          InkWell(onTap: () => ref.read(cartProvider.notifier).updateCantidad(item.product.id, -1),
                              child: Container(width: 36, height: 32, alignment: Alignment.center,
                                  child: Icon(Icons.remove, size: 18, color: item.cantidad > 1 ? PeraCoColors.primary : PeraCoColors.textHint))),
                        ])),
                  ])),
            );
          },
        )),

        // Resumen
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          decoration: BoxDecoration(color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -4))]),
          child: SafeArea(child: Column(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(color: PeraCoColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
                child: const Row(children: [
                  Icon(Icons.local_offer_outlined, color: PeraCoColors.primary, size: 20),
                  SizedBox(width: 10),
                  Expanded(child: Text('Agregar codigo de descuento', style: TextStyle(fontSize: 13, color: PeraCoColors.textSecondary))),
                  Icon(Icons.chevron_right, color: PeraCoColors.textHint, size: 20),
                ])),
            const SizedBox(height: 14),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Subtotal (${cart.totalItems} productos)', style: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.textSecondary)),
              Text(_formatPrice(cart.subtotal), style: PeraCoText.body(context)),
            ]),
            const SizedBox(height: 6),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Envio', style: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.textSecondary)),
              cart.envio == 0
                  ? Text('GRATIS', style: PeraCoText.bodyBold(context).copyWith(color: PeraCoColors.primary))
                  : Text(_formatPrice(cart.envio), style: PeraCoText.body(context)),
            ]),
            if (cart.envio > 0) ...[
              const SizedBox(height: 4),
              Text('Envio gratis en compras mayores a COP 50.000', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textHint)),
            ],
            const Divider(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Total', style: PeraCoText.h3(context)),
              Text(_formatPrice(cart.total), style: PeraCoText.h3(context).copyWith(color: PeraCoColors.primary)),
            ]),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, height: 52,
                child: ElevatedButton.icon(
                    onPressed: () => context.push(AppRoutes.checkout),
                    icon: const Icon(Icons.shopping_basket, size: 20),
                    label: Text('Ir a pagar  ${_formatPrice(cart.total)}'),
                    style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
          ])),
        ),
      ]),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Row(children: [
        Icon(Icons.shopping_basket, color: PeraCoColors.primary), SizedBox(width: 8), Text('Mi Canasta')])),
      body: Center(child: Padding(padding: const EdgeInsets.all(40),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: 100, height: 100,
                decoration: BoxDecoration(color: PeraCoColors.greenPastel, borderRadius: BorderRadius.circular(30)),
                child: Icon(Icons.shopping_basket_outlined, size: 50, color: PeraCoColors.primary.withOpacity(0.5))),
            const SizedBox(height: 24),
            Text('Tu canasta esta vacia', style: PeraCoText.h3(context)),
            const SizedBox(height: 8),
            Text('Agrega productos frescos del campo\npara comenzar tu pedido',
                style: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            ElevatedButton.icon(onPressed: () => context.go(AppRoutes.clientCatalog),
                icon: const Icon(Icons.search, size: 20), label: const Text('Explorar productos')),
          ]))),
    );
  }
}