import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/core/config/supabase_config.dart';
import 'package:peraco/features/auth/providers/auth_provider.dart';

class VendorOrder {
  final String pedidoId;
  final String codigo;
  final String estado;
  final String clienteNombre;
  final double totalPedido;
  final DateTime createdAt;
  final List<VendorOrderItem> items;

  VendorOrder({required this.pedidoId, required this.codigo, required this.estado,
    required this.clienteNombre, required this.totalPedido, required this.createdAt, required this.items});

  double get miTotal => items.fold(0.0, (sum, item) => sum + item.subtotal);

  String get displayTotal => 'COP ${miTotal.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  String get displayDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays == 1) return 'Ayer';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String get displayEstado {
    switch (estado) {
      case 'confirmado': return 'Nuevo';
      case 'preparando': return 'Preparando';
      case 'listo': return 'Listo';
      case 'recogido': return 'Recogido';
      case 'en_camino': return 'En camino';
      case 'entregado': return 'Entregado';
      case 'cancelado': return 'Cancelado';
      default: return estado;
    }
  }

  Color get estadoColor {
    switch (estado) {
      case 'confirmado': return const Color(0xFF66BB6A);
      case 'preparando': return PeraCoColors.warning;
      case 'listo': return PeraCoColors.primaryLight;
      case 'recogido': return PeraCoColors.primaryLight;
      case 'en_camino': return PeraCoColors.primary;
      case 'entregado': return PeraCoColors.success;
      case 'cancelado': return PeraCoColors.error;
      default: return PeraCoColors.textHint;
    }
  }
}

class VendorOrderItem {
  final String nombreProducto;
  final int cantidad;
  final String unidad;
  final double precioUnitario;
  final double subtotal;

  VendorOrderItem({required this.nombreProducto, required this.cantidad,
    required this.unidad, required this.precioUnitario, required this.subtotal});

  factory VendorOrderItem.fromMap(Map<String, dynamic> map) {
    return VendorOrderItem(
      nombreProducto: map['nombre_producto'] as String,
      cantidad: (map['cantidad'] as num).toInt(),
      unidad: map['unidad'] as String? ?? 'kg',
      precioUnitario: (map['precio_unitario'] as num).toDouble(),
      subtotal: (map['subtotal'] as num).toDouble(),
    );
  }
}

class VendorOrdersNotifier extends StateNotifier<AsyncValue<List<VendorOrder>>> {
  final Ref ref;
  VendorOrdersNotifier(this.ref) : super(const AsyncValue.loading()) { loadOrders(); }

  Future<void> loadOrders() async {
    state = const AsyncValue.loading();
    try {
      final userId = ref.read(authProvider).user?.id;
      if (userId == null) { state = const AsyncValue.data([]); return; }

      // Buscar items donde vendedor_id = mi id, con info del pedido
      final data = await SupabaseConfig.client
          .from('pedido_items')
          .select('*, pedido:pedidos!pedido_id(id, codigo, estado, total, created_at)')
          .eq('vendedor_id', userId)
          .order('id', ascending: false);

      // Agrupar por pedido
      final Map<String, VendorOrder> ordersMap = {};
      for (final row in data as List) {
        final pedido = row['pedido'] as Map<String, dynamic>;
        final pedidoId = pedido['id'] as String;

        if (!ordersMap.containsKey(pedidoId)) {
          ordersMap[pedidoId] = VendorOrder(
            pedidoId: pedidoId,
            codigo: pedido['codigo'] as String? ?? 'PC-???',
            estado: pedido['estado'] as String,
            clienteNombre: 'Cliente',
            totalPedido: (pedido['total'] as num).toDouble(),
            createdAt: DateTime.parse(pedido['created_at'] as String),
            items: [],
          );
        }
        ordersMap[pedidoId]!.items.add(VendorOrderItem.fromMap(row));
      }

      final orders = ordersMap.values.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> updateEstado(String pedidoId, String nuevoEstado) async {
    try {
      await SupabaseConfig.client.from('pedidos').update({'estado': nuevoEstado}).eq('id', pedidoId);
      try {
        await SupabaseConfig.client.from('pedido_tracking').insert({
          'pedido_id': pedidoId,
          'estado': nuevoEstado,
          'mensaje': _mensajeEstado(nuevoEstado),
        });
      } catch (_) { /* tabla opcional */ }
      await loadOrders();
      return true;
    } catch (_) {
      return false;
    }
  }

  String _mensajeEstado(String estado) {
    switch (estado) {
      case 'preparando': return 'El vendedor esta preparando tu pedido';
      case 'listo': return 'Tu pedido esta listo para ser recogido';
      default: return 'Estado actualizado a $estado';
    }
  }
}

final vendorOrdersProvider = StateNotifierProvider<VendorOrdersNotifier, AsyncValue<List<VendorOrder>>>((ref) {
  return VendorOrdersNotifier(ref);
});

class FarmerOrdersScreen extends ConsumerWidget {
  const FarmerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(vendorOrdersProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(children: [
                Text('Pedidos Recibidos', style: PeraCoText.h2(context)),
                const Spacer(),
                ordersAsync.whenOrNull(data: (orders) {
                  final activos = orders.where((o) => !['entregado', 'cancelado'].contains(o.estado)).length;
                  return activos > 0
                      ? Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: PeraCoColors.warning.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                      child: Text('$activos activos', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.warning, fontWeight: FontWeight.bold)))
                      : null;
                }) ?? const SizedBox(),
              ])),

          Expanded(child: ordersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline, size: 48, color: PeraCoColors.error),
              const SizedBox(height: 12),
              Text('Error al cargar', style: PeraCoText.body(context)),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: () => ref.read(vendorOrdersProvider.notifier).loadOrders(), child: const Text('Reintentar')),
            ])),
            data: (orders) {
              if (orders.isEmpty) {
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.shopping_cart_outlined, size: 72, color: PeraCoColors.primaryLight.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('Sin pedidos pendientes', style: PeraCoText.body(context).copyWith(color: PeraCoColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Los pedidos de tus clientes apareceran aqui', style: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.textHint)),
                ]));
              }

              final nuevos = orders.where((o) => o.estado == 'confirmado').toList();
              final enProceso = orders.where((o) => ['preparando', 'listo'].contains(o.estado)).toList();
              final completados = orders.where((o) => ['recogido', 'en_camino', 'entregado', 'cancelado'].contains(o.estado)).toList();

              return RefreshIndicator(
                onRefresh: () => ref.read(vendorOrdersProvider.notifier).loadOrders(),
                child: ListView(padding: const EdgeInsets.symmetric(horizontal: 20), children: [
                  if (nuevos.isNotEmpty) ...[
                    _SectionHeader(title: 'Nuevos', count: nuevos.length, color: const Color(0xFF66BB6A)),
                    const SizedBox(height: 10),
                    ...nuevos.map((o) => _VendorOrderCard(order: o)),
                    const SizedBox(height: 20),
                  ],
                  if (enProceso.isNotEmpty) ...[
                    _SectionHeader(title: 'En proceso', count: enProceso.length, color: PeraCoColors.warning),
                    const SizedBox(height: 10),
                    ...enProceso.map((o) => _VendorOrderCard(order: o)),
                    const SizedBox(height: 20),
                  ],
                  if (completados.isNotEmpty) ...[
                    _SectionHeader(title: 'Completados', count: completados.length, color: PeraCoColors.textSecondary),
                    const SizedBox(height: 10),
                    ...completados.map((o) => _VendorOrderCard(order: o)),
                  ],
                  const SizedBox(height: 20),
                ]),
              );
            },
          )),
        ]),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title; final int count; final Color color;
  const _SectionHeader({required this.title, required this.count, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 4, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title, style: PeraCoText.bodyBold(context)),
      const SizedBox(width: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
          child: Text('$count', style: PeraCoText.caption(context).copyWith(color: color, fontWeight: FontWeight.bold))),
    ]);
  }
}

class _VendorOrderCard extends ConsumerWidget {
  final VendorOrder order;
  const _VendorOrderCard({required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: order.estadoColor.withOpacity(0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Row(children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: order.estadoColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(order.displayEstado, style: PeraCoText.caption(context).copyWith(
                  color: order.estadoColor, fontWeight: FontWeight.w600, fontSize: 11))),
          const Spacer(),
          Text(order.displayDate, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textHint)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Text(order.codigo, style: PeraCoText.bodyBold(context)),
          const SizedBox(width: 8),
          Text('· ${order.clienteNombre}', style: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.textSecondary)),
        ]),
        const SizedBox(height: 8),

        // Items
        ...order.items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: [
              Text('${item.cantidad}x', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.primary, fontWeight: FontWeight.w600)),
              const SizedBox(width: 8),
              Expanded(child: Text(item.nombreProducto, style: PeraCoText.bodySmall(context))),
              Text('${item.cantidad} ${item.unidad}', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
            ]))),

        const Divider(height: 20),

        // Total + Acciones
        Row(children: [
          Text('Mi venta: ', style: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.textSecondary)),
          Text(order.displayTotal, style: PeraCoText.price(context).copyWith(color: PeraCoColors.primary)),
          const Spacer(),
          if (order.estado == 'confirmado')
            _ActionButton(label: 'Preparar', color: Color(0xFF66BB6A), icon: Icons.shopping_bag,
                onTap: () => ref.read(vendorOrdersProvider.notifier).updateEstado(order.pedidoId, 'preparando')),
          if (order.estado == 'preparando')
            _ActionButton(label: 'Listo', color: PeraCoColors.primary, icon: Icons.check_circle_outline,
                onTap: () => ref.read(vendorOrdersProvider.notifier).updateEstado(order.pedidoId, 'listo')),
          if (order.estado == 'listo')
            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: PeraCoColors.greenPastel, borderRadius: BorderRadius.circular(8)),
                child: Row(children: [
                  const Icon(Icons.hourglass_top, size: 14, color: PeraCoColors.primary),
                  const SizedBox(width: 4),
                  Text('Esperando PeraGoger', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.primary, fontWeight: FontWeight.w600)),
                ])),
        ]),
      ]),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label; final Color color; final IconData icon; final VoidCallback onTap;
  const _ActionButton({required this.label, required this.color, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap,
        child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(label, style: PeraCoText.caption(context).copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
            ])));
  }
}