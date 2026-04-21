import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/features/client/catalog/providers/products_provider.dart';

class SeasonItem extends StatelessWidget {
  final Product product;
  const SeasonItem({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/client/product/${product.id}'),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        child: Column(children: [
          Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: PeraCoColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: product.imagenUrl != null
                ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(product.imagenUrl!, fit: BoxFit.cover))
                : Icon(Icons.eco, color: PeraCoColors.primary, size: 28),
          ),
          const SizedBox(height: 6),
          Text(product.nombre,
              style: PeraCoText.caption(context).copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(product.displaySeason,
              style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary, fontSize: 10),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
