import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:peraco/core/config/supabase_config.dart';
import 'package:peraco/features/auth/providers/auth_provider.dart';

class DailySale {
  final DateTime date;
  final double amount;
  const DailySale({required this.date, required this.amount});
}

class MonthlySale {
  final String label; // "Ene", "Feb", etc.
  final double amount;
  const MonthlySale({required this.label, required this.amount});
}

class Transaction {
  final String pedidoId;
  final String productName;
  final DateTime date;
  final double amount;
  final int quantity;
  final String unit;
  final String status;
  const Transaction({
    required this.pedidoId,
    required this.productName,
    required this.date,
    required this.amount,
    required this.quantity,
    required this.unit,
    required this.status,
  });
}

class FinancesSummary {
  final double today;
  final double thisWeek;
  final double thisMonth;
  final double total;
  final int orderCount;
  final double avgTicket;
  final String? topProduct;
  final List<DailySale> last7Days;
  final List<MonthlySale> last6Months;
  final List<Transaction> transactions;

  const FinancesSummary({
    required this.today,
    required this.thisWeek,
    required this.thisMonth,
    required this.total,
    required this.orderCount,
    required this.avgTicket,
    this.topProduct,
    required this.last7Days,
    required this.last6Months,
    required this.transactions,
  });
}

final _monthLabels = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];

final financesProvider = FutureProvider<FinancesSummary>((ref) async {
  final userId = ref.read(authProvider).user?.id;
  if (userId == null) return _empty();

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final weekStart = today.subtract(Duration(days: today.weekday - 1));
  final monthStart = DateTime(now.year, now.month, 1);

  final data = await SupabaseConfig.client
      .from('pedido_items')
      .select('nombre_producto, cantidad, unidad, subtotal, pedido:pedidos!pedido_id(id, estado, created_at)')
      .eq('vendedor_id', userId)
      .order('created_at', referencedTable: 'pedidos', ascending: false);

  final items = data as List;
  if (items.isEmpty) return _empty();

  double todayTotal = 0, weekTotal = 0, monthTotal = 0, grandTotal = 0;
  final Set<String> pedidoIds = {};
  final Map<String, double> productTotals = {};
  final Map<String, double> dailyMap = {};
  final Map<String, double> monthlyMap = {};
  final List<Transaction> transactions = [];

  for (final item in items) {
    final pedido = item['pedido'] as Map<String, dynamic>;
    final estado = pedido['estado'] as String? ?? '';
    if (estado == 'cancelado') continue;

    final pedidoId = pedido['id'] as String;
    final createdStr = pedido['created_at'] as String;
    final created = DateTime.parse(createdStr).toLocal();
    final createdDay = DateTime(created.year, created.month, created.day);

    final subtotal = (item['subtotal'] as num).toDouble();
    final productName = item['nombre_producto'] as String? ?? 'Producto';
    final qty = (item['cantidad'] as num).toInt();
    final unit = item['unidad'] as String? ?? '';

    grandTotal += subtotal;
    pedidoIds.add(pedidoId);
    productTotals[productName] = (productTotals[productName] ?? 0) + subtotal;

    if (!createdDay.isBefore(today)) todayTotal += subtotal;
    if (!createdDay.isBefore(weekStart)) weekTotal += subtotal;
    if (!createdDay.isBefore(monthStart)) monthTotal += subtotal;

    // Daily map for last 7 days
    if (!createdDay.isBefore(today.subtract(const Duration(days: 6)))) {
      final key = '${createdDay.year}-${createdDay.month.toString().padLeft(2, '0')}-${createdDay.day.toString().padLeft(2, '0')}';
      dailyMap[key] = (dailyMap[key] ?? 0) + subtotal;
    }

    // Monthly map for last 6 months
    final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
    if (!created.isBefore(sixMonthsAgo)) {
      final key = '${created.year}-${created.month.toString().padLeft(2, '0')}';
      monthlyMap[key] = (monthlyMap[key] ?? 0) + subtotal;
    }

    transactions.add(Transaction(
      pedidoId: pedidoId, productName: productName,
      date: created, amount: subtotal, quantity: qty, unit: unit, status: estado,
    ));
  }

  // Build last 7 days list
  final last7Days = List.generate(7, (i) {
    final day = today.subtract(Duration(days: 6 - i));
    final key = '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    return DailySale(date: day, amount: dailyMap[key] ?? 0);
  });

  // Build last 6 months list
  final last6Months = List.generate(6, (i) {
    final month = DateTime(now.year, now.month - 5 + i, 1);
    final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    return MonthlySale(label: _monthLabels[month.month - 1], amount: monthlyMap[key] ?? 0);
  });

  final orderCount = pedidoIds.length;
  final avgTicket = orderCount > 0 ? grandTotal / orderCount : 0.0;
  final topProduct = productTotals.isEmpty ? null
      : productTotals.entries.reduce((a, b) => a.value > b.value ? a : b).key;

  return FinancesSummary(
    today: todayTotal, thisWeek: weekTotal, thisMonth: monthTotal, total: grandTotal,
    orderCount: orderCount, avgTicket: avgTicket, topProduct: topProduct,
    last7Days: last7Days, last6Months: last6Months, transactions: transactions,
  );
});

FinancesSummary _empty() => const FinancesSummary(
  today: 0, thisWeek: 0, thisMonth: 0, total: 0,
  orderCount: 0, avgTicket: 0, topProduct: null,
  last7Days: [], last6Months: [], transactions: [],
);
