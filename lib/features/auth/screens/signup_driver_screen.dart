import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/router/app_router.dart';
import 'package:peraco/core/utils/validators.dart';
import 'package:peraco/features/auth/providers/auth_provider.dart';

class SignupDriverScreen extends ConsumerStatefulWidget {
  const SignupDriverScreen({super.key});
  @override
  ConsumerState<SignupDriverScreen> createState() => _SignupDriverScreenState();
}

class _SignupDriverScreenState extends ConsumerState<SignupDriverScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombre = TextEditingController(); final _apellido = TextEditingController();
  final _email = TextEditingController(); final _telefono = TextEditingController();
  final _pass = TextEditingController(); final _confirmPass = TextEditingController();
  final _placa = TextEditingController();
  bool _obscure1 = true; bool _obscure2 = true;
  String _vehiculo = 'moto';

  @override
  void dispose() { for (var c in [_nombre,_apellido,_email,_telefono,_pass,_confirmPass,_placa]) c.dispose(); super.dispose(); }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).signUpDriver(
      email: _email.text, password: _pass.text, nombre: _nombre.text,
      apellido: _apellido.text, tipoVehiculo: _vehiculo, placa: _placa.text,
      telefono: _telefono.text.isNotEmpty ? _telefono.text : null,
    );
    if (success && mounted) context.go(AppRoutes.driverDeliveries);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    ref.listen<AuthState>(authProvider, (p, n) {
      if (n.status == AuthStatus.error && n.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(n.errorMessage!), backgroundColor: PeraCoColors.error, behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      }
    });
    final isLoading = authState.status == AuthStatus.loading;
    final vehiculos = ['moto', 'bicicleta', 'auto', 'camioneta'];

    return Scaffold(backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop())),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 24), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 8),
        Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: PeraCoColors.primaryDark.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.local_shipping, color: PeraCoColors.primaryDark, size: 24)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Registro PeraGoger', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: PeraCoColors.textPrimary)),
            Text('Genera ingresos repartiendo', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: PeraCoColors.textSecondary)),
          ]),
        ]),
        const SizedBox(height: 28),
        Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('Datos personales', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PeraCoColors.textSecondary)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: TextFormField(controller: _nombre, textCapitalization: TextCapitalization.words, validator: (v) => AppValidators.required(v, 'Nombre'), decoration: const InputDecoration(hintText: 'Nombre'))),
            const SizedBox(width: 12),
            Expanded(child: TextFormField(controller: _apellido, textCapitalization: TextCapitalization.words, validator: (v) => AppValidators.required(v, 'Apellido'), decoration: const InputDecoration(hintText: 'Apellido'))),
          ]),
          const SizedBox(height: 12),
          TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, validator: AppValidators.email, autovalidateMode: AutovalidateMode.onUserInteraction, decoration: const InputDecoration(hintText: 'Correo electronico', prefixIcon: Icon(Icons.mail_outline))),
          const SizedBox(height: 12),
          TextFormField(controller: _telefono, keyboardType: TextInputType.phone, validator: (v) => AppValidators.required(v, 'Telefono'), decoration: const InputDecoration(hintText: 'Telefono', prefixIcon: Icon(Icons.phone_outlined))),
          const SizedBox(height: 24),
          Text('Vehiculo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PeraCoColors.textSecondary)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: vehiculos.map((v) => ChoiceChip(
  label: Text(v[0].toUpperCase() + v.substring(1),
    style: TextStyle(color: _vehiculo == v ? PeraCoColors.primaryDark : PeraCoColors.textPrimary, fontWeight: _vehiculo == v ? FontWeight.w600 : FontWeight.normal)),
  selected: _vehiculo == v,
  onSelected: (_) => setState(() => _vehiculo = v),
  selectedColor: PeraCoColors.greenPastel,
  backgroundColor: PeraCoColors.surfaceVariant,
  checkmarkColor: PeraCoColors.primary,
  side: BorderSide(color: _vehiculo == v ? PeraCoColors.primary : Colors.transparent),
)).toList()),
          const SizedBox(height: 12),
          TextFormField(controller: _placa, textCapitalization: TextCapitalization.characters, validator: (v) => AppValidators.required(v, 'Placa'), decoration: const InputDecoration(hintText: 'Placa del vehiculo', prefixIcon: Icon(Icons.directions_car_outlined))),
          const SizedBox(height: 24),
          Text('Seguridad', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: PeraCoColors.textSecondary)),
          const SizedBox(height: 12),
          TextFormField(controller: _pass, obscureText: _obscure1, validator: AppValidators.password, autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(hintText: 'Contrasena', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_obscure1 ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => _obscure1 = !_obscure1)))),
          const SizedBox(height: 12),
          TextFormField(controller: _confirmPass, obscureText: _obscure2, validator: (v) => AppValidators.confirmPassword(v, _pass.text), autovalidateMode: AutovalidateMode.onUserInteraction,
            decoration: InputDecoration(hintText: 'Confirmar contrasena', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_obscure2 ? Icons.visibility_off_outlined : Icons.visibility_outlined), onPressed: () => setState(() => _obscure2 = !_obscure2)))),
          const SizedBox(height: 32),
          ElevatedButton(onPressed: isLoading ? null : _handleSignup, child: isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))) : const Text('Registrarme como PeraGoger')),
        ])),
        const SizedBox(height: 32),
      ]))),
    );
  }
}
