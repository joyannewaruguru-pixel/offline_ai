import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages light/dark theme state across the entire app.
/// Access via [ThemeService.instance] or use with Provider.
class ThemeService extends ChangeNotifier {
  ThemeService._();
  static final ThemeService instance = ThemeService._();

  bool _isDark = false;
  bool get isDark => _isDark;
  ThemeMode get themeMode => _isDark ? ThemeMode.dark : ThemeMode.light;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool('dark_mode') ?? false;
    notifyListeners();
  }

  Future<void> toggle() async {
    _isDark = !_isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', _isDark);
    notifyListeners();
  }

  // ── Brand colours ─────────────────────────────────────────────────────────
  static const primaryGreen  = Color(0xFF1D9E75);
  static const primaryLight  = Color(0xFFE1F5EE);
  static const primaryDark   = Color(0xFF0F6E56);

  // ── Light theme ───────────────────────────────────────────────────────────
  static ThemeData light() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen, brightness: Brightness.light),
    scaffoldBackgroundColor: const Color(0xFFF6F8F7),
    cardColor: Colors.white,
    appBarTheme: const AppBarTheme(
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
            color: Colors.white, fontSize: 16,
            fontWeight: FontWeight.w500)),
    navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: primaryLight,
        labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w500))),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            foregroundColor: primaryGreen,
            side: const BorderSide(color: primaryGreen),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)))),
    inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryGreen, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE24B4A)))),
    switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected)
                ? primaryGreen : Colors.grey),
        trackColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected)
                ? primaryLight : Colors.grey.shade300)),
  );

  // ── Dark theme ────────────────────────────────────────────────────────────
  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
        seedColor: primaryGreen, brightness: Brightness.dark),
    scaffoldBackgroundColor: const Color(0xFF0F1117),
    cardColor: const Color(0xFF1C1F26),
    appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF161920),
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: TextStyle(
            color: Colors.white, fontSize: 16,
            fontWeight: FontWeight.w500)),
    navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF161920),
        indicatorColor: primaryGreen.withOpacity(0.25),
        labelTextStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 11, fontWeight: FontWeight.w500))),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            elevation: 0,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)))),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
            foregroundColor: primaryGreen,
            side: const BorderSide(color: primaryGreen),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)))),
    inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1C1F26),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2C2F3A))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2C2F3A))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: primaryGreen, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE24B4A)))),
    switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected)
                ? primaryGreen : Colors.grey),
        trackColor: WidgetStateProperty.resolveWith(
                (s) => s.contains(WidgetState.selected)
                ? primaryGreen.withOpacity(0.3) : Colors.grey.shade800)),
    dividerColor: const Color(0xFF2C2F3A),
  );
}