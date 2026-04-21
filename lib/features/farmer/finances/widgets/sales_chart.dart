import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/features/farmer/finances/providers/finances_provider.dart';

class WeeklySalesChart extends StatelessWidget {
  final List<DailySale> data;
  const WeeklySalesChart({super.key, required this.data});

  String _dayLabel(DateTime d) {
    const days = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
    return days[d.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final maxY = data.map((e) => e.amount).fold(0.0, (a, b) => a > b ? a : b);
    final yMax = maxY == 0 ? 100.0 : (maxY * 1.25).ceilToDouble();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Ultimos 7 dias', style: PeraCoText.bodyBold(context)),
      const SizedBox(height: 4),
      Text('Ingresos por dia', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
      const SizedBox(height: 16),
      SizedBox(height: 180, child: BarChart(
        BarChartData(
          maxY: yMax,
          gridData: FlGridData(
            show: true, drawVerticalLine: false,
            horizontalInterval: yMax / 4,
            getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFEEEEEE), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(padding: const EdgeInsets.only(top: 6),
                    child: Text(_dayLabel(data[i].date),
                        style: PeraCoText.caption(context).copyWith(fontSize: 10, color: PeraCoColors.textHint)));
              },
            )),
          ),
          barGroups: List.generate(data.length, (i) {
            final isToday = i == data.length - 1;
            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: data[i].amount == 0 ? 0.5 : data[i].amount,
                color: isToday ? PeraCoColors.primary : PeraCoColors.primary.withValues(alpha: 0.35),
                width: 22, borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ]);
          }),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => PeraCoColors.primaryDark,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final amount = data[group.x].amount;
                if (amount == 0) return null;
                return BarTooltipItem(
                  'COP ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                  const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                );
              },
            ),
          ),
        ),
      )),
    ]);
  }
}

class MonthlySalesChart extends StatelessWidget {
  final List<MonthlySale> data;
  const MonthlySalesChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final maxY = data.map((e) => e.amount).fold(0.0, (a, b) => a > b ? a : b);
    final yMax = maxY == 0 ? 100.0 : (maxY * 1.25).ceilToDouble();

    final spots = List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i].amount));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Ultimos 6 meses', style: PeraCoText.bodyBold(context)),
      const SizedBox(height: 4),
      Text('Tendencia mensual', style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
      const SizedBox(height: 16),
      SizedBox(height: 180, child: LineChart(
        LineChartData(
          minY: 0, maxY: yMax,
          gridData: FlGridData(
            show: true, drawVerticalLine: false,
            horizontalInterval: yMax / 4,
            getDrawingHorizontalLine: (_) => const FlLine(color: Color(0xFFEEEEEE), strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= data.length) return const SizedBox.shrink();
                return Padding(padding: const EdgeInsets.only(top: 6),
                    child: Text(data[i].label,
                        style: PeraCoText.caption(context).copyWith(fontSize: 10, color: PeraCoColors.textHint)));
              },
            )),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true, curveSmoothness: 0.3,
              color: PeraCoColors.primary,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                  radius: 4, color: PeraCoColors.primary,
                  strokeColor: Colors.white, strokeWidth: 2,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [PeraCoColors.primary.withValues(alpha: 0.2), PeraCoColors.primary.withValues(alpha: 0.0)],
                ),
              ),
            ),
          ],
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => PeraCoColors.primaryDark,
              getTooltipItems: (spots) => spots.map((s) {
                final amount = s.y;
                return LineTooltipItem(
                  'COP ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                  const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                );
              }).toList(),
            ),
          ),
        ),
      )),
    ]);
  }
}
