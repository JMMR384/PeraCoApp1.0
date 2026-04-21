import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/features/profile/providers/addresses_provider.dart';

class AddressFormSheet extends ConsumerStatefulWidget {
  final Address? address;
  const AddressFormSheet({super.key, this.address});

  static void show(BuildContext context, {Address? address}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddressFormSheet(address: address),
    );
  }

  @override
  ConsumerState<AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends ConsumerState<AddressFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreCtrl;
  late TextEditingController _direccionCtrl;
  late TextEditingController _ciudadCtrl;
  bool _esPrincipal = false;
  bool _loading = false;

  final _sugerencias = ['Casa', 'Oficina', 'Trabajo', 'Apartamento', 'Finca', 'Otro'];

  @override
  void initState() {
    super.initState();
    _nombreCtrl    = TextEditingController(text: widget.address?.nombre    ?? '');
    _direccionCtrl = TextEditingController(text: widget.address?.direccion ?? '');
    _ciudadCtrl    = TextEditingController(text: widget.address?.ciudad    ?? '');
    _esPrincipal   = widget.address?.esPrincipal ?? false;
  }

  @override
  void dispose() { _nombreCtrl.dispose(); _direccionCtrl.dispose(); _ciudadCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final notifier = ref.read(addressesProvider.notifier);
    final success = widget.address != null
        ? await notifier.update(id: widget.address!.id, nombre: _nombreCtrl.text, direccion: _direccionCtrl.text, ciudad: _ciudadCtrl.text, esPrincipal: _esPrincipal)
        : await notifier.add(nombre: _nombreCtrl.text, direccion: _direccionCtrl.text, ciudad: _ciudadCtrl.text, esPrincipal: _esPrincipal);
    setState(() => _loading = false);
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.address != null ? 'Direccion actualizada' : 'Direccion agregada'),
          backgroundColor: PeraCoColors.success, behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.address != null;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: SingleChildScrollView(child: Form(key: _formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: PeraCoColors.divider, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Row(children: [
          Text(isEditing ? 'Editar direccion' : 'Nueva direccion', style: PeraCoText.h3(context)),
          const Spacer(),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
        ]),
        const SizedBox(height: 16),
        if (!isEditing) ...[
          Wrap(spacing: 8, runSpacing: 8, children: _sugerencias.map((s) => GestureDetector(
            onTap: () => setState(() => _nombreCtrl.text = s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                  color: _nombreCtrl.text == s ? PeraCoColors.primary.withValues(alpha: 0.1) : PeraCoColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _nombreCtrl.text == s ? PeraCoColors.primary : PeraCoColors.divider)),
              child: Text(s, style: PeraCoText.caption(context).copyWith(
                  color: _nombreCtrl.text == s ? PeraCoColors.primary : PeraCoColors.textSecondary, fontWeight: FontWeight.w500)),
            ),
          )).toList()),
          const SizedBox(height: 16),
        ],
        TextFormField(controller: _nombreCtrl, style: PeraCoText.body(context),
            validator: (v) => v == null || v.isEmpty ? 'Nombre requerido' : null,
            decoration: const InputDecoration(hintText: 'Nombre (ej: Casa, Oficina)', prefixIcon: Icon(Icons.label_outline))),
        const SizedBox(height: 12),
        TextFormField(controller: _direccionCtrl, style: PeraCoText.body(context), maxLines: 2,
            validator: (v) => v == null || v.isEmpty ? 'Direccion requerida' : null,
            decoration: const InputDecoration(hintText: 'Direccion completa', prefixIcon: Icon(Icons.location_on_outlined), alignLabelWithHint: true)),
        const SizedBox(height: 12),
        TextFormField(controller: _ciudadCtrl, style: PeraCoText.body(context),
            validator: (v) => v == null || v.isEmpty ? 'Ciudad requerida' : null,
            decoration: const InputDecoration(hintText: 'Ciudad', prefixIcon: Icon(Icons.location_city_outlined))),
        const SizedBox(height: 12),
        SwitchListTile(
            title: Text('Direccion principal', style: PeraCoText.body(context)),
            subtitle: Text('Se usara por defecto en tus pedidos', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
            value: _esPrincipal, activeColor: PeraCoColors.primary,
            onChanged: (v) => setState(() => _esPrincipal = v),
            contentPadding: EdgeInsets.zero),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              : Text(isEditing ? 'Guardar cambios' : 'Agregar direccion'),
        )),
      ]))),
    );
  }
}
