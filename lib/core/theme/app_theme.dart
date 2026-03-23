import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:peraco/core/constants/colors.dart';

/// Tema global de la aplicacion PeraCo
class PeraCoTheme {
  PeraCoTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: PeraCoColors.primary,
        primaryContainer: PeraCoColors.primaryLight,
        secondary: PeraCoColors.primaryLight,
        secondaryContainer: PeraCoColors.limePastel,
        surface: PeraCoColors.surface,
        error: PeraCoColors.error,
        onPrimary: Colors.white,
        onSecondary: PeraCoColors.primaryDark,
        onSurface: PeraCoColors.textPrimary,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: PeraCoColors.surface,
        foregroundColor: PeraCoColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: _buildTextTheme(),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: PeraCoColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: PeraCoColors.primary,
          minimumSize: const Size(double.infinity, 52),
          side: const BorderSide(color: PeraCoColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: PeraCoColors.primary,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PeraCoColors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PeraCoColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PeraCoColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: PeraCoColors.error, width: 1.5),
        ),
        hintStyle: const TextStyle(
          color: PeraCoColors.textHint,
          fontSize: 14,
        ),
        prefixIconColor: PeraCoColors.textSecondary,
      ),
      cardTheme: CardThemeData(
        color: PeraCoColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: PeraCoColors.divider, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: PeraCoColors.surfaceVariant,
        selectedColor: PeraCoColors.limePastel,
        labelStyle: const TextStyle(fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: PeraCoColors.surface,
        selectedItemColor: PeraCoColors.primary,
        unselectedItemColor: PeraCoColors.textHint,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: PeraCoColors.divider,
        thickness: 0.5,
        space: 0,
      ),
    );
  }

  static TextTheme _buildTextTheme() {
    return GoogleFonts.poppinsTextTheme(const TextTheme(
      bodyLarge: TextStyle(fontSize: 16, color: PeraCoColors.textPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: PeraCoColors.textPrimary),
      bodySmall: TextStyle(fontSize: 12, color: PeraCoColors.textSecondary),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(fontSize: 11, color: PeraCoColors.textSecondary),
    ));
  }
}
