import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/core/config/supabase_config.dart';
import 'package:peraco/features/auth/providers/auth_provider.dart';
import 'package:peraco/features/farmer/products/providers/farmer_products_provider.dart';
import 'package:peraco/features/farmer/orders/screens/farmer_orders_screen.dart';

final vendorMetricsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final userId = ref.read(authProvider).user?.id;
  if (userId == null) return {'productos': 0, 'pedidos': 0, 'ventas': 0.0, 'pendientes': 0};

  final client = SupabaseConfig.client;

  // Contar productos activos
  final productos = await client.from('productos').select('id').eq('vendedor_id', userId).eq('activo', true);
  final productCount = (productos as List).length;

  // Pedidos donde tengo items
  final items = await client.from('pedido_items')
      .select('subtotal, pedido:pedidos!pedido_id(id, estado, created_at)')
      .eq('vendedor_id', userId);

  final pedidoIds = <String>{};
  double ventasTotal = 0.0;
  int pendientes = 0;
  final now = DateTime.now();

  for (final item in items as List) {
    final pedido = item['pedido'] as Map<String, dynamic>;
    final pedidoId = pedido['id'] as String;
    final estado = pedido['estado'] as String;
    pedidoIds.add(pedidoId);
    ventasTotal += (item['subtotal'] as num).toDouble();
    if (!['entregado', 'cancelado'].contains(estado)) pendientes++;
  }

  return {
    'productos': productCount,
    'pedidos': pedidoIds.length,
    'ventas': ventasTotal,
    'pendientes': pendientes,
  };
});

class FarmerDashboardScreen extends ConsumerWidget {
  const FarmerDashboardScreen({super.key});

  String _formatPrice(double price) {
    if (price == 0) return 'COP 0';
    return 'COP ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final name = auth.userName ?? 'Vendedor';
    final metricsAsync = ref.watch(vendorMetricsProvider);

    String greeting = 'Hola';
    final hour = DateTime.now().hour;
    if (hour < 12) { greeting = 'Buenos dias'; }
    else if (hour < 18) { greeting = 'Buenas tardes'; }
    else { greeting = 'Buenas noches'; }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(vendorMetricsProvider),
          child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('$greeting, $name', style: PeraCoText.h2(context)),
                    const SizedBox(height: 2),
                    Text('Tu resumen general', style: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.textSecondary)),
                  ])),
                  Image.asset('assets/images/icono_peraco.png', height: 48, fit: BoxFit.contain),
                ]),
                const SizedBox(height: 24),

                metricsAsync.when(
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
                  error: (_, __) => const Center(child: Text('Error cargando metricas')),
                  data: (metrics) {
                    final productos = metrics['productos'] as int;
                    final pedidos = metrics['pedidos'] as int;
                    final ventas = metrics['ventas'] as double;
                    final pendientes = metrics['pendientes'] as int;

                    return Column(children: [
                      Row(children: [
                        Expanded(child: _MetricCard(icon: Icons.inventory_2, label: 'Productos', value: '$productos', color: PeraCoColors.primary)),
                        const SizedBox(width: 12),
                        Expanded(child: _MetricCard(icon: Icons.shopping_cart, label: 'Total pedidos', value: '$pedidos', color: const Color(0xFF66BB6A))),
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(child: _MetricCard(icon: Icons.trending_up, label: 'Ventas totales', value: _formatPrice(ventas), color: PeraCoColors.primaryLight)),
                        const SizedBox(width: 12),
                        Expanded(child: _MetricCard(icon: Icons.pending_actions, label: 'Pendientes', value: '$pendientes', color: PeraCoColors.warning)),
                      ]),
                    ]);
                  },
                ),

                const SizedBox(height: 24),
                Text('Accesos rapidos', style: PeraCoText.h3(context)),
                const SizedBox(height: 12),
                _QuickAction(icon: Icons.add_circle_outline, title: 'Agregar producto', subtitle: 'Publica un nuevo producto',
                    color: PeraCoColors.primary, onTap: () => context.go('/farmer/products')),
                const SizedBox(height: 8),
                _QuickAction(icon: Icons.receipt_long_outlined, title: 'Ver pedidos', subtitle: 'Gestiona tus pedidos pendientes',
                    color: PeraCoColors.warning, onTap: () => context.go('/farmer/orders')),
                const SizedBox(height: 8),
                _QuickAction(icon: Icons.bar_chart_rounded, title: 'Mis finanzas', subtitle: 'Ventas, graficas y transacciones',
                    color: PeraCoColors.info, onTap: () => context.push('/farmer/finances')),
                const SizedBox(height: 8),
                _QuickAction(icon: Icons.store_outlined, title: 'Mi tienda', subtitle: 'Edita tu perfil de vendedor',
                    color: PeraCoColors.primaryDark, onTap: () => context.go('/farmer/profile')),
              ]),
          ),
        ),
      ),
    );
  }
}
class _MetricCard extends StatelessWidget {
  final IconData icon; final String label; final String value; final Color color;
  const _MetricCard({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 22)),
          const SizedBox(height: 12),
          Text(value, style: PeraCoText.priceLarge(context).copyWith(color: PeraCoColors.textPrimary)),
          const SizedBox(height: 4),
          Text(label, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
        ]));
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon; final String title; final String subtitle; final Color color; final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, borderRadius: BorderRadius.circular(12), child: Container(padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: PeraCoColors.divider)),
        child: Row(children: [
          Container(width: 44, height: 44, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: PeraCoText.bodyBold(context)),
            Text(subtitle, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
          ])),
          const Icon(Icons.chevron_right, color: PeraCoColors.textHint),
        ])));
  }
}