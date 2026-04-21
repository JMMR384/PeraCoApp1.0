import 'package:flutter/material.dart';
import 'package:peraco/core/config/supabase_config.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (_) => const ChangePasswordSheet(),
    );
  }

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final _passCtrl    = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() { _passCtrl.dispose(); _confirmCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 40, height: 4, decoration: BoxDecoration(color: PeraCoColors.divider, borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 16),
        Text('Cambiar Contrasena', style: PeraCoText.h3(context)),
        const SizedBox(height: 20),
        TextField(controller: _passCtrl, obscureText: true, style: PeraCoText.body(context),
            decoration: const InputDecoration(hintText: 'Nueva contrasena', prefixIcon: Icon(Icons.lock_outline))),
        const SizedBox(height: 12),
        TextField(controller: _confirmCtrl, obscureText: true, style: PeraCoText.body(context),
            decoration: const InputDecoration(hintText: 'Confirmar contrasena', prefixIcon: Icon(Icons.lock_outline))),
        const SizedBox(height: 20),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
          onPressed: _loading ? null : () async {
            if (_passCtrl.text.length < 6) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimo 6 caracteres')));
              return;
            }
            if (_passCtrl.text != _confirmCtrl.text) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Las contrasenas no coinciden')));
              return;
            }
            setState(() => _loading = true);
            try {
              await SupabaseConfig.client.auth.updateUser(UserAttributes(password: _passCtrl.text));
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Contrasena actualizada'),
                    backgroundColor: PeraCoColors.success, behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
              }
            } catch (e) {
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: PeraCoColors.error));
            }
            if (mounted) setState(() => _loading = false);
          },
          child: _loading ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
              : const Text('Cambiar Contrasena'),
        )),
      ]),
    );
  }
}
