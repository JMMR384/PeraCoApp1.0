import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/features/client/catalog/providers/products_provider.dart';
import 'package:peraco/features/farmer/products/providers/farmer_products_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:peraco/core/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
                  Icon(Icons.inventory_2_outlined, size: 72, color: PeraCoColors.primaryLight.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('Sin productos publicados', style: PeraCoText.body(context).copyWith(color: PeraCoColors.textSecondary)),
                  const SizedBox(height: 4),
                  Text('Agrega tu primer producto para empezar a vender', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textHint), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                      onPressed: () => _showProductForm(context, ref),
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
        onPressed: () => _showProductForm(context, ref),
        backgroundColor: PeraCoColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Agregar', style: PeraCoText.button(context).copyWith(color: Colors.white)),
      ),
    );
  }

  void _showProductForm(BuildContext context, WidgetRef ref, {FarmerProduct? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductFormSheet(product: product),
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
          border: Border.all(color: product.activo ? PeraCoColors.divider : PeraCoColors.error.withOpacity(0.3))),
      child: Row(children: [
        Container(width: 56, height: 56,
            decoration: BoxDecoration(color: PeraCoColors.greenPastel, borderRadius: BorderRadius.circular(10)),
            child: product.imagenUrl != null
                ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(product.imagenUrl!, fit: BoxFit.cover))
                : Icon(Icons.eco, color: PeraCoColors.primary.withOpacity(0.4), size: 24)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(product.nombre, style: PeraCoText.bodyBold(context), maxLines: 1, overflow: TextOverflow.ellipsis)),
            if (!product.activo)
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: PeraCoColors.error.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
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
              showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                  builder: (_) => _ProductFormSheet(product: product));
            } else if (val == 'toggle') {
              print('TOGGLE: ${product.id} activo: ${product.activo} -> ${!product.activo}');
              final result = await ref.read(farmerProductsProvider.notifier).toggleActive(product.id, !product.activo);
              print('TOGGLE RESULT: $result');
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

class _ProductFormSheet extends ConsumerStatefulWidget {
  final FarmerProduct? product;
  const _ProductFormSheet({this.product});
  @override
  ConsumerState<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _descripcionCtrl;
  late TextEditingController _precioCtrl;
  late TextEditingController _stockCtrl;
  String _unidad = 'kg';
  String? _categoriaId;
  bool _esTemporada = false;
  bool _loading = false;
  File? _imageFile;
  String? _currentImageUrl;

  final _unidades = ['kg', 'lb', 'unidad', 'manojo', 'litro'];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nombreCtrl = TextEditingController(text: p?.nombre ?? '');
    _descripcionCtrl = TextEditingController(text: p?.descripcion ?? '');
    _precioCtrl = TextEditingController(text: p != null ? p.precio.toStringAsFixed(0) : '');
    _stockCtrl = TextEditingController(text: p != null ? p.stock.toStringAsFixed(0) : '');
    _unidad = p?.unidad ?? 'kg';
    _categoriaId = p?.categoriaId;
    _esTemporada = p?.esTemporada ?? false;
    _currentImageUrl = p?.imagenUrl;
  }

  @override
  void dispose() { _nombreCtrl.dispose(); _descripcionCtrl.dispose(); _precioCtrl.dispose(); _stockCtrl.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.camera_alt, color: PeraCoColors.primary),
            title: const Text('Tomar foto'), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
        ListTile(leading: const Icon(Icons.photo_library, color: PeraCoColors.primary),
            title: const Text('Galeria'), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
      ])),
    );
    if (source == null) return;
    final picked = await picker.pickImage(source: source, maxWidth: 800, maxHeight: 800, imageQuality: 75);
    if (picked != null) setState(() => _imageFile = File(picked.path));
  }

  Future<String?> _uploadImage(String productId) async {
    if (_imageFile == null) return _currentImageUrl;
    try {
      final ext = _imageFile!.path.split('.').last;
      final path = '$productId.$ext';
      await SupabaseConfig.client.storage.from('productos').upload(
          path, _imageFile!, fileOptions: const FileOptions(upsert: true));
      final url = SupabaseConfig.client.storage.from('productos').getPublicUrl(path);
      return url;
    } catch (e) {
      print('ERROR SUBIENDO IMAGEN: $e');
      return _currentImageUrl;
    }
  }
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final notifier = ref.read(farmerProductsProvider.notifier);
    bool success;
    String? imageUrl;

    if (widget.product != null) {
      imageUrl = await _uploadImage(widget.product!.id);
      success = await notifier.updateProduct(
        id: widget.product!.id,
        nombre: _nombreCtrl.text, descripcion: _descripcionCtrl.text,
        precio: double.parse(_precioCtrl.text), unidad: _unidad,
        stock: double.parse(_stockCtrl.text), categoriaId: _categoriaId,
        esTemporada: _esTemporada, imagenUrl: imageUrl,
      );
    } else {
      success = await notifier.createProduct(
        nombre: _nombreCtrl.text, descripcion: _descripcionCtrl.text,
        precio: double.parse(_precioCtrl.text), unidad: _unidad,
        stock: double.parse(_stockCtrl.text), categoriaId: _categoriaId,
        esTemporada: _esTemporada,
      );
      // Si se creó y hay imagen, subir con el ID del producto creado
      if (success && _imageFile != null) {
        final products = ref.read(farmerProductsProvider).value ?? [];
        if (products.isNotEmpty) {
          imageUrl = await _uploadImage(products.first.id);
          if (imageUrl != null) {
            await notifier.updateProduct(
              id: products.first.id,
              nombre: _nombreCtrl.text, descripcion: _descripcionCtrl.text,
              precio: double.parse(_precioCtrl.text), unidad: _unidad,
              stock: double.parse(_stockCtrl.text), categoriaId: _categoriaId,
              esTemporada: _esTemporada, imagenUrl: imageUrl,
            );
          }
        }
      }
    }

    setState(() => _loading = false);
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.product != null ? 'Producto actualizado' : 'Producto creado'),
          backgroundColor: PeraCoColors.success, behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isEditing = widget.product != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(children: [
        // Handle
        Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(color: PeraCoColors.divider, borderRadius: BorderRadius.circular(2))),
        // Header
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
            child: Row(children: [
              Text(isEditing ? 'Editar producto' : 'Nuevo producto', style: PeraCoText.h3(context)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ])),
        const Divider(height: 1),

        // Form
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20),
            child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Imagen del producto
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity, height: 160,
                  decoration: BoxDecoration(
                      color: PeraCoColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: PeraCoColors.divider, style: BorderStyle.solid)),
                  child: _imageFile != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(14),
                      child: Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity))
                      : _currentImageUrl != null
                      ? ClipRRect(borderRadius: BorderRadius.circular(14),
                      child: Image.network(_currentImageUrl!, fit: BoxFit.cover, width: double.infinity))
                      : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_a_photo_outlined, size: 40, color: PeraCoColors.primary.withOpacity(0.5)),
                    const SizedBox(height: 8),
                    Text('Agregar foto del producto', style: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.textSecondary)),
                    const SizedBox(height: 4),
                    Text('Toca para tomar foto o elegir de galeria', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textHint)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),

              Text('Informacion basica', style: PeraCoText.bodyBold(context)),
              const SizedBox(height: 12),
              TextFormField(controller: _nombreCtrl, style: PeraCoText.body(context),
                  validator: (v) => v == null || v.isEmpty ? 'Nombre requerido' : null,
                  decoration: const InputDecoration(hintText: 'Nombre del producto', prefixIcon: Icon(Icons.eco_outlined))),
              const SizedBox(height: 12),
              TextFormField(controller: _descripcionCtrl, style: PeraCoText.body(context), maxLines: 3,
                  decoration: const InputDecoration(hintText: 'Descripcion (opcional)', alignLabelWithHint: true)),
              const SizedBox(height: 12),

              // Categoria
              categoriesAsync.when(
                data: (cats) => DropdownButtonFormField<String>(
                    value: _categoriaId,
                    decoration: const InputDecoration(hintText: 'Categoria', prefixIcon: Icon(Icons.category_outlined)),
                    items: cats.map((c) => DropdownMenuItem(value: c['id'] as String, child: Text(c['nombre'] as String))).toList(),
                    onChanged: (v) => setState(() => _categoriaId = v)),
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Error cargando categorias'),
              ),

              const SizedBox(height: 15),
              Text('Precio y stock', style: PeraCoText.bodyBold(context)),
              const SizedBox(height: 15),
              Row(children: [
                Expanded(flex: 3, child: TextFormField(controller: _precioCtrl,
                    keyboardType: TextInputType.number,
                    validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                    decoration: const InputDecoration(hintText: 'Precio COP', prefixIcon: Icon(Icons.attach_money)))),
                const SizedBox(width: 10),
                Expanded(flex: 2, child: DropdownButtonFormField<String>(
                    value: _unidad,
                    decoration: const InputDecoration(hintText: 'Unidad'),
                    items: _unidades.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                    onChanged: (v) => setState(() => _unidad = v!))),
              ]),
              const SizedBox(height: 12),
              TextFormField(controller: _stockCtrl, style: PeraCoText.body(context),
                  keyboardType: TextInputType.number,
                  validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
                  decoration: InputDecoration(hintText: 'Stock disponible ($_unidad)', prefixIcon: const Icon(Icons.inventory_outlined))),

              const SizedBox(height: 16),
              SwitchListTile(
                  title: Text('Producto de temporada', style: PeraCoText.body(context)),
                  subtitle: Text('Se mostrara en la seccion de temporada', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
                  value: _esTemporada, activeColor: PeraCoColors.primary,
                  onChanged: (v) => setState(() => _esTemporada = v),
                  contentPadding: EdgeInsets.zero),

              const SizedBox(height: 24),
            ])))),

        // Boton guardar
        Container(padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, -2))]),
            child: SafeArea(child: SizedBox(width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                      : Text(isEditing ? 'Guardar cambios' : 'Crear producto'),
                )))),
      ]),
    );
  }
}