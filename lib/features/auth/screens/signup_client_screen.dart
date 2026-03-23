import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/router/app_router.dart';
import 'package:peraco/core/utils/validators.dart';
import 'package:peraco/features/auth/providers/auth_provider.dart';

class SignupClientScreen extends ConsumerStatefulWidget {
  const SignupClientScreen({super.key});
  @override
  ConsumerState<SignupClientScreen> createState() => _SignupClientScreenState();
}

class _SignupClientScreenState extends ConsumerState<SignupClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController(); final _apellido = TextEditingController();
  final _email = TextEditingController(); final _telefono = TextEditingController();
  final _pass = TextEditingController(); final _confirmPass = TextEditingController();
  bool _obscure1 = true; bool _obscure2 = true; String _tipo = 'B2C';

  @override
  void dispose() { _nombre.dispose(); _apellido.dispose(); _email.dispose(); _telefono.dispose(); _pass.dispose(); _confirmPass.dispose(); super.dispose(); }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).signUpClient(
      email: _email.text, password: _pass.text, nombre: _nombre.text,
      apellido: _apellido.text, tipoCliente: _tipo,
      telefono: _telefono.text.isNotEmpty ? _telefono.text : null,
    );
    if (success && mounted) context.go(AppRoutes.clientHome);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    ref.listen<AuthState>(authProvider, (p, n) {
      if (n.status == AuthStatus.error && n.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(n.errorMessage!), backgroundColor: PeraCoColors.error,
          behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      }
    });
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop())),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        Text('Crear Cuenta', style: Theme.of(context).textTheme.headlineMedium?.copyWith(color: PeraCoColors.textPrimary)),
        const SizedBox(height: 4),
        Text('Compra productos frescos y locales', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: PeraCoColors.textSecondary)),
        const SizedBox(height: 24),
        // Selector B2C/B2B
        Row(children: [
          Expanded(child: _TypeCard(selected: _tipo == 'B2C', icon: Icons.person_outline, title: 'Persona', sub: 'Compra para ti', onTap: () => setState(() => _tipo = 'B2C'))),
          const SizedBox(width: 12),
          Expanded(child: _TypeCard(selected: _tipo == 'B2B', icon: Icons.storefront_outlined, title: 'Negocio', sub: 'Compra al mayor', onTap: () => setState(() => _tipo = 'B2B'))),
        ]),
        const SizedBox(height: 24),
        Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Expanded(child: TextFormField(controller: _nombre, textCapitalization: TextCapitalization.words, textInputAction: TextInputAction.next, validator: (v) => AppValidators.required(v, 'Nombre'), decoration: const InputDecoration(hintText: 'Nombre'))),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(controller: _apellido, textCapitalization: TextCapitalization.words, textInputAction: TextInputAction.next, validator: (v) => AppValidators.required(v, 'Apellido'), decoration: const InputDecoration(hintText: 'Apellido'))),
          ]),
          const SizedBox(height: 16),
          TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next, validator: AppValidators.email, autovalidateMode: AutovalidateMode.onUserInteraction, decoration: const InputDecoration(hintText: 'Correo electronico', prefixIcon: Icon(Icons.mail_outline))),
          const SizedBox(height: 16),
          TextFormField(controller: _telefono, keyboardType: TextInputType.phone, textInputAction: TextInputAction.next, validator: AppValidators.phone, decoration: const InputDecoration(hintText: 'Telefono (opcional)', prefixIcon: Icon(Icons.phone_outlined))),
          const SizedBox(height: 16),
          TextFormField(controller: _pass, obscureText: _obscure1, textInputAction: TextInputAction.next, validator: AppValidators.password, autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(hintText: 'Contrasena', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_obscure1 ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => _obscure1 = !_obscure1)))),
          const SizedBox(height: 16),
          TextFormField(controller: _confirmPass, obscureText: _obscure2, textInputAction: TextInputAction.done, validator: (v) => AppValidators.confirmPassword(v, _pass.text), autovalidateMode: AutovalidateMode.onUserInteraction, onFieldSubmitted: (_) => _handleSignup(),
            decoration: InputDecoration(hintText: 'Confirmar contrasena', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_obscure2 ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => _obscure2 = !_obscure2)))),
          const SizedBox(height: 32),
          ElevatedButton(onPressed: isLoading ? null : _handleSignup, child: isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : const Text('Crear Cuenta')),
        ])),
        const SizedBox(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('Ya tienes cuenta? ', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: PeraCoColors.textSecondary)),
          GestureDetector(onTap: () { context.pop(); context.push(AppRoutes.login); },
            child: Text('Iniciar Sesion', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: PeraCoColors.primary, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 32),
      ]))),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final bool selected; final IconData icon; final String title; final String sub; final VoidCallback onTap;
  const _TypeCard({required this.selected, required this.icon, required this.title, required this.sub, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: AnimatedContainer(duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(color: selected ? PeraCoColors.greenPastel : PeraCoColors.surfaceVariant, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? PeraCoColors.primary : Colors.transparent, width: 2)),
      child: Column(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: selected ? PeraCoColors.primary.withOpacity(0.1) : Colors.white, shape: BoxShape.circle),
          child: Icon(icon, color: selected ? PeraCoColors.primary : PeraCoColors.textSecondary, size: 26)),
        const SizedBox(height: 10),
        Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: selected ? PeraCoColors.primaryDark : PeraCoColors.textPrimary)),
        const SizedBox(height: 2),
        Text(sub, style: TextStyle(fontSize: 12, color: selected ? PeraCoColors.primary : PeraCoColors.textSecondary)),
      ])));
  }
}
