import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0066FF)),
      fontFamily: 'SF Pro',
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF0A0B0F),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardColor: const Color(0xFF151821),
      dividerColor: Colors.white10,
      textTheme: base.textTheme.apply(bodyColor: Colors.white, displayColor: Colors.white),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white10,
        labelStyle: const TextStyle(color: Colors.white),
      ),
    );
  }
}
