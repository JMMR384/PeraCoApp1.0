import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/features/client/cart/providers/cart_provider.dart';
import 'package:peraco/features/client/catalog/providers/products_provider.dart';

class ProductCard extends ConsumerWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/client/product/${product.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: PeraCoColors.divider, width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 5,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: PeraCoColors.greenPastel,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: product.imagenUrl != null
                  ? ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(10)), child: Image.network(product.imagenUrl!, fit: BoxFit.cover))
                  : Center(child: Icon(Icons.eco, size: 32, color: PeraCoColors.primary.withValues(alpha: 0.3))),
            ),
          ),
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(product.nombre, style: PeraCoText.label(context), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(product.displayFarm, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Flexible(child: Text(product.displayPrice, style: PeraCoText.price(context).copyWith(color: PeraCoColors.primary), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    GestureDetector(
                      onTap: () => ref.read(cartProvider.notifier).addProduct(product),
                      child: Container(
                        width: 24, height: 24,
                        decoration: BoxDecoration(color: PeraCoColors.primary, borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.add, color: Colors.white, size: 14),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
