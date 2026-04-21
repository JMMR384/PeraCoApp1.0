import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/features/farmer/crops/providers/harvest_provider.dart';
import 'package:peraco/features/farmer/crops/widgets/harvest_form_sheet.dart';

class FarmerHarvestCalendarScreen extends ConsumerWidget {
  const FarmerHarvestCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final harvestAsync = ref.watch(harvestProvider);

    return Scaffold(
      backgroundColor: PeraCoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Mis Cosechas', style: PeraCoText.h3(context)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => HarvestFormSheet.show(context),
        backgroundColor: PeraCoColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Programar', style: PeraCoText.bodyBold(context).copyWith(color: Colors.white)),
      ),
      body: harvestAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e', style: PeraCoText.body(context))),
        data: (harvests) {
          if (harvests.isEmpty) {
            return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.agriculture_outlined, size: 64, color: PeraCoColors.textHint),
              const SizedBox(height: 16),
              Text('Sin cosechas programadas', style: PeraCoText.bodyBold(context).copyWith(color: PeraCoColors.textSecondary)),
              const SizedBox(height: 8),
              Text('Toca el botón para agregar una', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textHint)),
              const SizedBox(height: 80),
            ]));
          }

          final upcoming = harvests.where((h) => h.estado == HarvestStatus.planificado || h.estado == HarvestStatus.enCrecimiento).toList();
          final done = harvests.where((h) => h.estado == HarvestStatus.cosechado || h.estado == HarvestStatus.perdido).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              if (upcoming.isNotEmpty) ...[
                _SectionHeader(title: 'Próximas cosechas', count: upcoming.length),
                const SizedBox(height: 8),
                ...upcoming.map((h) => _HarvestCard(harvest: h)),
              ],
              if (done.isNotEmpty) ...[
                const SizedBox(height: 8),
                _SectionHeader(title: 'Historial', count: done.length),
                const SizedBox(height: 8),
                ...done.map((h) => _HarvestCard(harvest: h)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  const _SectionHeader({required this.title, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(title, style: PeraCoText.bodyBold(context)),
      const SizedBox(width: 8),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(color: PeraCoColors.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
        child: Text('$count', style: TextStyle(fontSize: 12, color: PeraCoColors.primary, fontWeight: FontWeight.w700)),
      ),
    ]);
  }
}

class _HarvestCard extends ConsumerWidget {
  final Harvest harvest;
  const _HarvestCard({required this.harvest});

  Color _statusColor(HarvestStatus s) {
    switch (s) {
      case HarvestStatus.planificado: return PeraCoColors.info;
      case HarvestStatus.enCrecimiento: return PeraCoColors.primary;
      case HarvestStatus.cosechado: return PeraCoColors.success;
      case HarvestStatus.perdido: return PeraCoColors.error;
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _statusColor(harvest.estado);
    final isVencido = harvest.isVencido;
    final diasRestantes = harvest.diasRestantes;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isVencido ? PeraCoColors.error.withValues(alpha: 0.4) : color.withValues(alpha: 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(harvest.cultivoNombre, style: PeraCoText.bodyBold(context))),
            _StatusBadge(label: harvest.estado.label, color: color),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            _InfoChip(icon: Icons.agriculture_outlined, label: _formatDate(harvest.fechaCosechaEstimada)),
            const SizedBox(width: 10),
            if (harvest.fechaSiembra != null)
              _InfoChip(icon: Icons.grass, label: _formatDate(harvest.fechaSiembra!)),
          ]),
          if (harvest.cantidadEstimada != null) ...[
            const SizedBox(height: 6),
            _InfoChip(
              icon: Icons.scale_outlined,
              label: '${harvest.cantidadEstimada!.toStringAsFixed(1)} ${harvest.unidad}',
            ),
          ],
          if (harvest.notas != null && harvest.notas!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(harvest.notas!, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
          const SizedBox(height: 10),
          Row(children: [
            if (harvest.estado == HarvestStatus.planificado || harvest.estado == HarvestStatus.enCrecimiento) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isVencido ? PeraCoColors.error.withValues(alpha: 0.1) : color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isVencido ? 'Vencido hace ${diasRestantes.abs()} días' : 'En $diasRestantes días',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isVencido ? PeraCoColors.error : color),
                ),
              ),
              const Spacer(),
              _StatusMenu(harvest: harvest),
            ] else
              const Spacer(),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: PeraCoColors.textHint),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Eliminar cosecha'),
                    content: Text('¿Eliminar la cosecha de ${harvest.cultivoNombre}?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Eliminar', style: TextStyle(color: PeraCoColors.error))),
                    ],
                  ),
                );
                if (confirm == true) {
                  await ref.read(harvestProvider.notifier).delete(harvest.id);
                }
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ]),
        ]),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 13, color: PeraCoColors.textSecondary),
      const SizedBox(width: 4),
      Text(label, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
    ]);
  }
}

class _StatusMenu extends ConsumerWidget {
  final Harvest harvest;
  const _StatusMenu({required this.harvest});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = HarvestStatus.values.where((s) => s != harvest.estado).toList();
    return PopupMenuButton<HarvestStatus>(
      onSelected: (s) => ref.read(harvestProvider.notifier).updateStatus(harvest.id, s),
      itemBuilder: (_) => options.map((s) => PopupMenuItem(value: s, child: Text(s.label))).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          border: Border.all(color: PeraCoColors.divider),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('Cambiar estado', style: PeraCoText.caption(context)),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, size: 16, color: PeraCoColors.textSecondary),
        ]),
      ),
    );
  }
}
