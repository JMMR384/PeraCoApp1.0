import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/core/config/supabase_config.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/features/auth/providers/auth_provider.dart';

class EditProfileSheet extends ConsumerStatefulWidget {
  const EditProfileSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => const EditProfileSheet(),
    );
  }

  @override
  ConsumerState<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<EditProfileSheet> {
  final _nombreCtrl   = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    _nombreCtrl.text = auth.userName ?? '';
    SupabaseConfig.client.from('usuarios').select('telefono').eq('id', auth.user!.id).single().then((data) {
      if (mounted) _telefonoCtrl.text = data['telefono'] as String? ?? '';
    });
  }

  @override
  void dispose() { _nombreCtrl.dispose(); _telefonoCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: PeraCoColors.divider, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Text('Editar Perfil', style: PeraCoText.h3(context)),
        const SizedBox(height: 20),
        TextField(controller: _nombreCtrl, style: PeraCoText.body(context),
            decoration: const InputDecoration(hintText: 'Nombre', prefixIcon: Icon(Icons.person_outline))),
        const SizedBox(height: 12),
        TextField(controller: _telefonoCtrl, style: PeraCoText.body(context),
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: 'Telefono', prefixIcon: Icon(Icons.phone_outlined))),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
          onPressed: _loading ? null : () async {
            setState(() => _loading = true);
            final userId = ref.read(authProvider).user!.id;
            await SupabaseConfig.client.from('usuarios').update({
              'nombre': _nombreCtrl.text.trim(), 'telefono': _telefonoCtrl.text.trim(),
            }).eq('id', userId);
            await ref.read(authProvider.notifier).checkCurrentSession();
            setState(() => _loading = false);
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Perfil actualizado'),
                  backgroundColor: PeraCoColors.success, behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
            }
          },
          child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              : const Text('Guardar'),
        )),
      ]),
    );
  }
}
