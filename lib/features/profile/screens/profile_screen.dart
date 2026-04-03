import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/core/config/supabase_config.dart';
import 'package:peraco/core/router/app_router.dart';
import 'package:peraco/features/auth/providers/auth_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String? _avatarUrl;
  bool _loadingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadAvatar();
  }

  Future<void> _loadAvatar() async {
    try {
      final userId = ref.read(authProvider).user?.id;
      if (userId == null) return;
      final data = await SupabaseConfig.client
          .from('usuarios')
          .select('avatar_url')
          .eq('id', userId)
          .single();
      if (mounted) setState(() => _avatarUrl = data['avatar_url'] as String?);
    } catch (_) {}
  }

  Future<void> _changeAvatar() async {
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
    final picked = await picker.pickImage(source: source, maxWidth: 400, maxHeight: 400, imageQuality: 80);
    if (picked == null) return;

    setState(() => _loadingAvatar = true);
    try {
      final userId = ref.read(authProvider).user?.id;
      final ext = picked.path.split('.').last;
      final path = '$userId.$ext';
      await SupabaseConfig.client.storage.from('avatars').upload(
          path, File(picked.path), fileOptions: FileOptions(upsert: true));
      final url = SupabaseConfig.client.storage.from('avatars').getPublicUrl(path);
      await SupabaseConfig.client.from('usuarios').update({'avatar_url': url}).eq('id', userId!);
      setState(() { _avatarUrl = url; _loadingAvatar = false; });
    } catch (e) {
      print('ERROR AVATAR: $e');
      setState(() => _loadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final name = auth.userName ?? 'Usuario';
    final role = auth.role;

    String rolLabel;
    IconData rolIcon;
    Color rolColor;
    switch (role) {
      case UserRole.clienteB2C:
        rolLabel = 'Cuenta Personal'; rolIcon = Icons.person; rolColor = PeraCoColors.primary;
      case UserRole.clienteB2B:
        rolLabel = 'Cuenta Negocio'; rolIcon = Icons.business; rolColor = PeraCoColors.info;
      case UserRole.agricultor:
        rolLabel = 'Productor'; rolIcon = Icons.grass; rolColor = PeraCoColors.primaryLight;
      case UserRole.comerciante:
        rolLabel = 'Comerciante'; rolIcon = Icons.store; rolColor = PeraCoColors.warning;
      case UserRole.peragoger:
        rolLabel = 'PeraGoger'; rolIcon = Icons.delivery_dining; rolColor = PeraCoColors.primary;
      default:
        rolLabel = 'Usuario'; rolIcon = Icons.person; rolColor = PeraCoColors.primary;
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(20), children: [
          // Header con avatar
          Center(child: Column(children: [
            GestureDetector(
              onTap: _changeAvatar,
              child: Stack(children: [
                CircleAvatar(radius: 48, backgroundColor: PeraCoColors.greenPastel,
                    backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                    child: _loadingAvatar
                        ? const CircularProgressIndicator(strokeWidth: 2)
                        : _avatarUrl == null
                        ? Text(name[0].toUpperCase(), style: PeraCoText.h1(context).copyWith(color: PeraCoColors.primary))
                        : null),
                Positioned(bottom: 0, right: 0,
                    child: Container(width: 30, height: 30,
                        decoration: BoxDecoration(color: PeraCoColors.primary, shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2)),
                        child: const Icon(Icons.camera_alt, color: Colors.white, size: 14))),
              ]),
            ),
            const SizedBox(height: 14),
            Text(name, style: PeraCoText.h2(context)),
            const SizedBox(height: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(color: rolColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(rolIcon, size: 14, color: rolColor),
                  const SizedBox(width: 6),
                  Text(rolLabel, style: PeraCoText.caption(context).copyWith(color: rolColor, fontWeight: FontWeight.w600)),
                ])),
            const SizedBox(height: 6),
            Text(auth.user?.email ?? '', style: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.textSecondary)),
          ])),

          const SizedBox(height: 28),

          // Menu segun rol
          if (role == UserRole.clienteB2C || role == UserRole.clienteB2B) ...[
            _SectionTitle(title: 'Mi cuenta'),
            const SizedBox(height: 8),
            _MenuItem(icon: Icons.receipt_long_outlined, title: 'Mis Pedidos', subtitle: 'Historial y seguimiento',
                onTap: () => context.go(AppRoutes.clientOrders)),
            _MenuItem(icon: Icons.location_on_outlined, title: 'Mis Direcciones', subtitle: 'Direcciones de entrega',
                onTap: () => context.push(AppRoutes.addresses)),
            _MenuItem(icon: Icons.payment_outlined, title: 'Metodos de Pago', subtitle: 'Tarjetas y cuentas',
                onTap: () => _showComingSoon(context, 'Metodos de Pago')),
            if (role == UserRole.clienteB2B)
              _MenuItem(icon: Icons.description_outlined, title: 'Info Fiscal', subtitle: 'NIT, razon social',
                  onTap: () => context.push(AppRoutes.fiscal)),
          ],

          if (role == UserRole.agricultor || role == UserRole.comerciante) ...[
            _SectionTitle(title: 'Mi negocio'),
            const SizedBox(height: 8),
            _MenuItem(icon: Icons.inventory_2_outlined, title: 'Mis Productos', subtitle: 'Gestionar catalogo',
                onTap: () => context.go('/farmer/products')),
            _MenuItem(icon: Icons.receipt_long_outlined, title: 'Mis Ventas', subtitle: 'Pedidos recibidos',
                onTap: () => context.go('/farmer/orders')),
            _MenuItem(icon: Icons.store_outlined, title: 'Mi Tienda', subtitle: 'Nombre, ubicacion, tipo',
                onTap: () => _showEditStore(context)),
          ],

          if (role == UserRole.peragoger) ...[
            _SectionTitle(title: 'Mi trabajo'),
            const SizedBox(height: 8),
            _MenuItem(icon: Icons.local_shipping_outlined, title: 'Mis Entregas', subtitle: 'Historial de entregas',
                onTap: () => context.go('/driver/history')),
            _MenuItem(icon: Icons.two_wheeler_outlined, title: 'Mi Vehiculo', subtitle: 'Tipo y placa',
                onTap: () => _showVehicleInfo(context)),
          ],

          const SizedBox(height: 20),
          _SectionTitle(title: 'General'),
          const SizedBox(height: 8),
          _MenuItem(icon: Icons.person_outline, title: 'Editar Perfil', subtitle: 'Nombre, telefono',
              onTap: () => _showEditProfile(context)),
          _MenuItem(icon: Icons.lock_outline, title: 'Cambiar Contrasena', subtitle: 'Actualizar contrasena',
              onTap: () => _showChangePassword(context)),
          _MenuItem(icon: Icons.help_outline, title: 'Ayuda', subtitle: 'Preguntas frecuentes, contacto',
              onTap: () => _showHelp(context)),
          _MenuItem(icon: Icons.info_outline, title: 'Acerca de PeraCo', subtitle: 'Version 1.0.0',
              onTap: () {}),

          const SizedBox(height: 24),
          Center(child: TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
                  title: Text('Cerrar Sesion', style: PeraCoText.h3(context)),
                  content: const Text('Seguro que quieres cerrar sesion?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Cerrar Sesion', style: TextStyle(color: PeraCoColors.error))),
                  ]));
              if (confirm == true) {
                await ref.read(authProvider.notifier).signOut();
                if (context.mounted) context.go(AppRoutes.welcome);
              }
            },
            child: Text('Cerrar Sesion', style: PeraCoText.bodyBold(context).copyWith(color: PeraCoColors.error)),
          )),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$feature - Proximamente'), behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }

  void _showEditProfile(BuildContext context) {
    final auth = ref.read(authProvider);
    final nombreCtrl = TextEditingController(text: auth.userName ?? '');
    final telefonoCtrl = TextEditingController();

    // Cargar telefono actual
    SupabaseConfig.client.from('usuarios').select('telefono').eq('id', auth.user!.id).single().then((data) {
      telefonoCtrl.text = data['telefono'] as String? ?? '';
    });

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (_) => Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: PeraCoColors.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Editar Perfil', style: PeraCoText.h3(context)),
            const SizedBox(height: 20),
            TextField(controller: nombreCtrl, style: PeraCoText.body(context),
                decoration: const InputDecoration(hintText: 'Nombre', prefixIcon: Icon(Icons.person_outline))),
            const SizedBox(height: 12),
            TextField(controller: telefonoCtrl, style: PeraCoText.body(context),
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(hintText: 'Telefono', prefixIcon: Icon(Icons.phone_outlined))),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
              onPressed: () async {
                await SupabaseConfig.client.from('usuarios').update({
                  'nombre': nombreCtrl.text.trim(),
                  'telefono': telefonoCtrl.text.trim(),
                }).eq('id', auth.user!.id);
                await ref.read(authProvider.notifier).checkCurrentSession();
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Perfil actualizado'),
                      backgroundColor: PeraCoColors.success, behavior: SnackBarBehavior.floating,
                      margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
                }
              },
              child: const Text('Guardar'),
            )),
          ]),
        ));
  }

  void _showChangePassword(BuildContext context) {
    final passCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();

    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (_) => Container(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: PeraCoColors.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Cambiar Contrasena', style: PeraCoText.h3(context)),
            const SizedBox(height: 20),
            TextField(controller: passCtrl, obscureText: true, style: PeraCoText.body(context),
                decoration: const InputDecoration(hintText: 'Nueva contrasena', prefixIcon: Icon(Icons.lock_outline))),
            const SizedBox(height: 12),
            TextField(controller: confirmCtrl, obscureText: true, style: PeraCoText.body(context),
                decoration: const InputDecoration(hintText: 'Confirmar contrasena', prefixIcon: Icon(Icons.lock_outline))),
            const SizedBox(height: 20),
            SizedBox(width: double.infinity, height: 52, child: ElevatedButton(
              onPressed: () async {
                if (passCtrl.text.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimo 6 caracteres')));
                  return;
                }
                if (passCtrl.text != confirmCtrl.text) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Las contrasenas no coinciden')));
                  return;
                }
                try {
                  await SupabaseConfig.client.auth.updateUser(UserAttributes(password: passCtrl.text));
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Contrasena actualizada'),
                        backgroundColor: PeraCoColors.success, behavior: SnackBarBehavior.floating,
                        margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: PeraCoColors.error));
                }
              },
              child: const Text('Cambiar Contrasena'),
            )),
          ]),
        ));
  }

  void _showEditStore(BuildContext context) {
    _showComingSoon(context, 'Mi Tienda');
  }

  void _showVehicleInfo(BuildContext context) {
    _showComingSoon(context, 'Mi Vehiculo');
  }

  void _showHelp(BuildContext context) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => Container(
          height: MediaQuery.of(context).size.height * 0.55,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: PeraCoColors.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Text('Ayuda', style: PeraCoText.h3(context)),
            const SizedBox(height: 16),
            Expanded(child: ListView(children: [
              _HelpItem(icon: Icons.email_outlined, title: 'Correo', subtitle: 'soporte@peraco.com'),
              _HelpItem(icon: Icons.phone_outlined, title: 'Telefono', subtitle: '+57 300 000 0000'),
              _HelpItem(icon: Icons.chat_outlined, title: 'WhatsApp', subtitle: '+57 300 000 0000'),
              const SizedBox(height: 12),
              _HelpItem(icon: Icons.question_answer_outlined, title: 'Preguntas Frecuentes', subtitle: 'Respuestas rapidas'),
              _HelpItem(icon: Icons.policy_outlined, title: 'Terminos y Condiciones', subtitle: 'Politicas de uso'),
              _HelpItem(icon: Icons.privacy_tip_outlined, title: 'Politica de Privacidad', subtitle: 'Proteccion de datos'),
            ])),
            const SizedBox(height: 8),
            Text('PeraCo v1.0.0', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textHint)),
            Text('Del campo a tu mesa', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textHint, fontStyle: FontStyle.italic)),
          ]),
        ));
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.only(top: 8),
        child: Text(title, style: PeraCoText.bodyBold(context).copyWith(color: PeraCoColors.textSecondary)));
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon; final String title; final String subtitle; final VoidCallback onTap;
  const _MenuItem({required this.icon, required this.title, required this.subtitle, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12),
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(children: [
              Container(width: 44, height: 44,
                  decoration: BoxDecoration(color: PeraCoColors.greenPastel, borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: PeraCoColors.primary, size: 22)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: PeraCoText.bodyBold(context)),
                Text(subtitle, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
              ])),
              const Icon(Icons.chevron_right, color: PeraCoColors.textHint, size: 22),
            ])));
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon; final String title; final String subtitle;
  const _HelpItem({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(children: [
          Icon(icon, color: PeraCoColors.primary, size: 22),
          const SizedBox(width: 14),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: PeraCoText.bodyBold(context)),
            Text(subtitle, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
          ]),
        ]));
  }
}