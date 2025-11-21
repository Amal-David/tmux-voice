import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const primary = Color(0xFF111111);
  static const accent = Color(0xFF27272F);
  static const backgroundBase = Color(0xFFF7F7F7);
  static const surface = Colors.white;
  static const surfaceMuted = Color(0xFFF0F0F0);
  static const successGreen = Color(0xFF2ECC71);
  static const warningYellow = Color(0xFFF5C042);
  static const errorRed = Color(0xFFD70015);

  // Legacy accessors for existing widgets
  static const primaryPurple = primary;
  static const accentTeal = Color(0xFF007AFF);
  static const accentGold = warningYellow;
  static const surfaceWhite = surface;
  static const surfaceCard = surface;
  static const surfaceFilled = surfaceMuted;
  static const textPrimary = Color(0xFF111111);
  static const textSecondary = Color(0xFF6E6E73);
  static const textTertiary = Color(0xFF8E8E93);
  static const purpleSoftGradient = LinearGradient(
    colors: [Color(0xFF1C1C1E), Color(0xFF2C2C2E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const tealGradient = LinearGradient(
    colors: [Color(0xFFE2E3E5), Color(0xFFC8CACD)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get light {
    final textTheme = GoogleFonts.interTextTheme(const TextTheme(
      displayLarge: TextStyle(fontSize: 48, fontWeight: FontWeight.w600, height: 1.1),
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600, height: 1.2),
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, height: 1.25),
      headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, height: 1.3),
      titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, height: 1.35),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.4),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
      bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.5),
      bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 1.5),
      bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 1.4),
      labelLarge: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
    )).apply(
      bodyColor: textPrimary,
      displayColor: textPrimary,
    );

    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundBase,
      textTheme: textTheme,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: accent,
        surface: surface,
        background: backgroundBase,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimary,
        onBackground: textPrimary,
        error: errorRed,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: ZoomPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: ZoomPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge?.copyWith(letterSpacing: -0.2),
        iconTheme: const IconThemeData(color: primary, size: 22),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      dividerColor: textTertiary.withOpacity(0.2),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary.withOpacity(0.2), width: 1.2),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMuted,
        labelStyle: textTheme.bodySmall?.copyWith(color: textSecondary),
        hintStyle: textTheme.bodyMedium?.copyWith(color: textTertiary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: primary, width: 1.2),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        indicatorColor: primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.bodyMedium,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceMuted,
        labelStyle: textTheme.bodySmall?.copyWith(color: textSecondary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
    );
  }

  static List<BoxShadow> get elevation1 => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ];
}
