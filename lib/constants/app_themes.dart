import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium brand palette for Hotel POS System.
///
/// Design language: dark-first, warm gold accent on deep charcoal.
/// Inspired by high-end restaurant POS hardware (Toast, Lightspeed) where
/// the UI feels like a tool, not a toy.
class BrandColors {
  BrandColors._();

  // Primary accent — warm gold (appetite/affordable-luxury association)
  static const Color gold = Color(0xFFD4AF37);
  static const Color goldBright = Color(0xFFF4D47C);
  static const Color goldDim = Color(0xFFB8941F);

  // Surfaces — deep charcoal, not pure black (easier on eyes in a kitchen)
  static const Color charcoal = Color(0xFF1A1A1A);
  static const Color charcoalLight = Color(0xFF242424);
  static const Color charcoalCard = Color(0xFF2A2A2A);

  // Light theme surfaces
  static const Color cream = Color(0xFFFAF8F5);
  static const Color creamCard = Color(0xFFFFFFFF);
  static const Color creamBorder = Color(0xFFE8E2D8);

  // Semantic
  static const Color success = Color(0xFF4CAF7A);
  static const Color warning = Color(0xFFE8A33D);
  static const Color danger = Color(0xFFE0584F);
}

class AppThemes {
  /// The default, signature theme — dark charcoal with gold accent.
  static final ThemeData darkTheme = _buildDark(BrandColors.charcoal);

  /// AMOLED true-black theme — for OLED screens (battery + contrast).
  static final ThemeData amoledTheme = _buildDark(Colors.black);

  /// Light theme — warm cream with gold accent (daylight / outdoor use).
  static final ThemeData lightTheme = _buildLight();

  static ThemeData _buildDark(Color surface) {
    final scheme = ColorScheme.dark(
      primary: BrandColors.gold,
      onPrimary: BrandColors.charcoal,
      primaryContainer: BrandColors.goldDim,
      onPrimaryContainer: BrandColors.goldBright,
      secondary: BrandColors.goldBright,
      onSecondary: BrandColors.charcoal,
      surface: surface,
      onSurface: Colors.white,
      surfaceContainerHighest: surface == Colors.black
          ? BrandColors.charcoalLight
          : surface.withValues(alpha: 0.6),
      error: BrandColors.danger,
      onError: Colors.white,
      outline: Colors.white24,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      canvasColor: surface,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface == Colors.black
            ? BrandColors.charcoalLight
            : BrandColors.charcoalCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: Colors.white.withValues(alpha: 0.08),
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: BrandColors.gold.withValues(alpha: 0.18),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? BrandColors.gold : Colors.white60,
            letterSpacing: 0.1,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? BrandColors.gold : Colors.white54,
            size: 24,
          );
        }),
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        selectedIconTheme: const IconThemeData(color: BrandColors.gold, size: 26),
        unselectedIconTheme: const IconThemeData(color: Colors.white54, size: 22),
        selectedLabelTextStyle: GoogleFonts.plusJakartaSans(
          color: BrandColors.gold,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: GoogleFonts.plusJakartaSans(
          color: Colors.white54,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface == Colors.black
            ? BrandColors.charcoalLight
            : BrandColors.charcoalCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BrandColors.gold, width: 1.5),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(color: Colors.white60),
        hintStyle: GoogleFonts.plusJakartaSans(color: Colors.white38),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandColors.gold,
          foregroundColor: BrandColors.charcoal,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: BrandColors.gold,
          side: const BorderSide(color: BrandColors.gold, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: BrandColors.gold,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: BrandColors.charcoalCard,
        selectedColor: BrandColors.gold.withValues(alpha: 0.2),
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: BrandColors.gold,
        foregroundColor: BrandColors.charcoal,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      listTileTheme: ListTileThemeData(
        textColor: Colors.white,
        iconColor: BrandColors.gold,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        subtitleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: Colors.white54,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: BrandColors.charcoalLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: Colors.white70,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: BrandColors.charcoalLight,
        contentTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: BrandColors.gold,
        linearTrackColor: Colors.white12,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? BrandColors.gold
              : Colors.white54;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? BrandColors.gold.withValues(alpha: 0.4)
              : Colors.white12;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? BrandColors.gold
              : Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(BrandColors.charcoal),
        side: const BorderSide(color: Colors.white54, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: BrandColors.gold,
        unselectedLabelColor: Colors.white54,
        indicatorColor: BrandColors.gold,
        labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 14),
      ),
    )..setGradientColors([
        surface,
        surface.withValues(alpha: 0.85),
      ]);
  }

  static ThemeData _buildLight() {
    final scheme = ColorScheme.light(
      primary: BrandColors.goldDim,
      onPrimary: Colors.white,
      primaryContainer: BrandColors.gold.withValues(alpha: 0.15),
      onPrimaryContainer: BrandColors.goldDim,
      secondary: BrandColors.gold,
      onSecondary: Colors.white,
      surface: BrandColors.cream,
      onSurface: const Color(0xFF1F1F1F),
      surfaceContainerHighest: BrandColors.creamCard,
      error: BrandColors.danger,
      onError: Colors.white,
      outline: BrandColors.creamBorder,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: BrandColors.cream,
      canvasColor: BrandColors.cream,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(
        ThemeData.light().textTheme,
      ).apply(
        bodyColor: const Color(0xFF1F1F1F),
        displayColor: const Color(0xFF1F1F1F),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: BrandColors.cream,
        foregroundColor: const Color(0xFF1F1F1F),
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: true,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: const Color(0xFF1F1F1F),
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: BrandColors.creamCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: BrandColors.creamBorder),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: BrandColors.creamBorder,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: BrandColors.creamCard,
        indicatorColor: BrandColors.gold.withValues(alpha: 0.18),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? BrandColors.goldDim : const Color(0xFF888888),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? BrandColors.goldDim : const Color(0xFF999999),
            size: 24,
          );
        }),
        height: 64,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BrandColors.creamCard,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BrandColors.creamBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BrandColors.creamBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: BrandColors.gold, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: BrandColors.gold,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    )..setGradientColors([
        BrandColors.cream,
        BrandColors.creamCard,
      ]);
  }
}

extension GradientColorsTheme on ThemeData {
  static final Map<Brightness, List<Color>> _gradientColors = {};

  void setGradientColors(List<Color> colors) {
    _gradientColors[brightness] = colors;
  }

  List<Color> get gradientColors {
    return _gradientColors[brightness] ?? [Colors.transparent, Colors.transparent];
  }
}