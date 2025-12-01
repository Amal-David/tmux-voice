import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Calm Tech Color Palette
  static const primary = Color(0xFF1D1D1F); // Dark Grey for primary text/actions
  static const backgroundBase = Color(0xFFF8F8FA); // Soft off-white
  static const surface = Color(0xFFFFFFFF); // White
  static const surfaceSecondary = Color(0xFFF6F6F7); // Light Grey
  
  // Text Colors
  static const textPrimary = Color(0xFF1D1D1F);
  static const textSecondary = Color(0xFF5C5C5F);
  static const textTertiary = Color(0xFF8E8E93);
  static const textDisabled = Color(0xFFC0C0C2);

  // Pastel Accents - Soft & Calming
  static const accentPurple = Color(0xFFEBDEF8);
  static const accentBlue = Color(0xFFD6E9FF);
  static const accentTeal = Color(0xFFB8E6D5);  // Softer mint/teal
  static const accentPeach = Color(0xFFFFDCC3);
  static const accentMint = Color(0xFFD4F1E8);  // Lighter mint
  
  // Active Accents (Darker versions for text/icons on pastel backgrounds)
  static const activePurple = Color(0xFFA78BCA);  // Softer purple
  static const activeBlue = Color(0xFF6BA5DB);    // Softer blue
  static const activeTeal = Color(0xFF5FB89A);    // Primary button color - soft teal

  // Semantic Colors
  static const successGreen = Color(0xFFA5E4B5);
  static const warningYellow = Color(0xFFFFEAA7);
  static const errorRed = Color(0xFFFF6A6A);

  // Legacy accessors mapping
  static const primaryPurple = activeTeal;  // Use teal instead of purple
  static const accentGold = warningYellow;
  static const surfaceWhite = surface;
  static const surfaceCard = surface;
  static const surfaceFilled = surfaceSecondary;

  // Gradients
  static const purpleSoftGradient = LinearGradient(
    colors: [Color(0xFFF3E8FF), Color(0xFFEBDEF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const tealGradient = LinearGradient(
    colors: [Color(0xFFE0F7FA), Color(0xFFCCF0E1)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static ThemeData get light {
    final textTheme = GoogleFonts.interTextTheme(const TextTheme(
      displayLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.w600, height: 1.2, letterSpacing: -0.5),
      headlineLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, height: 1.2, letterSpacing: -0.5),
      headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, height: 1.3),
      headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, height: 1.3),
      titleLarge: TextStyle(fontSize: 19, fontWeight: FontWeight.w600, height: 1.2),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, height: 1.3),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.4),
      bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, height: 1.5),
      bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, height: 1.5),
      bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 1.4),
      labelLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5),
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
        secondary: activePurple,
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
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: primary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: primary, size: 24),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      dividerColor: Color(0xFFE5E5E8),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(0, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: activePurple,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: Color(0xFFE5E5E8), width: 1),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceSecondary,
        labelStyle: textTheme.bodySmall?.copyWith(color: textSecondary),
        hintStyle: textTheme.bodyMedium?.copyWith(color: textTertiary),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: activePurple, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorRed, width: 1),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: textSecondary,
        indicatorColor: activePurple,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.bodyMedium,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceSecondary,
        labelStyle: textTheme.bodySmall?.copyWith(color: textSecondary),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: activePurple,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }

  // Shadow Tokens
  static List<BoxShadow> get elevation1 => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.02),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];

  static List<BoxShadow> get elevation2 => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
      
  static List<BoxShadow> get elevation3 => [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 30,
          offset: const Offset(0, 12),
        ),
      ];
}
