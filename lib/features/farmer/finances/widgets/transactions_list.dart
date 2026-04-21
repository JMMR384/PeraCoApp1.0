import 'package:flutter/material.dart';
import 'package:peraco/core/constants/colors.dart';
import 'package:peraco/core/constants/text_styles.dart';
import 'package:peraco/features/farmer/finances/providers/finances_provider.dart';

class TransactionsList extends StatelessWidget {
  final List<Transaction> transactions;
  const TransactionsList({super.key, required this.transactions});

  String _formatPrice(double price) =>
      'COP ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

  String _formatDate(DateTime d) {
    const months = ['ene', 'feb', 'mar', 'abr', 'may', 'jun', 'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final txDay = DateTime(d.year, d.month, d.day);
    if (txDay == today) return 'Hoy ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
    if (txDay == today.subtract(const Duration(days: 1))) return 'Ayer';
    return '${d.day} ${months[d.month - 1]}';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'entregado': return PeraCoColors.success;
      case 'cancelado': return PeraCoColors.error;
      case 'en_camino': return PeraCoColors.info;
      default: return PeraCoColors.warning;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'entregado': return 'Entregado';
      case 'cancelado': return 'Cancelado';
      case 'en_camino': return 'En camino';
      case 'confirmado': return 'Confirmado';
      case 'preparando': return 'Preparando';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(32),
          child: Column(children: [
            Icon(Icons.receipt_long_outlined, size: 48, color: PeraCoColors.textHint),
            const SizedBox(height: 12),
            Text('Sin transacciones', style: PeraCoText.body(context).copyWith(color: PeraCoColors.textSecondary)),
          ])));
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactions.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 56),
      itemBuilder: (context, i) {
        final tx = transactions[i];
        final color = _statusColor(tx.status);
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
          leading: Container(width: 40, height: 40,
              decoration: BoxDecoration(color: PeraCoColors.greenPastel, borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.eco_outlined, color: PeraCoColors.primary, size: 20)),
          title: Text(tx.productName, style: PeraCoText.bodyBold(context), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Row(children: [
            Text('${tx.quantity} ${tx.unit}  ·  ${_formatDate(tx.date)}',
                style: PeraCoText.caption(context).copyWith(color: PeraCoColors.textSecondary)),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(_statusLabel(tx.status),
                    style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600))),
          ]),
          trailing: Text(_formatPrice(tx.amount),
              style: PeraCoText.bodyBold(context).copyWith(color: PeraCoColors.primary)),
        );
      },
    );
  }
}
