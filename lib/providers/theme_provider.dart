import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode {
    return _themeMode == ThemeMode.dark;
  }
  
  bool get isSystemMode {
    return _themeMode == ThemeMode.system;
  }

  // Initialize theme from shared preferences
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? ThemeMode.system.index;
    _themeMode = ThemeMode.values[themeIndex];
    notifyListeners();
  }

  // Set theme mode
  Future<void> setThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, themeMode.index);
  }

  // Toggle between light and dark theme
  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  // Shared design tokens
  static const _seedColor = Color(0xFF5B8DEF);
  static const _surfaceRadius = 14.0;
  static const _cardElevation = 1.5;

  static ThemeData _baseTheme(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: brightness,
    );

    final textTheme = Typography.material2021().black.apply(
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        );

    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      textTheme: isDark ? Typography.material2021().white : textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: true,
        elevation: 0,
        titleTextStyle: (isDark ? Typography.material2021().white : textTheme)
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700) ??
            TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
      ),
      cardTheme: CardThemeData(
        elevation: _cardElevation,
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_surfaceRadius),
          side: isDark
              ? BorderSide(color: Colors.white.withOpacity(0.12), width: 0.5)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        color: isDark ? const Color(0xE60F172A) : colorScheme.surface,
        shadowColor: colorScheme.shadow.withOpacity(0.08),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        iconColor: colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor:
            isDark ? colorScheme.surfaceVariant.withOpacity(0.35) : colorScheme.surfaceVariant.withOpacity(0.6),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_surfaceRadius),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_surfaceRadius),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_surfaceRadius),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_surfaceRadius),
          borderSide: BorderSide(color: colorScheme.error, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.primary,
          side: BorderSide(color: colorScheme.primary),
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceVariant,
        selectedColor: colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurface),
        secondaryLabelStyle: TextStyle(color: colorScheme.onPrimaryContainer),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.6),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      dividerColor: colorScheme.outlineVariant,
      scaffoldBackgroundColor: colorScheme.background,
    );
  }

  // Light theme data
  static ThemeData get lightTheme => _baseTheme(Brightness.light);

  // Dark theme data
  static ThemeData get darkTheme => _baseTheme(Brightness.dark);
}
