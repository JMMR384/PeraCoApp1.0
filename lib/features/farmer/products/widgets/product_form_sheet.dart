import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:peraco/core/config/supabase_config.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/features/client/catalog/providers/products_provider.dart';
import 'package:peraco/features/farmer/products/models/farmer_product.dart';
import 'package:peraco/features/farmer/products/providers/farmer_products_provider.dart';
import 'package:peraco/features/farmer/products/widgets/image_thumb.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductFormSheet extends ConsumerStatefulWidget {
  final FarmerProduct? product;
  const ProductFormSheet({super.key, this.product});

  static void show(BuildContext context, {FarmerProduct? product}) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => ProductFormSheet(product: product),
    );
  }

  @override
  ConsumerState<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends ConsumerState<ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _descripcionCtrl;
  late TextEditingController _precioCtrl;
  late TextEditingController _stockCtrl;
  String _unidad = 'kg';
  String? _categoriaId;
  bool _esTemporada = false;
  bool _loading = false;
  List<File> _newImages = [];
  List<String> _existingImageUrls = [];
  String? _currentImageUrl;

  final _unidades = ['kg', 'lb', 'unidad', 'manojo', 'litro'];

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nombreCtrl     = TextEditingController(text: p?.nombre ?? '');
    _descripcionCtrl = TextEditingController(text: p?.descripcion ?? '');
    _precioCtrl     = TextEditingController(text: p != null ? p.precio.toStringAsFixed(0) : '');
    _stockCtrl      = TextEditingController(text: p != null ? p.stock.toStringAsFixed(0) : '');
    _unidad         = p?.unidad ?? 'kg';
    _categoriaId    = p?.categoriaId;
    _esTemporada    = p?.esTemporada ?? false;
    _currentImageUrl = p?.imagenUrl;
    if (p != null) _loadExistingImages(p.id);
  }

  @override
  void dispose() {
    _nombreCtrl.dispose(); _descripcionCtrl.dispose();
    _precioCtrl.dispose(); _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingImages(String productId) async {
    try {
      final data = await SupabaseConfig.client.from('producto_imagenes')
          .select('imagen_url').eq('producto_id', productId).order('orden');
      if (mounted) setState(() => _existingImageUrls = (data as List).map((e) => e['imagen_url'] as String).toList());
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.camera_alt, color: PeraCoColors.primary),
            title: const Text('Tomar foto'), onTap: () => Navigator.pop(ctx, ImageSource.camera)),
        ListTile(leading: const Icon(Icons.photo_library, color: PeraCoColors.primary),
            title: const Text('Galeria (multiple)'), onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
      ])),
    );
    if (source == null) return;
    if (source == ImageSource.camera) {
      final picked = await picker.pickImage(source: source, maxWidth: 800, maxHeight: 800, imageQuality: 75);
      if (picked != null) setState(() => _newImages.add(File(picked.path)));
    } else {
      final picked = await picker.pickMultiImage(maxWidth: 800, maxHeight: 800, imageQuality: 75);
      if (picked.isNotEmpty) setState(() => _newImages.addAll(picked.map((p) => File(p.path))));
    }
  }

  Future<String?> _uploadMainImage(String productId) async {
    if (_newImages.isEmpty) return _currentImageUrl;
    try {
      final file = _newImages.first;
      final ext = file.path.split('.').last;
      final path = '$productId.$ext';
      await SupabaseConfig.client.storage.from('productos').upload(
          path, file, fileOptions: FileOptions(upsert: true));
      return SupabaseConfig.client.storage.from('productos').getPublicUrl(path);
    } catch (_) { return _currentImageUrl; }
  }

  Future<void> _uploadAdditionalImages(String productId) async {
    final startIndex = _currentImageUrl == null && _newImages.isNotEmpty ? 1 : 0;
    for (int i = startIndex; i < _newImages.length; i++) {
      try {
        final file = _newImages[i];
        final ext = file.path.split('.').last;
        final ts = DateTime.now().millisecondsSinceEpoch;
        final path = '${productId}_${ts}_$i.$ext';
        await SupabaseConfig.client.storage.from('productos').upload(
            path, file, fileOptions: FileOptions(upsert: true));
        final url = SupabaseConfig.client.storage.from('productos').getPublicUrl(path);
        await SupabaseConfig.client.from('producto_imagenes').insert({
          'producto_id': productId, 'imagen_url': url,
          'orden': _existingImageUrls.length + i,
        });
      } catch (_) {}
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final notifier = ref.read(farmerProductsProvider.notifier);
    bool success;
    String? imageUrl;

    if (widget.product != null) {
      imageUrl = await _uploadMainImage(widget.product!.id);
      success = await notifier.updateProduct(
        id: widget.product!.id, nombre: _nombreCtrl.text, descripcion: _descripcionCtrl.text,
        precio: double.parse(_precioCtrl.text), unidad: _unidad,
        stock: double.parse(_stockCtrl.text), categoriaId: _categoriaId,
        esTemporada: _esTemporada, imagenUrl: imageUrl,
      );
      if (success && _newImages.length > 1) await _uploadAdditionalImages(widget.product!.id);
    } else {
      success = await notifier.createProduct(
        nombre: _nombreCtrl.text, descripcion: _descripcionCtrl.text,
        precio: double.parse(_precioCtrl.text), unidad: _unidad,
        stock: double.parse(_stockCtrl.text), categoriaId: _categoriaId,
        esTemporada: _esTemporada,
      );
      if (success && _newImages.isNotEmpty) {
        final products = ref.read(farmerProductsProvider).value ?? [];
        if (products.isNotEmpty) {
          final newId = products.first.id;
          imageUrl = await _uploadMainImage(newId);
          if (imageUrl != null) {
            await notifier.updateProduct(
              id: newId, nombre: _nombreCtrl.text, descripcion: _descripcionCtrl.text,
              precio: double.parse(_precioCtrl.text), unidad: _unidad,
              stock: double.parse(_stockCtrl.text), categoriaId: _categoriaId,
              esTemporada: _esTemporada, imagenUrl: imageUrl,
            );
          }
          if (_newImages.length > 1) await _uploadAdditionalImages(newId);
        }
      }
    }

    setState(() => _loading = false);
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.product != null ? 'Producto actualizado' : 'Producto creado'),
          backgroundColor: PeraCoColors.success, behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isEditing = widget.product != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(children: [
        Container(width: 40, height: 4, margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(color: PeraCoColors.divider, borderRadius: BorderRadius.circular(2))),
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
            child: Row(children: [
              Text(isEditing ? 'Editar producto' : 'Nuevo producto', style: PeraCoText.h3(context)),
              const Spacer(),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ])),
        const Divider(height: 1),

        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20),
            child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Fotos del producto', style: PeraCoText.bodyBold(context)),
              const SizedBox(height: 8),
              SizedBox(height: 120, child: ListView(scrollDirection: Axis.horizontal, children: [
                if (_currentImageUrl != null)
                  ImageThumb(url: _currentImageUrl!, isMain: true, onRemove: null),
                ..._existingImageUrls.map((url) => ImageThumb(url: url, onRemove: () {
                  setState(() => _existingImageUrls.remove(url));
                })),
                ..._newImages.map((file) => Container(
                  width: 100, height: 100, margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(image: FileImage(file), fit: BoxFit.cover)),
                  child: Align(alignment: Alignment.topRight,
                      child: GestureDetector(onTap: () => setState(() => _newImages.remove(file)),
                          child: Container(margin: const EdgeInsets.all(4), padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                              child: const Icon(Icons.close, color: Colors.white, size: 14)))),
                )),
                GestureDetector(onTap: _pickImage,
                  child: Container(width: 100, height: 100,
                      decoration: BoxDecoration(color: PeraCoColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(12), border: Border.all(color: PeraCoColors.divider)),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.add_a_photo_outlined, size: 28, color: PeraCoColors.primary.withValues(alpha: 0.5)),
                        const SizedBox(height: 4),
                        Text('Agregar', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textHint)),
                      ]))),
              ])),
              Text('${(_currentImageUrl != null ? 1 : 0) + _existingImageUrls.length + _newImages.length} fotos',
                  style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textHint)),
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

        Container(padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(color: Colors.white,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))]),
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
