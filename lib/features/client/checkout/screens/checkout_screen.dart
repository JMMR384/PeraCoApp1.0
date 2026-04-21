import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/core/config/supabase_config.dart';
import 'package:peraco/features/client/cart/providers/cart_provider.dart';
import 'package:peraco/features/auth/providers/auth_provider.dart';
import 'package:peraco/features/client/checkout/widgets/checkout_success_view.dart';
import 'package:peraco/features/client/checkout/widgets/step_dot.dart';
import 'package:peraco/features/client/checkout/widgets/summary_section.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});
  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  int _currentStep = 0;
  int _selectedAddress = 0;
  int _selectedPayment = 0;
  bool _processing = false;
  bool _orderComplete = false;
  String? _orderId;
  String _orderCode = '';

  final List<Map<String, String>> _addresses = [
    {'name': 'Casa', 'address': 'Calle 45 #12-34, Bogota', 'icon': 'home'},
    {'name': 'Oficina', 'address': 'Carrera 7 #89-12, Piso 4', 'icon': 'work'},
  ];

  final List<Map<String, String>> _paymentMethods = [
    {'name': 'Efectivo contra entrega', 'icon': 'money', 'detail': 'Paga al recibir tu pedido'},
    {'name': 'Nequi', 'icon': 'phone', 'detail': 'Transferencia inmediata'},
    {'name': 'Daviplata', 'icon': 'phone', 'detail': 'Transferencia inmediata'},
    {'name': 'Tarjeta de credito', 'icon': 'card', 'detail': 'Visa, Mastercard'},
  ];

  double get _subtotal => ref.read(cartProvider.notifier).subtotal;
  double get _envio => ref.read(cartProvider.notifier).envio;
  double get _total => ref.read(cartProvider.notifier).total;

  String _formatPrice(double price) => 'COP ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  void _nextStep() {
    if (_currentStep < 2) setState(() => _currentStep++);
    else _processOrder();
  }

  void _prevStep() {
    if (_currentStep > 0) setState(() => _currentStep--);
    else context.pop();
  }

  Future<void> _processOrder() async {
    setState(() => _processing = true);
    try {
      final cart = ref.read(cartProvider.notifier);
      final userId = ref.read(authProvider).user?.id;
      if (userId == null) return;

      final client = SupabaseConfig.client;
      final pedidoData = await client.from('pedidos').insert({
        'cliente_id': userId, 'estado': 'confirmado',
        'metodo_pago': _paymentMethods[_selectedPayment]['name'],
        'subtotal': cart.subtotal, 'costo_envio': cart.envio,
        'total': cart.total, 'notas_entrega': null,
      }).select().single();

      _orderId = pedidoData['id'] as String;
      _orderCode = pedidoData['codigo'] as String? ?? 'PC-??????';

      final items = ref.read(cartProvider);
      for (final item in items) {
        await client.from('pedido_items').insert({
          'pedido_id': _orderId, 'producto_id': item.product.id,
          'vendedor_id': item.product.vendedorId, 'nombre_producto': item.product.nombre,
          'precio_unitario': item.product.precio, 'cantidad': item.cantidad,
          'unidad': item.product.unidad, 'subtotal': item.subtotal,
        });
      }
      await client.from('pedido_tracking').insert({
        'pedido_id': _orderId, 'estado': 'confirmado',
        'mensaje': 'Pedido confirmado exitosamente',
      });

      ref.read(cartProvider.notifier).clear();
      if (!mounted) return;
      setState(() { _processing = false; _orderComplete = true; });
    } catch (e) {
      setState(() => _processing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Error al crear pedido: $e'),
            backgroundColor: PeraCoColors.error, behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_orderComplete) return CheckoutSuccessView(orderCode: _orderCode, orderId: _orderId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white,
          leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: _prevStep),
          title: const Text('Checkout'), centerTitle: true),
      body: Column(children: [
        _buildStepper(),
        const Divider(height: 1),
        Expanded(child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: _currentStep == 0 ? _buildAddressStep()
                : _currentStep == 1 ? _buildPaymentStep()
                : _buildConfirmStep())),
        _buildBottomButton(),
      ]),
    );
  }

  Widget _buildStepper() {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        child: Row(children: [
          StepDot(label: 'Direccion', step: 0, current: _currentStep),
          Expanded(child: Container(height: 2, color: _currentStep >= 1 ? PeraCoColors.primary : PeraCoColors.divider)),
          StepDot(label: 'Pago', step: 1, current: _currentStep),
          Expanded(child: Container(height: 2, color: _currentStep >= 2 ? PeraCoColors.primary : PeraCoColors.divider)),
          StepDot(label: 'Confirmar', step: 2, current: _currentStep),
        ]));
  }

  Widget _buildAddressStep() {
    return SingleChildScrollView(key: const ValueKey('address'), padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Donde entregamos tu pedido?', style: PeraCoText.h3(context)),
          const SizedBox(height: 16),
          ...List.generate(_addresses.length, (i) {
            final addr = _addresses[i]; final isSelected = _selectedAddress == i;
            return GestureDetector(onTap: () => setState(() => _selectedAddress = i),
                child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: isSelected ? PeraCoColors.greenPastel : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isSelected ? PeraCoColors.primary : PeraCoColors.divider, width: isSelected ? 2 : 1)),
                    child: Row(children: [
                      Container(width: 44, height: 44,
                          decoration: BoxDecoration(
                              color: isSelected ? PeraCoColors.primary.withValues(alpha: 0.1) : PeraCoColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(addr['icon'] == 'home' ? Icons.home_outlined : Icons.work_outlined,
                              color: isSelected ? PeraCoColors.primary : PeraCoColors.textSecondary)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(addr['name']!, style: PeraCoText.bodyBold(context).copyWith(color: isSelected ? PeraCoColors.primaryDark : PeraCoColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(addr['address']!, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
                      ])),
                      if (isSelected) const Icon(Icons.check_circle, color: PeraCoColors.primary),
                    ])));
          }),
          const SizedBox(height: 8),
          OutlinedButton.icon(onPressed: () {},
              icon: const Icon(Icons.add_location_alt_outlined, size: 20),
              label: const Text('Agregar nueva direccion'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: PeraCoColors.divider))),
          const SizedBox(height: 24),
          Text('Notas de entrega (opcional)', style: PeraCoText.caption(context).copyWith(fontWeight: FontWeight.w600, color: PeraCoColors.textSecondary)),
          const SizedBox(height: 8),
          TextField(maxLines: 2, decoration: InputDecoration(
              hintText: 'Ej: Dejar en porteria, timbre no funciona...',
              filled: true, fillColor: PeraCoColors.surfaceVariant,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
        ]));
  }

  Widget _buildPaymentStep() {
    return SingleChildScrollView(key: const ValueKey('payment'), padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Como quieres pagar?', style: PeraCoText.h3(context)),
          const SizedBox(height: 16),
          ...List.generate(_paymentMethods.length, (i) {
            final method = _paymentMethods[i]; final isSelected = _selectedPayment == i;
            final IconData icon;
            switch (method['icon']) {
              case 'money': icon = Icons.payments_outlined;
              case 'phone': icon = Icons.phone_android_outlined;
              case 'card': icon = Icons.credit_card_outlined;
              default: icon = Icons.payment_outlined;
            }
            return GestureDetector(onTap: () => setState(() => _selectedPayment = i),
                child: Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: isSelected ? PeraCoColors.greenPastel : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isSelected ? PeraCoColors.primary : PeraCoColors.divider, width: isSelected ? 2 : 1)),
                    child: Row(children: [
                      Container(width: 44, height: 44,
                          decoration: BoxDecoration(
                              color: isSelected ? PeraCoColors.primary.withValues(alpha: 0.1) : PeraCoColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(12)),
                          child: Icon(icon, color: isSelected ? PeraCoColors.primary : PeraCoColors.textSecondary)),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(method['name']!, style: PeraCoText.bodyBold(context).copyWith(color: isSelected ? PeraCoColors.primaryDark : PeraCoColors.textPrimary)),
                        const SizedBox(height: 2),
                        Text(method['detail']!, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
                      ])),
                      if (isSelected) const Icon(Icons.check_circle, color: PeraCoColors.primary),
                    ])));
          }),
        ]));
  }

  Widget _buildConfirmStep() {
    final items = ref.watch(cartProvider);
    return SingleChildScrollView(key: const ValueKey('confirm'), padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Revisa tu pedido', style: PeraCoText.h3(context)),
          const SizedBox(height: 16),
          SummarySection(icon: Icons.location_on_outlined,
              title: _addresses[_selectedAddress]['name']!,
              subtitle: _addresses[_selectedAddress]['address']!,
              onEdit: () => setState(() => _currentStep = 0)),
          const SizedBox(height: 12),
          SummarySection(icon: Icons.payment_outlined,
              title: _paymentMethods[_selectedPayment]['name']!,
              subtitle: _paymentMethods[_selectedPayment]['detail']!,
              onEdit: () => setState(() => _currentStep = 1)),
          const SizedBox(height: 20),
          Container(padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: PeraCoColors.surfaceVariant, borderRadius: BorderRadius.circular(14)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.shopping_basket, color: PeraCoColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Productos (${items.length})', style: PeraCoText.bodyBold(context)),
                ]),
                const Divider(height: 20),
                ...items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Text('${item.cantidad}x', style: PeraCoText.bodyBold(context).copyWith(color: PeraCoColors.primary)),
                      const SizedBox(width: 10),
                      Expanded(child: Text(item.product.nombre, style: PeraCoText.body(context))),
                      Text(_formatPrice(item.subtotal), style: PeraCoText.body(context)),
                    ]))),
                const Divider(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Subtotal', style: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.textSecondary)),
                  Text(_formatPrice(_subtotal), style: PeraCoText.body(context)),
                ]),
                const SizedBox(height: 4),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Envio', style: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.textSecondary)),
                  _envio == 0
                      ? Text('GRATIS', style: PeraCoText.bodyBold(context).copyWith(color: PeraCoColors.primary))
                      : Text(_formatPrice(_envio), style: PeraCoText.body(context)),
                ]),
                const Divider(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Total', style: PeraCoText.h3(context)),
                  Text(_formatPrice(_total), style: PeraCoText.h3(context).copyWith(color: PeraCoColors.primary)),
                ]),
              ])),
        ]));
  }

  Widget _buildBottomButton() {
    final labels = ['Continuar', 'Continuar', 'Confirmar pedido'];
    return Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(color: Colors.white,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))]),
        child: SafeArea(child: SizedBox(width: double.infinity, height: 52,
            child: ElevatedButton(
                onPressed: _processing ? null : _nextStep,
                style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _processing
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  if (_currentStep == 2) const Icon(Icons.shopping_basket, size: 20),
                  if (_currentStep == 2) const SizedBox(width: 8),
                  Text(labels[_currentStep]),
                  if (_currentStep == 2) ...[
                    const SizedBox(width: 8),
                    Text(_formatPrice(_total), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ])))));
  }
}
