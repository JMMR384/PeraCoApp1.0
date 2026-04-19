import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/core/router/app_router.dart';
import 'package:peraco/core/utils/validators.dart';
import 'package:peraco/features/auth/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).signIn(email: _emailCtrl.text, password: _passCtrl.text);
    if (success && mounted) {
      final role = ref.read(authProvider).role;
      switch (role) {
        case UserRole.clienteB2C:
        case UserRole.clienteB2B:
          context.go(AppRoutes.clientHome);
        case UserRole.agricultor:
          context.go(AppRoutes.farmerDashboard);
        case UserRole.comerciante:
          context.go(AppRoutes.farmerDashboard);
        case UserRole.peragoger:
          context.go(AppRoutes.driverDeliveries);
        default:
          context.go(AppRoutes.clientHome);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    ref.listen<AuthState>(authProvider, (prev, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(next.errorMessage!), backgroundColor: PeraCoColors.error,
          behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      }
    });
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop())),
      body: SafeArea(
        child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(children: [
            const SizedBox(height: 10),
            Image.asset('assets/images/logo_original.png', width: 220, fit: BoxFit.contain),
            const SizedBox(height: 32),
            Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              TextFormField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.next,
                validator: AppValidators.email, autovalidateMode: AutovalidateMode.onUserInteraction,
                style: PeraCoText.body(context),
                decoration: const InputDecoration(hintText: 'Correo electronico', prefixIcon: Icon(Icons.mail_outline))),
              const SizedBox(height: 16),
              TextFormField(controller: _passCtrl, obscureText: _obscure, textInputAction: TextInputAction.done,
                validator: AppValidators.password, autovalidateMode: AutovalidateMode.onUserInteraction, onFieldSubmitted: (_) => _handleLogin(),
                style: PeraCoText.body(context),
                decoration: InputDecoration(hintText: 'Contrasena', prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => _obscure = !_obscure)))),
              const SizedBox(height: 8),
              Align(alignment: Alignment.centerRight, child: TextButton(
                onPressed: () { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Funcion disponible proximamente'),
                  backgroundColor: PeraCoColors.info, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))); },
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: Text('Olvidaste tu contrasena?', style: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.primary)))),
              const SizedBox(height: 28),
              ElevatedButton(onPressed: isLoading ? null : _handleLogin,
                child: isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                  : const Text('Iniciar Sesion')),
              const SizedBox(height: 16),
              Row(children: [
                const Expanded(child: Divider()),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('o', style: TextStyle(color: PeraCoColors.textHint))),
                const Expanded(child: Divider()),
              ]),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Google Login - Proximamente'),
                  backgroundColor: PeraCoColors.info,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                )),
                icon: Image.asset('assets/images/google_logo.png', width: 20, height: 20,
                  errorBuilder: (_, __, ___) => const Icon(Icons.g_mobiledata, size: 24)),
                label: const Text('Continuar con Google'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  side: const BorderSide(color: PeraCoColors.divider),
                  foregroundColor: PeraCoColors.textPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ])),
            const SizedBox(height: 32),
          ]),
        ),
      ),
    );
  }
}
