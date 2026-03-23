import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/core/config/supabase_config.dart';
import 'package:peraco/features/auth/providers/auth_provider.dart';

class DeliveryItem {
  final String nombreProducto;
  final int cantidad;
  final String unidad;
  final String vendedorNombre;
  final String? vendedorNegocio;

  DeliveryItem({required this.nombreProducto, required this.cantidad,
    required this.unidad, required this.vendedorNombre, this.vendedorNegocio});
}

class Delivery {
  final String pedidoId;
  final String codigo;
  final String estado;
  final String clienteNombre;
  final double total;
  final DateTime createdAt;
  final List<DeliveryItem> items;
  final String? notasEntrega;

  Delivery({required this.pedidoId, required this.codigo, required this.estado,
    required this.clienteNombre, required this.total,
    required this.createdAt, required this.items, this.notasEntrega});

  String get displayTotal => 'COP ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  String get displayDate {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';
    if (diff.inDays == 1) return 'Ayer';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String get displayEstado {
    switch (estado) {
      case 'listo': return 'Listo para recoger';
      case 'recogido': return 'Recogido';
      case 'en_camino': return 'En camino';
      case 'entregado': return 'Entregado';
      default: return estado;
    }
  }

  Color get estadoColor {
    switch (estado) {
      case 'listo': return PeraCoColors.primaryLight;
      case 'recogido': return PeraCoColors.warning;
      case 'en_camino': return PeraCoColors.primary;
      case 'entregado': return PeraCoColors.success;
      default: return PeraCoColors.textHint;
    }
  }

  IconData get estadoIcon {
    switch (estado) {
      case 'listo': return Icons.inventory_2_outlined;
      case 'recogido': return Icons.local_shipping_outlined;
      case 'en_camino': return Icons.delivery_dining;
      case 'entregado': return Icons.done_all;
      default: return Icons.help_outline;
    }
  }

  // Agrupar items por vendedor
  Map<String, List<DeliveryItem>> get itemsByVendor {
    final map = <String, List<DeliveryItem>>{};
    for (final item in items) {
      final key = item.vendedorNegocio ?? item.vendedorNombre;
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }
}

class DeliveriesNotifier extends StateNotifier<AsyncValue<List<Delivery>>> {
  final Ref ref;
  DeliveriesNotifier(this.ref) : super(const AsyncValue.loading()) { loadDeliveries(); }

  Future<void> loadDeliveries() async {
    state = const AsyncValue.loading();
    try {
      final client = SupabaseConfig.client;

      final data = await client.from('pedidos')
          .select('*, cliente:cliente_id(nombre), pedido_items(nombre_producto, cantidad, unidad, vendedor_id)')
          .inFilter('estado', ['listo', 'recogido', 'en_camino'])
          .order('created_at', ascending: false);

      // Obtener nombres de vendedores
      final vendedorIds = <String>{};
      for (final pedido in data as List) {
        for (final item in pedido['pedido_items'] as List) {
          vendedorIds.add(item['vendedor_id'] as String);
        }
      }

      Map<String, Map<String, String>> vendedorInfo = {};
      if (vendedorIds.isNotEmpty) {
        final vendedores = await client.from('usuarios')
            .select('id, nombre')
            .inFilter('id', vendedorIds.toList());
        final infoVendedor = await client.from('info_vendedor')
            .select('usuario_id, nombre_negocio')
            .inFilter('usuario_id', vendedorIds.toList());

        for (final v in vendedores as List) {
          vendedorInfo[v['id'] as String] = {'nombre': v['nombre'] as String};
        }
        for (final iv in infoVendedor as List) {
          final uid = iv['usuario_id'] as String;
          if (vendedorInfo.containsKey(uid)) {
            vendedorInfo[uid]!['negocio'] = (iv['nombre_negocio'] as String?) ?? '';
          }
        }
      }

      final deliveries = (data).map((pedido) {
        final cliente = pedido['cliente'] as Map<String, dynamic>?;
        final pedidoItems = pedido['pedido_items'] as List;

        final items = pedidoItems.map((item) {
          final vid = item['vendedor_id'] as String;
          final vInfo = vendedorInfo[vid];
          return DeliveryItem(
            nombreProducto: item['nombre_producto'] as String,
            cantidad: (item['cantidad'] as num).toInt(),
            unidad: item['unidad'] as String? ?? 'kg',
            vendedorNombre: vInfo?['nombre'] ?? 'Vendedor',
            vendedorNegocio: vInfo?['negocio'],
          );
        }).toList();

        return Delivery(
          pedidoId: pedido['id'] as String,
          codigo: pedido['codigo'] as String? ?? 'PC-???',
          estado: pedido['estado'] as String,
          clienteNombre: cliente?['nombre'] as String? ?? 'Cliente',
          total: (pedido['total'] as num).toDouble(),
          createdAt: DateTime.parse(pedido['created_at'] as String),
          items: items,
          notasEntrega: pedido['notas_entrega'] as String?,
        );
      }).toList();

      state = AsyncValue.data(deliveries);
    } catch (e, st) {
      print('ERROR CARGANDO ENTREGAS: $e');
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> acceptDelivery(String pedidoId) async {
    try {
      final userId = ref.read(authProvider).user?.id;
      await SupabaseConfig.client.from('pedidos').update({
        'peragoger_id': userId,
        'estado': 'recogido',
      }).eq('id', pedidoId);
      await SupabaseConfig.client.from('pedido_tracking').insert({
        'pedido_id': pedidoId, 'estado': 'recogido',
        'mensaje': 'Un PeraGoger ha recogido tu pedido',
      });
      await loadDeliveries();
      return true;
    } catch (e) { print('ERROR ACEPTANDO: $e'); return false; }
  }

  Future<bool> startDelivery(String pedidoId) async {
    try {
      await SupabaseConfig.client.from('pedidos').update({'estado': 'en_camino'}).eq('id', pedidoId);
      await SupabaseConfig.client.from('pedido_tracking').insert({
        'pedido_id': pedidoId, 'estado': 'en_camino',
        'mensaje': 'Tu pedido va en camino',
      });
      await loadDeliveries();
      return true;
    } catch (e) { return false; }
  }

  Future<bool> completeDelivery(String pedidoId) async {
    try {
      await SupabaseConfig.client.from('pedidos').update({'estado': 'entregado'}).eq('id', pedidoId);
      await SupabaseConfig.client.from('pedido_tracking').insert({
        'pedido_id': pedidoId, 'estado': 'entregado',
        'mensaje': 'Pedido entregado exitosamente',
      });
      await loadDeliveries();
      return true;
    } catch (e) { return false; }
  }
}

final deliveriesProvider = StateNotifierProvider<DeliveriesNotifier, AsyncValue<List<Delivery>>>((ref) {
  return DeliveriesNotifier(ref);
});

class DriverDeliveriesScreen extends ConsumerWidget {
  const DriverDeliveriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final name = auth.userName ?? 'PeraGoger';
    final deliveriesAsync = ref.watch(deliveriesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            decoration: const BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: PeraCoColors.divider, width: 0.5))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Hola, $name', style: PeraCoText.h2(context)),
                const SizedBox(height: 6),
                Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: PeraCoColors.greenPastel, borderRadius: BorderRadius.circular(20)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 8, height: 8, decoration: const BoxDecoration(color: PeraCoColors.primary, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text('Disponible', style: PeraCoText.label(context).copyWith(color: PeraCoColors.primary)),
                    ])),
              ])),
              Image.asset('assets/images/icono_peraco.png', height: 48, fit: BoxFit.contain),
            ]),
          ),

          // Titulo
          Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(children: [
                Text('Entregas', style: PeraCoText.h3(context)),
                const Spacer(),
                deliveriesAsync.whenOrNull(data: (d) => d.isNotEmpty
                    ? Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: PeraCoColors.warning.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                    child: Text('${d.length} disponibles', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.warning, fontWeight: FontWeight.bold)))
                    : null) ?? const SizedBox(),
              ])),
          const SizedBox(height: 12),

          // Lista
          Expanded(child: deliveriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.error_outline, size: 48, color: PeraCoColors.error),
              const SizedBox(height: 12),
              Text('Error al cargar', style: PeraCoText.body(context)),
              const SizedBox(height: 8),
              ElevatedButton(onPressed: () => ref.read(deliveriesProvider.notifier).loadDeliveries(), child: const Text('Reintentar')),
            ])),
            data: (deliveries) {
              if (deliveries.isEmpty) {
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.local_shipping_outlined, size: 72, color: PeraCoColors.primaryLight.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text('Sin entregas pendientes', style: PeraCoText.body(context).copyWith(color: PeraCoColors.textSecondary)),
                  const SizedBox(height: 8),
                  Text('Las entregas disponibles apareceran aqui', style: PeraCoText.bodySmall(context).copyWith(color: PeraCoColors.textHint)),
                ]));
              }

              final disponibles = deliveries.where((d) => d.estado == 'listo').toList();
              final misEntregas = deliveries.where((d) => d.estado != 'listo').toList();

              return RefreshIndicator(
                onRefresh: () => ref.read(deliveriesProvider.notifier).loadDeliveries(),
                child: ListView(padding: const EdgeInsets.symmetric(horizontal: 20), children: [
                  if (disponibles.isNotEmpty) ...[
                    _SectionTitle(title: 'Disponibles para recoger', color: PeraCoColors.primaryLight),
                    const SizedBox(height: 10),
                    ...disponibles.map((d) => _DeliveryCard(delivery: d)),
                    const SizedBox(height: 20),
                  ],
                  if (misEntregas.isNotEmpty) ...[
                    _SectionTitle(title: 'Mis entregas activas', color: PeraCoColors.primary),
                    const SizedBox(height: 10),
                    ...misEntregas.map((d) => _DeliveryCard(delivery: d)),
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

class _SectionTitle extends StatelessWidget {
  final String title; final Color color;
  const _SectionTitle({required this.title, required this.color});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 4, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 8),
      Text(title, style: PeraCoText.bodyBold(context)),
    ]);
  }
}

class _DeliveryCard extends ConsumerWidget {
  final Delivery delivery;
  const _DeliveryCard({required this.delivery});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showDetail(context, ref),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: delivery.estadoColor.withOpacity(0.3))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Estado + fecha
          Row(children: [
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: delivery.estadoColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(delivery.estadoIcon, size: 14, color: delivery.estadoColor),
                  const SizedBox(width: 4),
                  Text(delivery.displayEstado, style: PeraCoText.caption(context).copyWith(
                      color: delivery.estadoColor, fontWeight: FontWeight.w600, fontSize: 11)),
                ])),
            const Spacer(),
            Text(delivery.displayDate, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textHint)),
          ]),
          const SizedBox(height: 10),

          // Codigo
          Text(delivery.codigo, style: PeraCoText.bodyBold(context)),
          const SizedBox(height: 8),

          // Vendedores (recoger)
          ...delivery.itemsByVendor.entries.map((entry) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: PeraCoColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.store_outlined, size: 14, color: PeraCoColors.primary),
                  const SizedBox(width: 6),
                  Text(entry.key, style: PeraCoText.label(context).copyWith(color: PeraCoColors.primary)),
                ]),
                const SizedBox(height: 6),
                ...entry.value.map((item) => Padding(padding: const EdgeInsets.only(left: 20, bottom: 2),
                    child: Row(children: [
                      Text('${item.cantidad}x', style: PeraCoText.caption(context).copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      Expanded(child: Text(item.nombreProducto, style: PeraCoText.bodySmall(context))),
                      Text('${item.cantidad} ${item.unidad}', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
                    ]))),
              ]))),

          const SizedBox(height: 6),

          // Cliente (entregar)
          Row(children: [
            const Icon(Icons.person_outline, size: 16, color: PeraCoColors.textSecondary),
            const SizedBox(width: 6),
            Text('Entregar a: ', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
            Text(delivery.clienteNombre, style: PeraCoText.label(context)),
          ]),

          const Divider(height: 20),

          // Total + Accion
          Row(children: [
            Text(delivery.displayTotal, style: PeraCoText.price(context).copyWith(color: PeraCoColors.primary)),
            const SizedBox(width: 8),
            Text('· ${delivery.items.length} productos', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
            const Spacer(),

            if (delivery.estado == 'listo')
              _ActionBtn(label: 'Recoger', color: PeraCoColors.primaryLight, icon: Icons.back_hand_outlined,
                  onTap: () => _confirmAction(context, ref, 'Recoger pedido ${delivery.codigo}?',
                          () => ref.read(deliveriesProvider.notifier).acceptDelivery(delivery.pedidoId))),

            if (delivery.estado == 'recogido')
              _ActionBtn(label: 'En camino', color: PeraCoColors.primary, icon: Icons.delivery_dining,
                  onTap: () => ref.read(deliveriesProvider.notifier).startDelivery(delivery.pedidoId)),

            if (delivery.estado == 'en_camino')
              _ActionBtn(label: 'Entregado', color: PeraCoColors.success, icon: Icons.done_all,
                  onTap: () => _confirmAction(context, ref, 'Confirmar entrega de ${delivery.codigo}?',
                          () => ref.read(deliveriesProvider.notifier).completeDelivery(delivery.pedidoId))),
          ]),
        ]),
      ),
    );
  }

  void _confirmAction(BuildContext context, WidgetRef ref, String message, Future<bool> Function() action) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Confirmar'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () async {
            Navigator.pop(ctx);
            final success = await action();
            if (success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Estado actualizado'),
                  backgroundColor: PeraCoColors.success, behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.all(16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
            }
          }, child: const Text('Confirmar')),
        ]));
  }

  void _showDetail(BuildContext context, WidgetRef ref) {
    // TODO: Abrir pantalla de detalle con mapa
  }
}

class _ActionBtn extends StatelessWidget {
  final String label; final Color color; final IconData icon; final VoidCallback onTap;
  const _ActionBtn({required this.label, required this.color, required this.icon, required this.onTap});
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