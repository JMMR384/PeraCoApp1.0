import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/features/client/catalog/providers/products_provider.dart';
import 'package:peraco/features/client/cart/providers/cart_provider.dart';

class ClientCatalogScreen extends ConsumerStatefulWidget {
  const ClientCatalogScreen({super.key});
  @override
  ConsumerState<ClientCatalogScreen> createState() => _ClientCatalogScreenState();
}

class _ClientCatalogScreenState extends ConsumerState<ClientCatalogScreen> {
  final _searchCtrl = TextEditingController();
  String _selectedCategory = 'Todos';
  String _searchQuery = '';

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(slivers: [
          SliverToBoxAdapter(child: Container(color: Colors.white, padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: TextField(controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: PeraCoText.body(context),
                  decoration: InputDecoration(hintText: 'Buscar productos...', hintStyle: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.textHint),
                      prefixIcon: const Icon(Icons.search, color: PeraCoColors.textHint),
                      suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.close), onPressed: () { _searchCtrl.clear(); setState(() => _searchQuery = ''); }) : null,
                      filled: true, fillColor: PeraCoColors.surfaceVariant,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14))))),

          SliverToBoxAdapter(child: SizedBox(height: 46,
              child: categoriesAsync.when(
                data: (cats) {
                  final names = ['Todos', ...cats.map((c) => c['nombre'] as String)];
                  return ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: names.length, itemBuilder: (context, index) {
                        final cat = names[index]; final isSelected = _selectedCategory == cat;
                        return Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: FilterChip(label: Text(cat, style: PeraCoText.label(context).copyWith(
                                color: isSelected ? PeraCoColors.primaryDark : PeraCoColors.textSecondary,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                                selected: isSelected, onSelected: (_) => setState(() => _selectedCategory = cat),
                                selectedColor: PeraCoColors.greenPastel, checkmarkColor: PeraCoColors.primary,
                                side: BorderSide(color: isSelected ? PeraCoColors.primary : PeraCoColors.divider), backgroundColor: Colors.white));
                      });
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => const Center(child: Text('Error cargando categorias')),
              ))),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          productsAsync.when(
            data: (allProducts) {
              var products = allProducts.toList();
              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                products = products.where((p) => p.nombre.toLowerCase().contains(q) || p.descripcion.toLowerCase().contains(q)).toList();
              }
              if (_selectedCategory != 'Todos') {
                final catsAsync = ref.read(categoriesProvider);
                catsAsync.whenData((cats) {
                  final cat = cats.firstWhere((c) => c['nombre'] == _selectedCategory, orElse: () => {});
                  if (cat.isNotEmpty) {
                    products = products.where((p) => p.categoriaId == cat['id']).toList();
                  }
                });
              }

              final seasonal = allProducts.where((p) => p.esTemporada).toList();
              final popular = allProducts.take(4).toList();

              return SliverList(delegate: SliverChildListDelegate([
                if (_searchQuery.isEmpty && _selectedCategory == 'Todos') ...[
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(children: [
                        const Icon(Icons.local_fire_department, color: Color(0xFFFF6D00), size: 22),
                        const SizedBox(width: 6),
                        Text('Mas consultadas', style: PeraCoText.h3(context)),
                      ])),
                  const SizedBox(height: 12),
                  SizedBox(height: 160,
                      child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: popular.length, itemBuilder: (ctx, i) => _PopularProductCard(product: popular[i]))),
                  const SizedBox(height: 20),

                  if (seasonal.isNotEmpty) ...[
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(width: double.infinity, padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: PeraCoColors.greenPastel, borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: PeraCoColors.primary.withOpacity(0.2))),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: PeraCoColors.primary, borderRadius: BorderRadius.circular(8)),
                                  child: const Text('DE TEMPORADA', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1))),
                              const SizedBox(height: 12),
                              SizedBox(height: 110, child: ListView.builder(scrollDirection: Axis.horizontal,
                                  itemCount: seasonal.length, itemBuilder: (ctx, i) => _SeasonItem(product: seasonal[i]))),
                            ]))),
                    const SizedBox(height: 20),
                  ],

                  Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(width: double.infinity, height: 100,
                          decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF1B8F31), Color(0xFF16502D)]),
                              borderRadius: BorderRadius.circular(14)),
                          child: Stack(children: [
                            Positioned(right: 16, top: 0, bottom: 0,
                                child: Opacity(opacity: 1, child: Image.asset('assets/images/logo_blanco.png', width: 100, fit: BoxFit.contain))),
                            Padding(padding: const EdgeInsets.all(16),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Text('Envio gratis en tu primer pedido', style: PeraCoText.bodyBold(context).copyWith(color: Colors.white)),
                                  const SizedBox(height: 4),
                                  Text('Usa el codigo PERACO2026', style: PeraCoText.bodySmall(context).copyWith(color: Colors.white.withOpacity(0.8))),
                                ])),
                          ]))),
                  const SizedBox(height: 24),
                ],

                Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(children: [
                      Text(_selectedCategory == 'Todos' ? 'Todos los productos' : _selectedCategory, style: PeraCoText.h3(context)),
                      const Spacer(),
                      Text('${products.length} productos', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
                    ])),
                const SizedBox(height: 12),

                if (products.isEmpty)
                  Padding(padding: const EdgeInsets.all(40),
                      child: Center(child: Column(children: [
                        Icon(Icons.search_off, size: 48, color: PeraCoColors.textHint),
                        const SizedBox(height: 12),
                        Text('No se encontraron productos', style: PeraCoText.body(context).copyWith(color: PeraCoColors.textSecondary)),
                      ])))
                else
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
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
                          itemCount: products.length,
                          itemBuilder: (ctx, i) => _ProductCard(product: products[i]),
                        );
                      })),
                const SizedBox(height: 24),
              ]));
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverFillRemaining(child: Center(child: Column(
                mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline, size: 48, color: PeraCoColors.error),
              const SizedBox(height: 12),
              Text('Error al cargar productos', style: PeraCoText.body(context)),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: () => ref.read(productsProvider.notifier).loadProducts(), child: const Text('Reintentar')),
            ]))),
          ),
        ]),
      ),
    );
  }
}

class _PopularProductCard extends StatelessWidget {
  final Product product;
  const _PopularProductCard({required this.product});
  @override
  Widget build(BuildContext context) {
    return Container(width: 145, margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: PeraCoColors.divider, width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: double.infinity, height: 60,
              decoration: BoxDecoration(color: PeraCoColors.greenPastel, borderRadius: BorderRadius.circular(10)),
              child: product.imagenUrl != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(product.imagenUrl!, fit: BoxFit.cover))
                  : Icon(Icons.eco, color: PeraCoColors.primary.withOpacity(0.4), size: 28)),
          const SizedBox(height: 8),
          Text(product.nombre, style: PeraCoText.label(context), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(product.displayFarm, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Row(children: [
            Text(product.displayPrice, style: PeraCoText.price(context).copyWith(color: PeraCoColors.primary)),
            Text(product.displayUnit, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
          ]),
        ]));
  }
}

class _SeasonItem extends StatelessWidget {
  final Product product;
  const _SeasonItem({required this.product});
  @override
  Widget build(BuildContext context) {
    return Container(width: 100, margin: const EdgeInsets.only(right: 12),
        child: Column(children: [
          Container(width: 60, height: 60,
              decoration: BoxDecoration(color: PeraCoColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
              child: product.imagenUrl != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.network(product.imagenUrl!, fit: BoxFit.cover))
                  : Icon(Icons.eco, color: PeraCoColors.primary, size: 28)),
          const SizedBox(height: 6),
          Text(product.nombre, style: PeraCoText.caption(context).copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(product.displaySeason, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary, fontSize: 10), textAlign: TextAlign.center),
        ]));
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  const _ProductCard({required this.product});
  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: PeraCoColors.divider, width: 0.5)),
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
                      Container(width: 24, height: 24, decoration: BoxDecoration(color: PeraCoColors.primary, borderRadius: BorderRadius.circular(6)),
                          child: const Icon(Icons.add, color: Colors.white, size: 14)),
                    ]),
                  ]))),
        ]));
  }
}