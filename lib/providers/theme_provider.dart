import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeKey = 'isDarkMode';
  bool _isDarkMode = false;
  SharedPreferences? _prefs;

  bool get isDarkMode => _isDarkMode;

  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Beautiful bluish violet
          brightness: Brightness.light,
        ).copyWith(
          primary: const Color(0xFF6366F1), // Indigo-500
          primaryContainer: const Color(0xFFE0E7FF), // Indigo-100
          secondary: const Color(0xFF8B5CF6), // Violet-500
          secondaryContainer: const Color(0xFFF3E8FF), // Violet-100
          tertiary: const Color(0xFF3B82F6), // Blue-500
          tertiaryContainer: const Color(0xFFDBEAFE), // Blue-100
          surface: const Color(0xFFFAFAFC),
          surfaceContainerHighest: const Color(0xFFF1F5F9),
          outline: const Color(0xFFCBD5E1),
        ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1), // Beautiful bluish violet
          brightness: Brightness.dark,
        ).copyWith(
          primary: const Color(
            0xFF818CF8,
          ), // Indigo-400 (lighter for dark mode)
          primaryContainer: const Color(0xFF3730A3), // Indigo-800
          secondary: const Color(0xFFA78BFA), // Violet-400
          secondaryContainer: const Color(0xFF6B21A8), // Violet-800
          tertiary: const Color(0xFF60A5FA), // Blue-400
          tertiaryContainer: const Color(0xFF1E3A8A), // Blue-800
          surface: const Color(0xFF0F0F23),
          surfaceContainerHighest: const Color(0xFF1E1B3A),
          outline: const Color(0xFF475569),
          onSurface: const Color(0xFFE2E8F0),
        ),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 0,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );

  ThemeData get currentTheme => _isDarkMode ? darkTheme : lightTheme;

  /// Initialize theme from shared preferences
  Future<void> initializeTheme() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _isDarkMode = _prefs?.getBool(_themeKey) ?? false;
      notifyListeners();
    } catch (e) {
      print('❌ Error initializing theme: $e');
    }
  }

  /// Toggle theme mode
  Future<void> toggleTheme() async {
    try {
      _isDarkMode = !_isDarkMode;
      await _prefs?.setBool(_themeKey, _isDarkMode);
      debugPrint('🎨 Theme toggled to: ${_isDarkMode ? "Dark" : "Light"} mode');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error toggling theme: $e');
    }
  }

  /// Set specific theme mode
  Future<void> setThemeMode(bool isDark) async {
    try {
      if (_isDarkMode != isDark) {
        _isDarkMode = isDark;
        await _prefs?.setBool(_themeKey, _isDarkMode);
        notifyListeners();
      }
    } catch (e) {
      print('❌ Error setting theme mode: $e');
    }
  }

  /// Get theme mode description
  String get themeModeDescription => _isDarkMode ? 'Dark Mode' : 'Light Mode';

  /// Get theme icon
  IconData get themeIcon => _isDarkMode ? Icons.dark_mode : Icons.light_mode;
}
