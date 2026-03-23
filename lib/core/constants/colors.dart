import 'package:flutter/material.dart';

/// Paleta de colores oficial de PeraCo
/// Basada en el manual de marca del founder
class PeraCoColors {
  PeraCoColors._();

  // Colores principales
  static const Color primaryLight = Color(0xFF9CC200);  // Verde lima
  static const Color primary = Color(0xFF1B8F31);       // Verde medio (principal)
  static const Color primaryDark = Color(0xFF16502D);   // Verde oscuro

  // Colores de fondo
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF5F5F5);

  // Colores de texto
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);

  // Colores de estado
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFFA726);
  static const Color info = Color(0xFF42A5F5);

  // Colores de pedido
  static const Color orderPending = Color(0xFFFFA726);
  static const Color orderConfirmed = Color(0xFF42A5F5);
  static const Color orderPreparing = Color(0xFFFF7043);
  static const Color orderShipped = Color(0xFF9CC200);
  static const Color orderDelivered = Color(0xFF1B8F31);
  static const Color orderCancelled = Color(0xFFE53935);

  // Colores auxiliares
  static const Color divider = Color(0xFFE0E0E0);
  static const Color shadow = Color(0x1A000000);
  static const Color overlay = Color(0x80000000);

  // Fondos pasteles para tarjetas
  static const Color greenPastel = Color(0xFFE8F5E9);
  static const Color limePastel = Color(0xFFF1F8E9);
  static const Color bluePastel = Color(0xFFE3F2FD);
  static const Color yellowPastel = Color(0xFFFFF8E1);
}
