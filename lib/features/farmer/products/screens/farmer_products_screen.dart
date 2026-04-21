import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/features/farmer/products/models/farmer_product.dart';
import 'package:peraco/features/farmer/products/providers/farmer_products_provider.dart';
import 'package:peraco/features/farmer/products/widgets/product_form_sheet.dart';

class FarmerProductsScreen extends ConsumerWidget {
  const FarmerProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(farmerProductsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(children: [
                Text('Mis Productos', style: PeraCoText.h2(context)),
                const Spacer(),
                productsAsync.whenOrNull(data: (p) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: PeraCoColors.greenPastel, borderRadius: BorderRadius.circular(8)),
                  child: Text('${p.length} productos', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.primary)),
                )) ?? const SizedBox(),
              ])),

          Expanded(child: productsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline, size: 48, color: PeraCoColors.error),
              const SizedBox(height: 12),
              Text('Error al cargar', style: PeraCoText.body(context)),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: () => ref.read(farmerProductsProvider.notifier).loadProducts(), child: const Text('Reintentar')),
            ])),
            data: (products) {
              if (products.isEmpty) {
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.inventory_2_outlined, size: 72, color: PeraCoColors.primaryLight.withValues(alpha: 0.5)),
                  const SizedBox(height: 16),
                  Text('Sin productos publicados', style: PeraCoText.body(context).copyWith(color: PeraCoColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('Agrega tu primer producto para empezar a vender', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textHint), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                      onPressed: () => ProductFormSheet.show(context),
                      icon: const Icon(Icons.add, size: 20), label: const Text('Agregar producto')),
                ]));
              }
              return RefreshIndicator(
                onRefresh: () => ref.read(farmerProductsProvider.notifier).loadProducts(),
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 80),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, i) => _ProductTile(product: products[i]),
                ),
              );
            },
          )),
        ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ProductFormSheet.show(context),
        backgroundColor: PeraCoColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Agregar', style: PeraCoText.button(context).copyWith(color: Colors.white)),
      ),
    );
  }
}

class _ProductTile extends ConsumerWidget {
  final FarmerProduct product;
  const _ProductTile({required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: product.activo ? PeraCoColors.divider : PeraCoColors.error.withValues(alpha: 0.3))),
      child: Row(children: [
        Container(width: 56, height: 56,
            decoration: BoxDecoration(color: PeraCoColors.greenPastel, borderRadius: BorderRadius.circular(10)),
            child: product.imagenUrl != null
                ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(product.imagenUrl!, fit: BoxFit.cover))
                : Icon(Icons.eco, color: PeraCoColors.primary.withValues(alpha: 0.4), size: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(product.nombre, style: PeraCoText.bodyBold(context), maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (!product.activo)
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: PeraCoColors.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text('Inactivo', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.error, fontSize: 10))),
          ]),
          const SizedBox(height: 2),
          Text('${product.categoriaNombre ?? "Sin categoria"} · ${product.stock} ${product.unidad}',
              style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
          const SizedBox(height: 4),
          Text(product.displayPrice, style: PeraCoText.price(context).copyWith(color: PeraCoColors.primary)),
        ])),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: PeraCoColors.textHint),
          onSelected: (val) async {
            if (val == 'edit') {
              ProductFormSheet.show(context, product: product);
            } else if (val == 'toggle') {
              await ref.read(farmerProductsProvider.notifier).toggleActive(product.id, !product.activo);
            } else if (val == 'delete') {
              final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                  title: const Text('Eliminar producto'),
                  content: Text('Seguro que quieres eliminar "${product.nombre}"?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Eliminar', style: TextStyle(color: PeraCoColors.error))),
                  ]));
              if (confirm == true) await ref.read(farmerProductsProvider.notifier).deleteProduct(product.id);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Editar')])),
            PopupMenuItem(value: 'toggle', child: Row(children: [
              Icon(product.activo ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18),
              const SizedBox(width: 8), Text(product.activo ? 'Desactivar' : 'Activar')])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: PeraCoColors.error), SizedBox(width: 8), Text('Eliminar', style: TextStyle(color: PeraCoColors.error))])),
          ],
        ),
      ]),
    );
  }
}
