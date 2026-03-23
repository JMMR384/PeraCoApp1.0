import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/core/config/supabase_config.dart';
import 'package:peraco/features/auth/providers/auth_provider.dart';

class ClientOrder {
  final String id;
  final String codigo;
  final String estado;
  final double total;
  final String metodoPago;
  final DateTime createdAt;
  final int itemCount;

  ClientOrder({required this.id, required this.codigo, required this.estado,
    required this.total, required this.metodoPago, required this.createdAt, required this.itemCount});

  factory ClientOrder.fromMap(Map<String, dynamic> map) {
    final items = map['pedido_items'] as List?;
    return ClientOrder(
      id: map['id'] as String,
      codigo: map['codigo'] as String? ?? 'PC-???',
      estado: map['estado'] as String,
      total: (map['total'] as num).toDouble(),
      metodoPago: map['metodo_pago'] as String? ?? 'Efectivo',
      createdAt: DateTime.parse(map['created_at'] as String),
      itemCount: items?.length ?? 0,
    );
  }

  String get displayTotal => 'COP ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  String get displayDate {
    final now = DateTime.now();
    final diff = now.difference(createdAt);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} dias';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String get displayEstado {
    switch (estado) {
      case 'confirmado': return 'Confirmado';
      case 'preparando': return 'Preparando';
      case 'listo': return 'Listo para recoger';
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

  IconData get estadoIcon {
    switch (estado) {
      case 'confirmado': return Icons.check_circle_outline;
      case 'preparando': return Icons.restaurant_outlined;
      case 'listo': return Icons.inventory_2_outlined;
      case 'recogido': return Icons.local_shipping_outlined;
      case 'en_camino': return Icons.delivery_dining;
      case 'entregado': return Icons.done_all;
      case 'cancelado': return Icons.cancel_outlined;
      default: return Icons.help_outline;
    }
  }
}

final clientOrdersProvider = FutureProvider<List<ClientOrder>>((ref) async {
  final userId = ref.read(authProvider).user?.id;
  if (userId == null) return [];

  final data = await SupabaseConfig.client
      .from('pedidos')
      .select('*, pedido_items(id)')
      .eq('cliente_id', userId)
      .order('created_at', ascending: false);

  return (data as List).map((e) => ClientOrder.fromMap(e)).toList();
});

class ClientOrdersScreen extends ConsumerWidget {
  const ClientOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(clientOrdersProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(children: [
                Text('Mis Pedidos', style: PeraCoText.h2(context)),
                const Spacer(),
                ordersAsync.whenOrNull(data: (orders) => orders.isNotEmpty
                    ? Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: PeraCoColors.greenPastel, borderRadius: BorderRadius.circular(8)),
                    child: Text('${orders.length}', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.primary, fontWeight: FontWeight.bold)))
                    : null) ?? const SizedBox(),
              ])),

          Expanded(child: ordersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline, size: 48, color: PeraCoColors.error),
              const SizedBox(height: 12),
              Text('Error al cargar pedidos', style: PeraCoText.body(context)),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: () => ref.invalidate(clientOrdersProvider), child: const Text('Reintentar')),
            ])),
            data: (orders) {
              if (orders.isEmpty) {
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.receipt_long_outlined, size: 72, color: PeraCoColors.primaryLight.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('No tienes pedidos aun', style: PeraCoText.body(context).copyWith(color: PeraCoColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Tus pedidos apareceran aqui', style: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.textHint)),
                ]));
              }

              // Separar activos y pasados
              final activos = orders.where((o) => !['entregado', 'cancelado'].contains(o.estado)).toList();
              final pasados = orders.where((o) => ['entregado', 'cancelado'].contains(o.estado)).toList();

              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(clientOrdersProvider),
                child: ListView(padding: const EdgeInsets.symmetric(horizontal: 20), children: [
                  if (activos.isNotEmpty) ...[
                    Text('En curso', style: PeraCoText.bodyBold(context).copyWith(color: PeraCoColors.primary)),
                    const SizedBox(height: 10),
                    ...activos.map((order) => _OrderCard(order: order, isActive: true)),
                    const SizedBox(height: 20),
                  ],
                  if (pasados.isNotEmpty) ...[
                    Text('Anteriores', style: PeraCoText.bodyBold(context).copyWith(color: PeraCoColors.textSecondary)),
                    const SizedBox(height: 10),
                    ...pasados.map((order) => _OrderCard(order: order, isActive: false)),
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

class _OrderCard extends StatelessWidget {
  final ClientOrder order;
  final bool isActive;
  const _OrderCard({required this.order, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/client/tracking/${order.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isActive ? order.estadoColor.withOpacity(0.3) : PeraCoColors.divider)),
        child: Column(children: [
          Row(children: [
            Container(width: 42, height: 42,
                decoration: BoxDecoration(color: order.estadoColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(order.estadoIcon, color: order.estadoColor, size: 22)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(order.codigo, style: PeraCoText.bodyBold(context)),
              const SizedBox(height: 2),
              Text('${order.itemCount} productos · ${order.displayDate}',
                  style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
            ])),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(order.displayTotal, style: PeraCoText.price(context).copyWith(color: PeraCoColors.primary)),
              const SizedBox(height: 4),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: order.estadoColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(order.displayEstado, style: PeraCoText.caption(context).copyWith(
                      color: order.estadoColor, fontWeight: FontWeight.w600, fontSize: 11))),
            ]),
          ]),
          if (isActive) ...[
            const SizedBox(height: 12),
            Container(
                width: double.infinity, height: 4,
                decoration: BoxDecoration(color: PeraCoColors.divider, borderRadius: BorderRadius.circular(2)),
                child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _progressForStatus(order.estado),
                    child: Container(decoration: BoxDecoration(color: order.estadoColor, borderRadius: BorderRadius.circular(2))))),
          ],
        ]),
      ),
    );
  }

  double _progressForStatus(String estado) {
    switch (estado) {
      case 'confirmado': return 0.15;
      case 'preparando': return 0.35;
      case 'listo': return 0.50;
      case 'recogido': return 0.65;
      case 'en_camino': return 0.85;
      case 'entregado': return 1.0;
      default: return 0.0;
    }
  }
}