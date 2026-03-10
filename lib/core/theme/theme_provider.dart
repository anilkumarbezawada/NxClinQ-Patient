import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_colors.dart';
import 'app_theme.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _seedColorKey = 'seed_color';

  ThemeMode _themeMode = ThemeMode.light;
  Color _seedColor = AppColors.primaryBrand;

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;

  ThemeData get lightTheme => AppTheme.lightTheme(_seedColor);
  ThemeData get darkTheme => AppTheme.darkTheme(_seedColor);

  bool get isDark => _themeMode == ThemeMode.dark;

  ThemeProvider() {
    _loadFromPrefs();
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_themeModeKey) ?? 0;
    final colorValue = prefs.getInt(_seedColorKey) ?? AppColors.primaryBrand.toARGB32();

    _themeMode = ThemeMode.values[modeIndex];
    _seedColor = Color(colorValue);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, mode.index);
  }

  Future<void> setSeedColor(Color color) async {
    _seedColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_seedColorKey, color.toARGB32());
  }

  void toggleTheme() {
    setThemeMode(_themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

