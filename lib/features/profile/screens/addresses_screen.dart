import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/core/config/supabase_config.dart';
import 'package:peraco/features/auth/providers/auth_provider.dart';

class Address {
  final String id;
  final String nombre;
  final String direccion;
  final String ciudad;
  final bool esPrincipal;

  Address({required this.id, required this.nombre, required this.direccion, required this.ciudad, this.esPrincipal = false});

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      id: map['id'] as String,
      nombre: map['nombre'] as String? ?? 'Sin nombre',
      direccion: map['direccion'] as String? ?? '',
      ciudad: map['ciudad'] as String? ?? '',
      esPrincipal: map['es_principal'] as bool? ?? false,
    );
  }
}

class AddressesNotifier extends StateNotifier<AsyncValue<List<Address>>> {
  final Ref ref;
  AddressesNotifier(this.ref) : super(const AsyncValue.loading()) { load(); }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final userId = ref.read(authProvider).user?.id;
      if (userId == null) { state = const AsyncValue.data([]); return; }
      final data = await SupabaseConfig.client.from('direcciones')
          .select().eq('usuario_id', userId).order('es_principal', ascending: false);
      state = AsyncValue.data((data as List).map((e) => Address.fromMap(e)).toList());
    } catch (e, st) {
      print('ERROR DIRECCIONES: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> add({required String nombre, required String direccion, required String ciudad, bool esPrincipal = false}) async {
    try {
      final userId = ref.read(authProvider).user?.id;
      if (userId == null) return false;
      if (esPrincipal) {
        await SupabaseConfig.client.from('direcciones').update({'es_principal': false}).eq('usuario_id', userId);
      }
      await SupabaseConfig.client.from('direcciones').insert({
        'usuario_id': userId, 'nombre': nombre.trim(), 'direccion': direccion.trim(),
        'ciudad': ciudad.trim(), 'es_principal': esPrincipal,
      });
      await load();
      return true;
    } catch (e) { print('ERROR ADD DIR: $e'); return false; }
  }

  Future<bool> update({required String id, required String nombre, required String direccion, required String ciudad, bool esPrincipal = false}) async {
    try {
      final userId = ref.read(authProvider).user?.id;
      if (esPrincipal) {
        await SupabaseConfig.client.from('direcciones').update({'es_principal': false}).eq('usuario_id', userId!);
      }
      await SupabaseConfig.client.from('direcciones').update({
        'nombre': nombre.trim(), 'direccion': direccion.trim(),
        'ciudad': ciudad.trim(), 'es_principal': esPrincipal,
      }).eq('id', id);
      await load();
      return true;
    } catch (e) { print('ERROR UPDATE DIR: $e'); return false; }
  }

  Future<bool> delete(String id) async {
    try {
      await SupabaseConfig.client.from('direcciones').delete().eq('id', id);
      await load();
      return true;
    } catch (e) { return false; }
  }

  Future<bool> setPrincipal(String id) async {
    try {
      final userId = ref.read(authProvider).user?.id;
      await SupabaseConfig.client.from('direcciones').update({'es_principal': false}).eq('usuario_id', userId!);
      await SupabaseConfig.client.from('direcciones').update({'es_principal': true}).eq('id', id);
      await load();
      return true;
    } catch (e) { return false; }
  }
}

final addressesProvider = StateNotifierProvider<AddressesNotifier, AsyncValue<List<Address>>>((ref) {
  return AddressesNotifier(ref);
});

class AddressesScreen extends ConsumerWidget {
  const AddressesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final addressesAsync = ref.watch(addressesProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Mis Direcciones', style: PeraCoText.h3(context))),
      body: addressesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 48, color: PeraCoColors.error),
          const SizedBox(height: 12),
          Text('Error al cargar', style: PeraCoText.body(context)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: () => ref.read(addressesProvider.notifier).load(), child: const Text('Reintentar')),
        ])),
        data: (addresses) {
          if (addresses.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.location_off_outlined, size: 72, color: PeraCoColors.primaryLight.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text('Sin direcciones', style: PeraCoText.body(context).copyWith(color: PeraCoColors.textSecondary)),
              const SizedBox(height: 8),
              Text('Agrega tu primera direccion de entrega', style: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.textHint)),
              const SizedBox(height: 20),
              ElevatedButton.icon(onPressed: () => _showForm(context, ref),
                  icon: const Icon(Icons.add_location_alt, size: 20), label: const Text('Agregar direccion')),
            ]));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(addressesProvider.notifier).load(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 80),
              itemCount: addresses.length,
              itemBuilder: (ctx, i) => _AddressCard(address: addresses[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(context, ref),
        backgroundColor: PeraCoColors.primary,
        icon: const Icon(Icons.add_location_alt, color: Colors.white),
        label: Text('Agregar', style: PeraCoText.button(context).copyWith(color: Colors.white)),
      ),
    );
  }

  void _showForm(BuildContext context, WidgetRef ref, {Address? address}) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (_) => _AddressFormSheet(address: address));
  }
}

class _AddressCard extends ConsumerWidget {
  final Address address;
  const _AddressCard({required this.address});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: address.esPrincipal ? PeraCoColors.primary.withOpacity(0.3) : PeraCoColors.divider)),
      child: Row(children: [
        Container(width: 48, height: 48,
            decoration: BoxDecoration(
                color: address.esPrincipal ? PeraCoColors.primary.withOpacity(0.1) : PeraCoColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(
                address.nombre.toLowerCase().contains('casa') ? Icons.home_outlined
                    : address.nombre.toLowerCase().contains('oficina') ? Icons.work_outlined
                    : address.nombre.toLowerCase().contains('trabajo') ? Icons.work_outlined
                    : Icons.location_on_outlined,
                color: address.esPrincipal ? PeraCoColors.primary : PeraCoColors.textSecondary, size: 24)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(address.nombre, style: PeraCoText.bodyBold(context)),
            if (address.esPrincipal) ...[
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: PeraCoColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                  child: Text('Principal', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.primary, fontSize: 10, fontWeight: FontWeight.w600))),
            ],
          ]),
          const SizedBox(height: 2),
          Text(address.direccion, style: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
          if (address.ciudad.isNotEmpty)
            Text(address.ciudad, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textHint)),
        ])),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: PeraCoColors.textHint),
          onSelected: (val) async {
            if (val == 'edit') {
              showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                  builder: (_) => _AddressFormSheet(address: address));
            } else if (val == 'principal') {
              await ref.read(addressesProvider.notifier).setPrincipal(address.id);
            } else if (val == 'delete') {
              final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                  title: const Text('Eliminar direccion'),
                  content: Text('Eliminar "${address.nombre}"?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Eliminar', style: TextStyle(color: PeraCoColors.error))),
                  ]));
              if (confirm == true) await ref.read(addressesProvider.notifier).delete(address.id);
            }
          },
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Editar')])),
            if (!address.esPrincipal)
              const PopupMenuItem(value: 'principal', child: Row(children: [Icon(Icons.star_outline, size: 18), SizedBox(width: 8), Text('Hacer principal')])),
            const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 18, color: PeraCoColors.error), SizedBox(width: 8), Text('Eliminar', style: TextStyle(color: PeraCoColors.error))])),
          ],
        ),
      ]),
    );
  }
}

class _AddressFormSheet extends ConsumerStatefulWidget {
  final Address? address;
  const _AddressFormSheet({this.address});
  @override
  ConsumerState<_AddressFormSheet> createState() => _AddressFormSheetState();
}

class _AddressFormSheetState extends ConsumerState<_AddressFormSheet> {
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
    _nombreCtrl = TextEditingController(text: widget.address?.nombre ?? '');
    _direccionCtrl = TextEditingController(text: widget.address?.direccion ?? '');
    _ciudadCtrl = TextEditingController(text: widget.address?.ciudad ?? '');
    _esPrincipal = widget.address?.esPrincipal ?? false;
  }

  @override
  void dispose() { _nombreCtrl.dispose(); _direccionCtrl.dispose(); _ciudadCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    final notifier = ref.read(addressesProvider.notifier);
    bool success;

    if (widget.address != null) {
      success = await notifier.update(id: widget.address!.id,
          nombre: _nombreCtrl.text, direccion: _direccionCtrl.text,
          ciudad: _ciudadCtrl.text, esPrincipal: _esPrincipal);
    } else {
      success = await notifier.add(
          nombre: _nombreCtrl.text, direccion: _direccionCtrl.text,
          ciudad: _ciudadCtrl.text, esPrincipal: _esPrincipal);
    }

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

        // Chips de sugerencia para nombre
        if (!isEditing) ...[
          Wrap(spacing: 8, runSpacing: 8, children: _sugerencias.map((s) => GestureDetector(
            onTap: () => setState(() => _nombreCtrl.text = s),
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: _nombreCtrl.text == s ? PeraCoColors.primary.withOpacity(0.1) : PeraCoColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _nombreCtrl.text == s ? PeraCoColors.primary : PeraCoColors.divider)),
                child: Text(s, style: PeraCoText.caption(context).copyWith(
                    color: _nombreCtrl.text == s ? PeraCoColors.primary : PeraCoColors.textSecondary, fontWeight: FontWeight.w500))),
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