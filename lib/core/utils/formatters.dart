import 'package:intl/intl.dart';

class AppFormatters {
  AppFormatters._();

  static String currency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  static String date(DateTime date) {
    final formatter = DateFormat("d 'de' MMMM, yyyy", 'es_CO');
    return formatter.format(date);
  }

  static String dateShort(DateTime date) {
    final formatter = DateFormat('d MMM yyyy', 'es_CO');
    return formatter.format(date);
  }

  static String time(DateTime date) {
    final formatter = DateFormat('h:mm a', 'es_CO');
    return formatter.format(date);
  }

  static String orderNumber(int id) {
    final year = DateTime.now().year;
    return '#PRC-$year-${id.toString().padLeft(4, '0')}';
  }
}
