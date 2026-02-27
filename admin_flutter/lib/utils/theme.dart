import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// PicSell Admin - Modern Purple Theme
/// Matches customer app design with Purple + Cyan gradient theme
class AppTheme {
  // ============================================
  // PRIMARY COLORS - Purple/Violet
  // ============================================
  static const Color primaryColor = Color(0xFF7C3AED);      // Main Purple
  static const Color primaryDark = Color(0xFF6D28D9);       // Deep Purple
  static const Color primaryLight = Color(0xFFA78BFA);      // Light Purple
  static const Color primarySoft = Color(0xFFEDE9FE);       // Very Light Purple

  // ============================================
  // ACCENT COLORS - Colorful Icons
  // ============================================
  static const Color accentColor = Color(0xFF06B6D4);       // Cyan/Teal
  static const Color accent = Color(0xFF06B6D4);
  static const Color accentPink = Color(0xFFEC4899);        // Pink
  static const Color accentGreen = Color(0xFF10B981);       // Green
  static const Color accentOrange = Color(0xFFF59E0B);      // Orange
  static const Color accentBlue = Color(0xFF3B82F6);        // Blue

  // ============================================
  // BACKGROUND COLORS - Light Theme
  // ============================================
  static const Color backgroundColor = Color(0xFFF8FAFC);   // Light Gray Background
  static const Color surface = Color(0xFFFFFFFF);           // White Surface
  static const Color card = Color(0xFFFFFFFF);              // White Card

  // ============================================
  // TEXT COLORS
  // ============================================
  static const Color text = Color(0xFF111827);              // Dark Text
  static const Color textSecondary = Color(0xFF6B7280);     // Gray Text
  static const Color textLight = Color(0xFF9CA3AF);         // Light Gray Text
  static const Color textWhite = Color(0xFFFFFFFF);         // White Text
  static const Color whiteColor = Color(0xFFFFFFFF);

  // ============================================
  // STATUS COLORS
  // ============================================
  static const Color success = Color(0xFF10B981);           // Green
  static const Color successColor = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);             // Red
  static const Color warning = Color(0xFFF59E0B);           // Orange
  static const Color info = Color(0xFF06B6D4);              // Cyan
  static const Color goldColor = Color(0xFFFFD700);

  // ============================================
  // BORDER & DIVIDER
  // ============================================
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  // ============================================
  // ICON BACKGROUNDS
  // ============================================
  static const Color iconBgPurple = Color(0xFFEDE9FE);
  static const Color iconBgCyan = Color(0xFFCFFAFE);
  static const Color iconBgPink = Color(0xFFFCE7F3);
  static const Color iconBgGreen = Color(0xFFD1FAE5);
  static const Color iconBgOrange = Color(0xFFFEF3C7);
  static const Color iconBgBlue = Color(0xFFDBEAFE);
  static const Color iconBgRed = Color(0xFFFEE2E2);

  // Dark theme colors
  static const Color darkBackground = Color(0xFF0F0F1E);
  static const Color cardBackground = Color(0xFF1A1A2E);
  static const Color surfaceColor = Color(0xFF16213E);

  // ============================================
  // SPACING
  // ============================================
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;

  // ============================================
  // BORDER RADIUS
  // ============================================
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;

  // ============================================
  // TYPOGRAPHY - Poppins Font
  // ============================================
  static TextStyle poppinsRegular({double? fontSize, Color? color}) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: FontWeight.w400,
      color: color,
    );
  }

  static TextStyle poppinsMedium({double? fontSize, Color? color}) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: color,
    );
  }

  static TextStyle poppinsSemiBold({double? fontSize, Color? color}) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  static TextStyle poppinsBold({double? fontSize, Color? color}) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: color,
    );
  }

  // ============================================
  // LIGHT THEME (matching customer app)
  // ============================================
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        secondary: accent,
        surface: surface,
        error: error,
        onPrimary: whiteColor,
        onSecondary: whiteColor,
        onSurface: text,
        onError: whiteColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: text,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: text,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 2,
        shadowColor: primaryColor.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: whiteColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl),
          ),
          padding: const EdgeInsets.symmetric(horizontal: spacingMd, vertical: spacingSm),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(color: text, fontSize: 48, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.poppins(color: text, fontSize: 32, fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.poppins(color: text, fontSize: 24, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.poppins(color: text, fontSize: 20, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.poppins(color: text, fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.poppins(color: text, fontSize: 16),
        bodyMedium: GoogleFonts.poppins(color: textSecondary, fontSize: 14),
        labelLarge: GoogleFonts.poppins(color: whiteColor, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.all(spacingMd),
        hintStyle: GoogleFonts.poppins(color: textLight),
      ),
    );
  }

  // ============================================
  // DARK THEME
  // ============================================
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        secondary: accent,
        surface: cardBackground,
        error: error,
        onPrimary: whiteColor,
        onSecondary: whiteColor,
        onSurface: whiteColor,
        onError: whiteColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: whiteColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: whiteColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardBackground,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          side: const BorderSide(color: Color(0x33FFFFFF), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: whiteColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl),
          ),
          padding: const EdgeInsets.symmetric(horizontal: spacingMd, vertical: spacingSm),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(color: whiteColor, fontSize: 48, fontWeight: FontWeight.bold),
        displayMedium: GoogleFonts.poppins(color: whiteColor, fontSize: 32, fontWeight: FontWeight.bold),
        headlineLarge: GoogleFonts.poppins(color: whiteColor, fontSize: 24, fontWeight: FontWeight.bold),
        headlineMedium: GoogleFonts.poppins(color: whiteColor, fontSize: 20, fontWeight: FontWeight.w600),
        titleLarge: GoogleFonts.poppins(color: whiteColor, fontSize: 18, fontWeight: FontWeight.w600),
        bodyLarge: GoogleFonts.poppins(color: whiteColor, fontSize: 16),
        bodyMedium: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
        labelLarge: GoogleFonts.poppins(color: whiteColor, fontSize: 14, fontWeight: FontWeight.w600),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0x33FFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: Color(0x33FFFFFF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: Color(0x33FFFFFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: accent),
        ),
        contentPadding: const EdgeInsets.all(spacingMd),
        hintStyle: GoogleFonts.poppins(color: Colors.white54),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: cardBackground,
        selectedItemColor: accent,
        unselectedItemColor: Colors.white60,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  // ============================================
  // GRADIENTS
  // ============================================
  static LinearGradient get primaryGradient {
    return const LinearGradient(
      colors: [primaryColor, primaryLight, accent],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static LinearGradient get purpleGradient {
    return const LinearGradient(
      colors: [primaryColor, primaryDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryColor, Color(0xFF5A4FCF)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accentColor, Color(0xFF00B8E6)],
  );

  // ============================================
  // BOX SHADOWS
  // ============================================
  static List<BoxShadow> get shadowSm {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];
  }

  static List<BoxShadow> get shadowMd {
    return [
      BoxShadow(
        color: primaryColor.withOpacity(0.3),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];
  }

  static List<BoxShadow> get shadowLg {
    return [
      BoxShadow(
        color: primaryColor.withOpacity(0.4),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static List<BoxShadow> get cardShadow => shadowMd;

  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: accentColor.withOpacity(0.4),
      blurRadius: 15,
      offset: const Offset(0, 8),
    ),
  ];
}
