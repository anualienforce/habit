import 'package:flutter/material.dart';

class AppGradients {
  static List<Color> background(Brightness brightness) => brightness == Brightness.dark
      ? const [Color(0xFF0A1224), Color(0xFF0C1930), Color(0xFF0E233C)]
      : const [Color(0xFFEFF2FF), Color(0xFFE3E8FF), Color(0xFFF9E1F2)];

  static List<Color> button(Brightness brightness) => brightness == Brightness.dark
      ? const [Color(0xFF50C7E8), Color(0xFF5F6BFF)]
      : const [Color(0xFF7C5CFF), Color(0xFFE856C7)];

  static List<Color> surfaceGlass(Brightness brightness) => brightness == Brightness.dark
      ? const [Color(0x1FFFFFFF), Color(0x14FFFFFF)]
      : const [Color(0x18FFFFFF), Color(0x12FFFFFF)];

  static List<Color> bottomNav(Brightness brightness) => brightness == Brightness.dark
      ? const [Color(0xFF0A1322), Color(0xFF0C1B2F)]
      : const [Color(0xFFFDFDFF), Color(0xFFF0F3FF)];
}

class AppShadows {
  static List<BoxShadow> softGlow(Color base, {double opacity = 0.35}) => [
        BoxShadow(
          color: base.withOpacity(opacity),
          blurRadius: 16,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> fab(Color base) => [
        BoxShadow(
          color: base.withOpacity(0.35),
          blurRadius: 14,
          offset: const Offset(0, 8),
        ),
      ];
}
