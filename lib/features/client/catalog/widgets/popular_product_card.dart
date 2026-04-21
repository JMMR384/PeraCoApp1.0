import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/features/client/catalog/providers/products_provider.dart';

class PopularProductCard extends StatelessWidget {
  final Product product;
  const PopularProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/client/product/${product.id}'),
      child: Container(
        width: 145,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: PeraCoColors.divider, width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: double.infinity, height: 60,
            decoration: BoxDecoration(color: PeraCoColors.greenPastel, borderRadius: BorderRadius.circular(10)),
            child: product.imagenUrl != null
                ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(product.imagenUrl!, fit: BoxFit.cover))
                : Icon(Icons.eco, color: PeraCoColors.primary.withValues(alpha: 0.4), size: 28),
          ),
          const SizedBox(height: 8),
          Text(product.nombre, style: PeraCoText.label(context), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(product.displayFarm, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Row(children: [
            Text(product.displayPrice, style: PeraCoText.price(context).copyWith(color: PeraCoColors.primary)),
            Text(product.displayUnit, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
          ]),
        ]),
      ),
    );
  }
}
