import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/core/config/supabase_config.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/features/auth/providers/auth_provider.dart';

class VehicleInfoSheet extends ConsumerStatefulWidget {
  const VehicleInfoSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => const VehicleInfoSheet(),
    );
  }

  @override
  ConsumerState<VehicleInfoSheet> createState() => _VehicleInfoSheetState();
}

class _VehicleInfoSheetState extends ConsumerState<VehicleInfoSheet> {
  final _tipoCtrl  = TextEditingController();
  final _placaCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final userId = ref.read(authProvider).user!.id;
    SupabaseConfig.client.from('info_peragoger').select().eq('usuario_id', userId).single().then((data) {
      if (mounted) {
        _tipoCtrl.text  = data['tipo_vehiculo'] as String? ?? '';
        _placaCtrl.text = data['placa']         as String? ?? '';
      }
    });
  }

  @override
  void dispose() { _tipoCtrl.dispose(); _placaCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: PeraCoColors.divider, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Text('Mi Vehiculo', style: PeraCoText.h3(context)),
        const SizedBox(height: 20),
        TextField(controller: _tipoCtrl, style: PeraCoText.body(context),
            decoration: const InputDecoration(hintText: 'Tipo de vehiculo', prefixIcon: Icon(Icons.two_wheeler_outlined))),
        const SizedBox(height: 12),
        TextField(controller: _placaCtrl, style: PeraCoText.body(context),
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: 'Placa', prefixIcon: Icon(Icons.confirmation_number_outlined))),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
          onPressed: _loading ? null : () async {
            setState(() => _loading = true);
            try {
              final userId = ref.read(authProvider).user!.id;
              await SupabaseConfig.client.from('info_peragoger').update({
                'tipo_vehiculo': _tipoCtrl.text.trim(),
                'placa': _placaCtrl.text.trim().toUpperCase(),
              }).eq('usuario_id', userId);
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Vehiculo actualizado'),
                    backgroundColor: PeraCoColors.success, behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
              }
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: PeraCoColors.error));
            }
            if (mounted) setState(() => _loading = false);
          },
          child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              : const Text('Guardar'),
        )),
      ]),
    );
  }
}
