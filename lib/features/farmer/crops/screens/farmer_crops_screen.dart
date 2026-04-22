import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/features/farmer/crops/data/crops_data.dart';
import 'package:peraco/features/farmer/crops/providers/harvest_provider.dart';
import 'package:peraco/features/farmer/crops/widgets/crop_advisor_sheet.dart';
import 'package:peraco/features/farmer/crops/widgets/crop_detail_sheet.dart';
import 'package:peraco/features/farmer/crops/widgets/harvest_form_sheet.dart';

class FarmerCropsScreen extends ConsumerStatefulWidget {
  const FarmerCropsScreen({super.key});

  @override
  ConsumerState<FarmerCropsScreen> createState() => _FarmerCropsScreenState();
}

class _FarmerCropsScreenState extends ConsumerState<FarmerCropsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _search = '';
  final _searchCtrl = TextEditingController();
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() => _tabIndex = _tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PeraCoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Mis Cultivos', style: PeraCoText.h3(context)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: PeraCoColors.primary,
          unselectedLabelColor: PeraCoColors.textSecondary,
          indicatorColor: PeraCoColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: 'Guía de cultivos'),
            Tab(text: 'Mis cosechas'),
          ],
        ),
      ),
      floatingActionButton: _tabIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => HarvestFormSheet.show(context),
              backgroundColor: PeraCoColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: Text('Registrar',
                  style: PeraCoText.bodyBold(context).copyWith(color: Colors.white)),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _GuideTab(search: _search, searchCtrl: _searchCtrl,
              onSearchChanged: (v) => setState(() => _search = v)),
          const _HarvestTab(),
        ],
      ),
    );
  }
}

// ──────────────────────────── TAB 1: GUÍA ────────────────────────────

class _GuideTab extends StatelessWidget {
  final String search;
  final TextEditingController searchCtrl;
  final ValueChanged<String> onSearchChanged;

  const _GuideTab({
    required this.search,
    required this.searchCtrl,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final filtered = search.isEmpty
        ? cropsData
        : cropsData.where((c) => c.nombre.toLowerCase().contains(search.toLowerCase())).toList();

    return Column(children: [
      // Botón asesor
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
        child: GestureDetector(
          onTap: () => CropAdvisorSheet.show(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1B8F31), Color(0xFF9CC200)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(children: [
              const Text('🌱', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Asesor Agrícola', style: PeraCoText.bodyBold(context).copyWith(color: Colors.white)),
                Text('Recomendaciones según tu ubicación, clima y suelo',
                    style: const TextStyle(fontSize: 11, color: Colors.white70)),
              ])),
              const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 14),
            ]),
          ),
        ),
      ),
      // Buscador
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: TextField(
          controller: searchCtrl,
          onChanged: onSearchChanged,
          style: PeraCoText.body(context),
          decoration: InputDecoration(
            hintText: 'Buscar cultivo...',
            prefixIcon: const Icon(Icons.search, color: PeraCoColors.textHint),
            suffixIcon: search.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () { searchCtrl.clear(); onSearchChanged(''); })
                : null,
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
      Expanded(
        child: filtered.isEmpty
            ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.search_off, size: 48, color: PeraCoColors.textHint),
                const SizedBox(height: 12),
                Text('No se encontró "$search"',
                    style: PeraCoText.body(context).copyWith(color: PeraCoColors.textSecondary)),
              ]))
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.85),
                itemCount: filtered.length,
                itemBuilder: (context, i) => _CropCard(crop: filtered[i]),
              ),
      ),
    ]);
  }
}

class _CropCard extends StatelessWidget {
  final CropInfo crop;
  const _CropCard({required this.crop});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final inSeason = crop.mesesSiembra.contains(now.month);

    return GestureDetector(
      onTap: () => CropDetailSheet.show(context, crop),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: inSeason ? crop.color.withValues(alpha: 0.3) : PeraCoColors.divider),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(crop.emoji, style: const TextStyle(fontSize: 36)),
            if (inSeason)
              Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: crop.color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text('SIEMBRA', style: TextStyle(fontSize: 8, color: crop.color, fontWeight: FontWeight.w700, letterSpacing: 0.5))),
          ]),
          const SizedBox(height: 8),
          Text(crop.nombre, style: PeraCoText.bodyBold(context)),
          const SizedBox(height: 4),
          Text(crop.altitud, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const Spacer(),
          Row(children: [
            Icon(Icons.schedule, size: 12, color: PeraCoColors.textHint),
            const SizedBox(width: 4),
            Expanded(child: Text(crop.diasLabel, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textHint),
                maxLines: 1, overflow: TextOverflow.ellipsis)),
          ]),
          const SizedBox(height: 6),
          Container(height: 4, decoration: BoxDecoration(
              color: crop.color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(2))),
        ]),
      ),
    );
  }
}

// ──────────────────────────── TAB 2: MIS COSECHAS ────────────────────────────

class _HarvestTab extends ConsumerWidget {
  const _HarvestTab();

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
    final harvestAsync = ref.watch(harvestProvider);

    return harvestAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e', style: PeraCoText.body(context))),
      data: (harvests) {
        if (harvests.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.agriculture_outlined, size: 64, color: PeraCoColors.textHint),
            const SizedBox(height: 16),
            Text('Sin cosechas registradas', style: PeraCoText.bodyBold(context).copyWith(color: PeraCoColors.textSecondary)),
            const SizedBox(height: 8),
            Text('Toca "Registrar" para agregar una', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textHint)),
            const SizedBox(height: 80),
          ]));
        }

        final upcoming = harvests.where((h) => h.estado == HarvestStatus.planificado || h.estado == HarvestStatus.enCrecimiento).toList();
        final done = harvests.where((h) => h.estado == HarvestStatus.cosechado || h.estado == HarvestStatus.perdido).toList();

        return RefreshIndicator(
          onRefresh: () => ref.read(harvestProvider.notifier).load(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            children: [
              if (upcoming.isNotEmpty) ...[
                _SectionHeader(title: 'En curso', count: upcoming.length),
                const SizedBox(height: 8),
                ...upcoming.map((h) => _HarvestCard(harvest: h, statusColor: _statusColor(h.estado), formatDate: _formatDate)),
              ],
              if (done.isNotEmpty) ...[
                const SizedBox(height: 8),
                _SectionHeader(title: 'Historial', count: done.length),
                const SizedBox(height: 8),
                ...done.map((h) => _HarvestCard(harvest: h, statusColor: _statusColor(h.estado), formatDate: _formatDate)),
              ],
            ],
          ),
        );
      },
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
  final Color statusColor;
  final String Function(DateTime) formatDate;
  const _HarvestCard({required this.harvest, required this.statusColor, required this.formatDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVencido = harvest.isVencido;
    final diasRestantes = harvest.diasRestantes;
    final color = statusColor;

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
          Wrap(spacing: 12, runSpacing: 4, children: [
            _InfoChip(icon: Icons.agriculture_outlined, label: formatDate(harvest.fechaCosechaEstimada)),
            if (harvest.fechaSiembra != null)
              _InfoChip(icon: Icons.grass, label: formatDate(harvest.fechaSiembra!)),
            if (harvest.cantidadEstimada != null)
              _InfoChip(icon: Icons.scale_outlined,
                  label: '${harvest.cantidadEstimada!.toStringAsFixed(1)} ${harvest.unidad}'),
          ]),
          if (harvest.notas != null && harvest.notas!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(harvest.notas!,
                style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary),
                maxLines: 2, overflow: TextOverflow.ellipsis),
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
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: isVencido ? PeraCoColors.error : color),
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
                      TextButton(onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Eliminar', style: TextStyle(color: PeraCoColors.error))),
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
        decoration: BoxDecoration(border: Border.all(color: PeraCoColors.divider), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text('Actualizar', style: PeraCoText.caption(context)),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, size: 16, color: PeraCoColors.textSecondary),
        ]),
      ),
    );
  }
}
