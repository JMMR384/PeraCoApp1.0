import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/core/router/app_router.dart';
import 'package:peraco/core/utils/validators.dart';
import 'package:peraco/features/auth/providers/auth_provider.dart';

class SignupFarmerScreen extends ConsumerStatefulWidget {
  const SignupFarmerScreen({super.key});
  @override
  ConsumerState<SignupFarmerScreen> createState() => _SignupFarmerScreenState();
}

class _SignupFarmerScreenState extends ConsumerState<SignupFarmerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;

  String _sellerType = 'productor'; // 'productor' o 'comerciante'

  @override
  void dispose() {
    _nameCtrl.dispose(); _lastNameCtrl.dispose(); _emailCtrl.dispose();
    _phoneCtrl.dispose(); _passCtrl.dispose(); _confirmPassCtrl.dispose();
    _businessNameCtrl.dispose(); _locationCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Las contrasenas no coinciden'), backgroundColor: PeraCoColors.error,
          behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      return;
    }
    final success = await ref.read(authProvider.notifier).signUpFarmer(
      email: _emailCtrl.text, password: _passCtrl.text,
      nombre: _nameCtrl.text, apellido: _lastNameCtrl.text,
      telefono: _phoneCtrl.text, nombreFinca: _businessNameCtrl.text,
      ubicacion: _locationCtrl.text,
      tipoVendedor: _sellerType,
    );
    if (success && mounted) context.go(AppRoutes.farmerDashboard);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(next.errorMessage!), backgroundColor: PeraCoColors.error,
            behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      }
    });
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white,
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Crear Cuenta', style: PeraCoText.h1(context)),
                const SizedBox(height: 4),
                Text('Vende tus productos frescos', style: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.textSecondary)),
                const SizedBox(height: 20),

                // Selector de tipo
                Row(children: [
                  Expanded(child: _TypeCard(
                    icon: Icons.agriculture,
                    label: 'Productor',
                    subtitle: 'Vende lo que cultivas',
                    selected: _sellerType == 'productor',
                    onTap: () => setState(() => _sellerType = 'productor'),
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _TypeCard(
                    icon: Icons.storefront,
                    label: 'Comerciante',
                    subtitle: 'Vende en plaza',
                    selected: _sellerType == 'comerciante',
                    onTap: () => setState(() => _sellerType = 'comerciante'),
                  )),
                ]),
                const SizedBox(height: 20),

                // Campos personales
                Row(children: [
                  Expanded(child: TextFormField(controller: _nameCtrl, textInputAction: TextInputAction.next,
                      validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null, style: PeraCoText.body(context),
                      decoration: const InputDecoration(hintText: 'Nombre'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _lastNameCtrl, textInputAction: TextInputAction.next,
                      validator: (v) => v == null || v.isEmpty ? 'Campo requerido' : null, style: PeraCoText.body(context),
                      decoration: const InputDecoration(hintText: 'Apellido'))),
                ]),
                const SizedBox(height: 14),
                TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next, validator: AppValidators.email,
                    style: PeraCoText.body(context),
                    decoration: const InputDecoration(hintText: 'Correo electronico', prefixIcon: Icon(Icons.mail_outline))),
                const SizedBox(height: 14),
                TextFormField(controller: _phoneCtrl, keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next, style: PeraCoText.body(context),
                    decoration: const InputDecoration(hintText: 'Telefono', prefixIcon: Icon(Icons.phone_outlined))),
                const SizedBox(height: 14),

                // Campos del negocio
                TextFormField(controller: _businessNameCtrl, textInputAction: TextInputAction.next,
                    style: PeraCoText.body(context),
                    decoration: InputDecoration(
                        hintText: _sellerType == 'productor' ? 'Nombre de la finca' : 'Nombre del negocio',
                        prefixIcon: Icon(_sellerType == 'productor' ? Icons.agriculture : Icons.storefront))),
                const SizedBox(height: 14),
                TextFormField(controller: _locationCtrl, textInputAction: TextInputAction.next,
                    style: PeraCoText.body(context),
                    decoration: InputDecoration(
                        hintText: _sellerType == 'productor' ? 'Ubicacion de la finca' : 'Ubicacion del negocio',
                        prefixIcon: const Icon(Icons.location_on_outlined))),
                const SizedBox(height: 14),

                // Contrasena
                TextFormField(controller: _passCtrl, obscureText: _obscure,
                    textInputAction: TextInputAction.next, validator: AppValidators.password,
                    style: PeraCoText.body(context),
                    decoration: InputDecoration(hintText: 'Contrasena', prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setState(() => _obscure = !_obscure)))),
                const SizedBox(height: 14),
                TextFormField(controller: _confirmPassCtrl, obscureText: _obscureConfirm,
                    textInputAction: TextInputAction.done, style: PeraCoText.body(context),
                    validator: (v) => v != _passCtrl.text ? 'Las contrasenas no coinciden' : null,
                    decoration: InputDecoration(hintText: 'Confirmar contrasena', prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)))),
                const SizedBox(height: 24),

                // Boton crear cuenta
                SizedBox(width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _handleSignup,
                    child: isLoading
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                        : const Text('Crear Cuenta'),
                  ),
                ),
                const SizedBox(height: 16),

                // Link a login
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Ya tienes cuenta? ', style: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.textSecondary)),
                  GestureDetector(
                    onTap: () => context.go(AppRoutes.login),
                    child: Text('Iniciar Sesion', style: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.primary, fontWeight: FontWeight.w600)),
                  ),
                ]),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final IconData icon; final String label; final String subtitle;
  final bool selected; final VoidCallback onTap;
  const _TypeCard({required this.icon, required this.label, required this.subtitle,
    required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: selected ? PeraCoColors.greenPastel : PeraCoColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? PeraCoColors.primary : Colors.transparent, width: 2),
        ),
        child: Column(children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
                color: selected ? PeraCoColors.primary.withOpacity(0.15) : Colors.white,
                shape: BoxShape.circle),
            child: Icon(icon, color: selected ? PeraCoColors.primary : PeraCoColors.textSecondary, size: 26),
          ),
          const SizedBox(height: 10),
          Text(label, style: PeraCoText.bodyBold(context).copyWith(
              color: selected ? PeraCoColors.primaryDark : PeraCoColors.textPrimary)),
          const SizedBox(height: 2),
          Text(subtitle, style: PeraCoText.caption(context).copyWith(
              color: selected ? PeraCoColors.primary : PeraCoColors.textSecondary),
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}