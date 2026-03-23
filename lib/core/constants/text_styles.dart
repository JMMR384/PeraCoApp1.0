import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tamaños de fuente estandarizados para toda la app.
/// Anton para títulos, Poppins para cuerpo.
class PeraCoText {
  PeraCoText._();

  static double _scale(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width <= 360) return 0.85;
    if (width <= 400) return 0.95;
    if (width <= 420) return 1.0;
    if (width <= 600) return 1.05;
    return 1.1;
  }

  // Titulos - Anton
  static TextStyle h1(BuildContext context) => GoogleFonts.poppins(
    fontSize: 28 * _scale(context),
    fontWeight: FontWeight.normal,
    height: 1.6,
  );

  static TextStyle h2(BuildContext context) => GoogleFonts.poppins(
    fontSize: 22 * _scale(context),
    fontWeight: FontWeight.normal,
    height: 1.3,
  );

  static TextStyle h3(BuildContext context) => GoogleFonts.poppins(
    fontSize: 19 * _scale(context),
    fontWeight: FontWeight.normal,
    height: 1.3,
  );

  // Cuerpo - Poppins
  static TextStyle body(BuildContext context) => GoogleFonts.poppins(
    fontSize: 17 * _scale(context),
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  static TextStyle bodyBold(BuildContext context) => GoogleFonts.poppins(
    fontSize: 17 * _scale(context),
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static TextStyle bodySmall(BuildContext context) => GoogleFonts.poppins(
    fontSize: 15 * _scale(context),
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  // Detalles - Poppins
  static TextStyle caption(BuildContext context) => GoogleFonts.poppins(
    fontSize: 14 * _scale(context),
    fontWeight: FontWeight.normal,
    height: 1.3,
  );

  static TextStyle label(BuildContext context) => GoogleFonts.poppins(
    fontSize: 16 * _scale(context),
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  // Precios - Poppins
  static TextStyle price(BuildContext context) => GoogleFonts.poppins(
    fontSize: 17 * _scale(context),
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  static TextStyle priceLarge(BuildContext context) => GoogleFonts.poppins(
    fontSize: 22 * _scale(context),
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  // Botones - Poppins
  static TextStyle button(BuildContext context) => GoogleFonts.poppins(
    fontSize: 17 * _scale(context),
    fontWeight: FontWeight.w600,
    height: 1.2,
  );
}