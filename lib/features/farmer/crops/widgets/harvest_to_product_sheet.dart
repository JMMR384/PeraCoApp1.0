import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/features/client/catalog/providers/products_provider.dart';
import 'package:peraco/features/farmer/crops/providers/harvest_provider.dart';
import 'package:peraco/features/farmer/products/models/farmer_product.dart';
import 'package:peraco/features/farmer/products/providers/farmer_products_provider.dart';

class HarvestToProductSheet extends ConsumerStatefulWidget {
  final Harvest harvest;
  const HarvestToProductSheet({super.key, required this.harvest});

  static Future<void> show(BuildContext context, Harvest harvest) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HarvestToProductSheet(harvest: harvest),
    );
  }

  @override
  ConsumerState<HarvestToProductSheet> createState() => _HarvestToProductSheetState();
}

class _HarvestToProductSheetState extends ConsumerState<HarvestToProductSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreCtrl;
  late TextEditingController _descripcionCtrl;
  late TextEditingController _precioCtrl;
  late TextEditingController _stockCtrl;
  String _unidad = 'kg';
  String? _categoriaId;
  bool _esTemporada = false;
  bool _loading = true;
  bool _saving = false;

  FarmerProduct? _existingProduct;

  final _unidades = ['kg', 'ton', 'lb', 'canastillas', 'costales', 'unidad', 'manojo', 'litro'];

  @override
  void initState() {
    super.initState();
    final h = widget.harvest;
    _nombreCtrl      = TextEditingController(text: h.cultivoNombre);
    _descripcionCtrl = TextEditingController(text: h.notas ?? '');
    _precioCtrl      = TextEditingController();
    _stockCtrl       = TextEditingController(
      text: h.cantidadEstimada != null ? h.cantidadEstimada!.toStringAsFixed(0) : '',
    );
    _unidad = _unidades.contains(h.unidad) ? h.unidad : 'kg';
    _loadExistingProduct();
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _descripcionCtrl.dispose();
    _precioCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadExistingProduct() async {
    final existing = await ref
        .read(farmerProductsProvider.notifier)
        .findByCosechaId(widget.harvest.id);
    if (mounted) {
      setState(() {
        _existingProduct = existing;
        if (existing != null) {
          _nombreCtrl.text      = existing.nombre;
          _descripcionCtrl.text = existing.descripcion ?? '';
          _precioCtrl.text      = existing.precio.toStringAsFixed(0);
          _stockCtrl.text       = existing.stock.toStringAsFixed(0);
          _unidad               = _unidades.contains(existing.unidad) ? existing.unidad : 'kg';
          _categoriaId          = existing.categoriaId;
          _esTemporada          = existing.esTemporada;
        }
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final notifier = ref.read(farmerProductsProvider.notifier);
    bool success;

    if (_existingProduct != null) {
      success = await notifier.updateProduct(
        id: _existingProduct!.id,
        nombre: _nombreCtrl.text,
        descripcion: _descripcionCtrl.text.isEmpty ? null : _descripcionCtrl.text,
        precio: double.parse(_precioCtrl.text),
        unidad: _unidad,
        stock: double.parse(_stockCtrl.text),
        categoriaId: _categoriaId,
        esTemporada: _esTemporada,
        cosechaId: widget.harvest.id,
      );
    } else {
      success = await notifier.createProduct(
        nombre: _nombreCtrl.text,
        descripcion: _descripcionCtrl.text.isEmpty ? null : _descripcionCtrl.text,
        precio: double.parse(_precioCtrl.text),
        unidad: _unidad,
        stock: double.parse(_stockCtrl.text),
        categoriaId: _categoriaId,
        esTemporada: _esTemporada,
        cosechaId: widget.harvest.id,
      );
    }

    if (success) {
      await ref
          .read(harvestProvider.notifier)
          .updateStatus(widget.harvest.id, HarvestStatus.cosechado);
    }

    setState(() => _saving = false);

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_existingProduct != null
            ? 'Producto actualizado y cosecha marcada'
            : 'Producto publicado y cosecha marcada'),
        backgroundColor: PeraCoColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isUpdate = _existingProduct != null;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(children: [
        Container(
          width: 40, height: 4,
          margin: const EdgeInsets.only(top: 12),
          decoration: BoxDecoration(color: PeraCoColors.divider, borderRadius: BorderRadius.circular(2)),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                isUpdate ? 'Actualizar producto' : 'Publicar en catálogo',
                style: PeraCoText.h3(context),
              ),
              const SizedBox(height: 2),
              Text(
                'Cosecha: ${widget.harvest.cultivoNombre}',
                style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary),
              ),
            ])),
            IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
          ]),
        ),
        const Divider(height: 1),

        if (_loading)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else ...[
          if (isUpdate)
            Container(
              margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: PeraCoColors.info.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: PeraCoColors.info.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.sync_outlined, size: 18, color: PeraCoColors.info),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ya existe un producto para esta cosecha. Se actualizará el stock y la información.',
                    style: PeraCoText.caption(context).copyWith(color: PeraCoColors.info),
                  ),
                ),
              ]),
            ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Información del producto', style: PeraCoText.bodyBold(context)),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _nombreCtrl,
                    style: PeraCoText.body(context),
                    validator: (v) => v == null || v.isEmpty ? 'Nombre requerido' : null,
                    decoration: const InputDecoration(
                      hintText: 'Nombre del producto',
                      prefixIcon: Icon(Icons.eco_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descripcionCtrl,
                    style: PeraCoText.body(context),
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Descripción (opcional)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  categoriesAsync.when(
                    data: (cats) => DropdownButtonFormField<String>(
                      value: _categoriaId,
                      decoration: const InputDecoration(
                        hintText: 'Categoría (opcional)',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      items: cats.map((c) => DropdownMenuItem(
                        value: c['id'] as String,
                        child: Text(c['nombre'] as String),
                      )).toList(),
                      onChanged: (v) => setState(() => _categoriaId = v),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const Text('Error cargando categorías'),
                  ),
                  const SizedBox(height: 20),

                  Text('Precio y stock', style: PeraCoText.bodyBold(context)),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _precioCtrl,
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Precio requerido';
                          if (double.tryParse(v) == null) return 'Número inválido';
                          return null;
                        },
                        decoration: const InputDecoration(
                          hintText: 'Precio COP',
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        value: _unidad,
                        decoration: const InputDecoration(hintText: 'Unidad'),
                        items: _unidades.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                        onChanged: (v) => setState(() => _unidad = v!),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _stockCtrl,
                    style: PeraCoText.body(context),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Stock requerido';
                      if (double.tryParse(v) == null) return 'Número inválido';
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Stock disponible ($_unidad)',
                      prefixIcon: const Icon(Icons.inventory_outlined),
                      helperText: widget.harvest.cantidadEstimada != null
                          ? 'Estimado de cosecha: ${widget.harvest.cantidadEstimada!.toStringAsFixed(1)} ${widget.harvest.unidad}'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 16),

                  SwitchListTile(
                    title: Text('Producto de temporada', style: PeraCoText.body(context)),
                    subtitle: Text(
                      'Se mostrará en la sección de temporada',
                      style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary),
                    ),
                    value: _esTemporada,
                    activeColor: PeraCoColors.primary,
                    onChanged: (v) => setState(() => _esTemporada = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
                      : Icon(isUpdate ? Icons.sync : Icons.storefront_outlined),
                  label: Text(isUpdate ? 'Actualizar producto' : 'Publicar en catálogo'),
                ),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}
