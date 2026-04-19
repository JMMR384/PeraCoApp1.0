import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/core/config/supabase_config.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/features/client/cart/providers/cart_provider.dart';
import 'package:peraco/features/client/catalog/providers/products_provider.dart';

final _productImagesProvider = FutureProvider.family<List<String>, String>((ref, productId) async {
  final data = await SupabaseConfig.client
      .from('producto_imagenes')
      .select('imagen_url')
      .eq('producto_id', productId)
      .order('orden');
  return (data as List).map((e) => e['imagen_url'] as String).toList();
});

class ProductDetailScreen extends ConsumerStatefulWidget {
  final String productId;
  const ProductDetailScreen({super.key, required this.productId});
  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  final _pageCtrl = PageController();
  int _currentPage = 0;
  int _cantidad = 1;

  @override
  void dispose() { _pageCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final imagesAsync = ref.watch(_productImagesProvider(widget.productId));

    return productsAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (products) {
        final product = products.firstWhere(
          (p) => p.id == widget.productId,
          orElse: () => throw StateError('Producto no encontrado'),
        );

        final extraImages = imagesAsync.asData?.value ?? [];
        final allImages = [
          if (product.imagenUrl != null) product.imagenUrl!,
          ...extraImages,
        ];

        return Scaffold(
          backgroundColor: Colors.white,
          body: CustomScrollView(
            slivers: [
              // Imagen carrusel con AppBar overlay
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: Colors.white,
                leading: IconButton(
                  icon: const CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 18,
                    child: Icon(Icons.arrow_back, color: PeraCoColors.textPrimary, size: 20),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: allImages.isEmpty
                      ? Container(
                          color: PeraCoColors.greenPastel,
                          child: Icon(Icons.eco, size: 80, color: PeraCoColors.primary.withOpacity(0.3)))
                      : Stack(
                          children: [
                            PageView.builder(
                              controller: _pageCtrl,
                              itemCount: allImages.length,
                              onPageChanged: (i) => setState(() => _currentPage = i),
                              itemBuilder: (_, i) => Image.network(
                                allImages[i],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: PeraCoColors.greenPastel,
                                  child: Icon(Icons.eco, size: 60, color: PeraCoColors.primary.withOpacity(0.3)),
                                ),
                              ),
                            ),
                            if (allImages.length > 1)
                              Positioned(
                                bottom: 12,
                                left: 0,
                                right: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(allImages.length, (i) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    width: i == _currentPage ? 20 : 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(3),
                                      color: i == _currentPage ? PeraCoColors.primary : Colors.white.withOpacity(0.6),
                                    ),
                                  )),
                                ),
                              ),
                          ],
                        ),
                ),
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    // Vendedor
                    Row(children: [
                      const Icon(Icons.storefront_outlined, size: 16, color: PeraCoColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        product.displayFarm,
                        style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary),
                      ),
                    ]),
                    const SizedBox(height: 8),

                    // Nombre
                    Text(product.nombre, style: PeraCoText.h2(context).copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),

                    // Precio y unidad
                    Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                      Text(product.displayPrice, style: PeraCoText.priceLarge(context).copyWith(color: PeraCoColors.primary)),
                      const SizedBox(width: 4),
                      Text(product.displayUnit, style: PeraCoText.body(context).copyWith(color: PeraCoColors.textSecondary)),
                    ]),
                    const SizedBox(height: 16),

                    // Stock
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: product.stock > 0 ? PeraCoColors.greenPastel : const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                          product.stock > 0 ? Icons.check_circle_outline : Icons.warning_amber_outlined,
                          size: 16,
                          color: product.stock > 0 ? PeraCoColors.primary : PeraCoColors.warning,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          product.stock > 0
                              ? 'Disponible: ${product.stock.toStringAsFixed(0)} ${product.unidad}'
                              : 'Sin stock',
                          style: PeraCoText.caption(context).copyWith(
                            color: product.stock > 0 ? PeraCoColors.primaryDark : PeraCoColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 24),

                    // Descripcion
                    if (product.descripcion.isNotEmpty) ...[
                      Text('Descripcion', style: PeraCoText.bodyBold(context)),
                      const SizedBox(height: 8),
                      Text(product.descripcion, style: PeraCoText.body(context).copyWith(
                        color: PeraCoColors.textSecondary, height: 1.6)),
                      const SizedBox(height: 24),
                    ],

                    // Selector de cantidad
                    Text('Cantidad', style: PeraCoText.bodyBold(context)),
                    const SizedBox(height: 10),
                    Row(children: [
                      _CounterButton(
                        icon: Icons.remove,
                        onTap: () { if (_cantidad > 1) setState(() => _cantidad--); },
                      ),
                      const SizedBox(width: 16),
                      Text('$_cantidad', style: PeraCoText.bodyBold(context).copyWith(fontSize: 20)),
                      const SizedBox(width: 16),
                      _CounterButton(
                        icon: Icons.add,
                        onTap: () {
                          if (_cantidad < product.stock) setState(() => _cantidad++);
                        },
                      ),
                    ]),
                  ]),
                ),
              ),
            ],
          ),

          // Botón fijo en la parte inferior
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: ElevatedButton.icon(
                onPressed: product.stock > 0
                    ? () {
                        for (int i = 0; i < _cantidad; i++) {
                          ref.read(cartProvider.notifier).addProduct(product);
                        }
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('${product.nombre} agregado al carrito',
                              style: PeraCoText.bodySmall(context).copyWith(color: Colors.white)),
                          backgroundColor: PeraCoColors.primary,
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          duration: const Duration(seconds: 2),
                        ));
                      }
                    : null,
                icon: const Icon(Icons.shopping_cart_outlined),
                label: Text('Agregar al carrito', style: PeraCoText.button(context)),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CounterButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CounterButton({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          border: Border.all(color: PeraCoColors.divider),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: PeraCoColors.textPrimary),
      ),
    );
  }
}
