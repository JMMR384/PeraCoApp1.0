import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/features/farmer/finances/providers/finances_provider.dart';
import 'package:peraco/features/farmer/finances/widgets/sales_chart.dart';
import 'package:peraco/features/farmer/finances/widgets/sales_summary_card.dart';
import 'package:peraco/features/farmer/finances/widgets/transactions_list.dart';

class FarmerFinancesScreen extends ConsumerStatefulWidget {
  const FarmerFinancesScreen({super.key});

  @override
  ConsumerState<FarmerFinancesScreen> createState() => _FarmerFinancesScreenState();
}

class _FarmerFinancesScreenState extends ConsumerState<FarmerFinancesScreen> {
  // 0 = semanal, 1 = mensual
  int _chartTab = 0;

  String _formatPrice(double price) =>
      'COP ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    final financesAsync = ref.watch(financesProvider);

    return Scaffold(
      backgroundColor: PeraCoColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('Mis Finanzas', style: PeraCoText.h3(context)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(financesProvider),
          ),
        ],
      ),
      body: financesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 48, color: PeraCoColors.error),
          const SizedBox(height: 12),
          Text('Error al cargar finanzas', style: PeraCoText.body(context)),
          const SizedBox(height: 8),
          ElevatedButton(onPressed: () => ref.invalidate(financesProvider), child: const Text('Reintentar')),
        ])),
        data: (f) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(financesProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Resumen de ventas — 4 tarjetas
              Text('Resumen de ventas', style: PeraCoText.h3(context)),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
                shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.55,
                children: [
                  SalesSummaryCard(label: 'Hoy', value: _formatPrice(f.today),
                      icon: Icons.today, color: PeraCoColors.primary, subtitle: 'HOY'),
                  SalesSummaryCard(label: 'Esta semana', value: _formatPrice(f.thisWeek),
                      icon: Icons.date_range, color: const Color(0xFF66BB6A), subtitle: '7 DIAS'),
                  SalesSummaryCard(label: 'Este mes', value: _formatPrice(f.thisMonth),
                      icon: Icons.calendar_month, color: PeraCoColors.info, subtitle: 'MES'),
                  SalesSummaryCard(label: 'Total acumulado', value: _formatPrice(f.total),
                      icon: Icons.account_balance_wallet, color: PeraCoColors.primaryLight),
                ],
              ),
              const SizedBox(height: 20),

              // KPIs secundarios
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: PeraCoColors.divider)),
                child: Row(children: [
                  _KpiItem(label: 'Pedidos', value: '${f.orderCount}', icon: Icons.shopping_bag_outlined),
                  _Divider(),
                  _KpiItem(label: 'Ticket prom.', value: _formatPrice(f.avgTicket), icon: Icons.receipt_outlined),
                  _Divider(),
                  _KpiItem(label: 'Top producto', value: f.topProduct ?? '-',
                      icon: Icons.star_outline, small: true),
                ]),
              ),
              const SizedBox(height: 24),

              // Gráfica — toggle semanal/mensual
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: PeraCoColors.divider)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Tabs
                  Container(
                    height: 36,
                    decoration: BoxDecoration(color: PeraCoColors.surfaceVariant, borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      _ChartTab(label: '7 dias', active: _chartTab == 0, onTap: () => setState(() => _chartTab = 0)),
                      _ChartTab(label: '6 meses', active: _chartTab == 1, onTap: () => setState(() => _chartTab = 1)),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: _chartTab == 0
                        ? WeeklySalesChart(key: const ValueKey('weekly'), data: f.last7Days)
                        : MonthlySalesChart(key: const ValueKey('monthly'), data: f.last6Months),
                  ),
                ]),
              ),
              const SizedBox(height: 24),

              // Historial de transacciones
              Text('Historial de transacciones', style: PeraCoText.h3(context)),
              const SizedBox(height: 4),
              Text('${f.transactions.length} registros', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: PeraCoColors.divider)),
                child: TransactionsList(transactions: f.transactions),
              ),
              const SizedBox(height: 32),
            ]),
          ),
        ),
      ),
    );
  }
}

class _KpiItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool small;
  const _KpiItem({required this.label, required this.value, required this.icon, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: Column(children: [
      Icon(icon, color: PeraCoColors.primary, size: 20),
      const SizedBox(height: 6),
      Text(value, style: small
          ? PeraCoText.caption(context).copyWith(fontWeight: FontWeight.w700, color: PeraCoColors.textPrimary)
          : PeraCoText.bodyBold(context).copyWith(color: PeraCoColors.textPrimary),
          maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center),
      const SizedBox(height: 2),
      Text(label, style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary, fontSize: 10),
          textAlign: TextAlign.center),
    ]));
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 48, color: PeraCoColors.divider, margin: const EdgeInsets.symmetric(horizontal: 8));
}

class _ChartTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _ChartTab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
            color: active ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)] : []),
        child: Center(child: Text(label, style: PeraCoText.label(context).copyWith(
            color: active ? PeraCoColors.primaryDark : PeraCoColors.textHint,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal))),
      ),
    ));
  }
}
