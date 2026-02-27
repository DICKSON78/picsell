import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// PicSell Studio - Modern Purple Theme
/// Matches React Native design with Purple + Cyan gradient theme
class AppTheme {
  // ============================================
  // PRIMARY COLORS - Purple/Violet
  // ============================================
  static const Color primaryColor = Color(0xFF7C3AED);      // Main Purple
  static const Color primaryDark = Color(0xFF6D28D9);       // Deep Purple
  static const Color primaryLight = Color(0xFFA78BFA);      // Light Purple
  static const Color primarySoft = Color(0xFFEDE9FE);       // Very Light Purple (backgrounds)

  // ============================================
  // ACCENT COLORS - Colorful Icons
  // ============================================
  static const Color accent = Color(0xFF06B6D4);            // Cyan/Teal
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
  // TAB BAR - Dark Style
  // ============================================
  static const Color tabBar = Color(0xFF1F2937);            // Dark Gray
  static const Color tabBarActive = Color(0xFFFFFFFF);      // White Active
  static const Color tabBarInactive = Color(0xFF9CA3AF);    // Gray Inactive

  // ============================================
  // TEXT COLORS
  // ============================================
  static const Color text = Color(0xFF111827);              // Dark Text
  static const Color textSecondary = Color(0xFF6B7280);     // Gray Text
  static const Color textLight = Color(0xFF9CA3AF);         // Light Gray Text
  static const Color textWhite = Color(0xFFFFFFFF);         // White Text

  // Legacy color names for compatibility
  static const Color blackColor = Color(0xFF111827);
  static const Color whiteColor = Color(0xFFFFFFFF);
  static const Color greyColor = Color(0xFF6B7280);
  static const Color lightGreyColor = Color(0xFFF3F4F6);

  // ============================================
  // STATUS COLORS
  // ============================================
  static const Color success = Color(0xFF10B981);           // Green
  static const Color error = Color(0xFFEF4444);             // Red
  static const Color warning = Color(0xFFF59E0B);           // Orange
  static const Color info = Color(0xFF06B6D4);              // Cyan

  // ============================================
  // BORDER & DIVIDER
  // ============================================
  static const Color border = Color(0xFFE5E7EB);
  static const Color divider = Color(0xFFF3F4F6);

  // ============================================
  // ICON BACKGROUNDS (circular colored icons)
  // ============================================
  static const Color iconBgPurple = Color(0xFFEDE9FE);
  static const Color iconBgCyan = Color(0xFFCFFAFE);
  static const Color iconBgPink = Color(0xFFFCE7F3);
  static const Color iconBgGreen = Color(0xFFD1FAE5);
  static const Color iconBgOrange = Color(0xFFFEF3C7);
  static const Color iconBgBlue = Color(0xFFDBEAFE);

  // ============================================
  // SPACING
  // ============================================
  static const double spacingXs = 4;
  static const double spacingSm = 8;
  static const double spacingMd = 16;
  static const double spacingLg = 24;
  static const double spacingXl = 32;
  static const double spacingXxl = 48;

  // ============================================
  // BORDER RADIUS
  // ============================================
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 24;
  static const double radiusRound = 999;

  // ============================================
  // FONT SIZES
  // ============================================
  static const double fontSizeXs = 12;
  static const double fontSizeSm = 14;
  static const double fontSizeMd = 16;
  static const double fontSizeLg = 18;
  static const double fontSizeXl = 24;
  static const double fontSizeXxl = 32;
  static const double fontSizeXxxl = 48;

  // ============================================
  // TYPOGRAPHY - Poppins Font
  // ============================================
  static TextStyle get poppins => GoogleFonts.poppins();

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
  // THEME DATA
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
            fontSize: fontSizeMd,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusXl),
          ),
          padding: const EdgeInsets.symmetric(horizontal: spacingMd, vertical: spacingSm),
          textStyle: GoogleFonts.poppins(
            fontSize: fontSizeMd,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.poppins(
          color: text,
          fontSize: fontSizeXxxl,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: GoogleFonts.poppins(
          color: text,
          fontSize: fontSizeXxl,
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: GoogleFonts.poppins(
          color: text,
          fontSize: fontSizeXl,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: GoogleFonts.poppins(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.poppins(
          color: text,
          fontSize: fontSizeMd,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: GoogleFonts.poppins(
          color: textSecondary,
          fontSize: fontSizeSm,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: GoogleFonts.poppins(
          color: whiteColor,
          fontSize: fontSizeSm,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: tabBar,
        selectedItemColor: tabBarActive,
        unselectedItemColor: tabBarInactive,
        elevation: 8,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.poppins(
          fontSize: fontSizeXs,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.poppins(
          fontSize: fontSizeXs,
          fontWeight: FontWeight.normal,
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: primarySoft,
        circularTrackColor: primarySoft,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusLg),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.all(spacingMd),
        hintStyle: GoogleFonts.poppins(
          color: textLight,
          fontSize: fontSizeMd,
        ),
      ),
    );
  }

  // ============================================
  // GRADIENTS
  // ============================================

  /// Main gradient: Purple to Cyan (for backgrounds)
  static LinearGradient get primaryGradient {
    return const LinearGradient(
      colors: [primaryColor, primaryLight, accent],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Simple purple gradient (for buttons)
  static LinearGradient get purpleGradient {
    return const LinearGradient(
      colors: [primaryColor, primaryDark],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Accent gradient (cyan)
  static LinearGradient get accentGradient {
    return const LinearGradient(
      colors: [accent, Color(0xFF22D3EE)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  /// Card gradient (white to soft purple)
  static LinearGradient get cardGradient {
    return const LinearGradient(
      colors: [whiteColor, primarySoft],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  /// Vertical gradient for splash/onboarding
  static LinearGradient get verticalGradient {
    return const LinearGradient(
      colors: [primaryColor, primaryLight],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );
  }

  // ============================================
  // BOX SHADOWS
  // ============================================

  /// Small shadow
  static List<BoxShadow> get shadowSm {
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];
  }

  /// Medium shadow with purple tint
  static List<BoxShadow> get shadowMd {
    return [
      BoxShadow(
        color: primaryColor.withOpacity(0.3),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ];
  }

  /// Large shadow with purple tint
  static List<BoxShadow> get shadowLg {
    return [
      BoxShadow(
        color: primaryColor.withOpacity(0.4),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ];
  }

  /// Cyan glow effect
  static List<BoxShadow> get shadowGlow {
    return [
      BoxShadow(
        color: accent.withOpacity(0.8),
        blurRadius: 20,
        offset: Offset.zero,
      ),
    ];
  }

  /// Card shadow (legacy)
  static List<BoxShadow> get cardShadowList {
    return shadowSm;
  }

  /// Button shadow (legacy)
  static List<BoxShadow> get buttonShadowList {
    return shadowMd;
  }
}
