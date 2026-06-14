import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _settingsBoxName = 'settings';
  static const String _themeKey = 'is_dark_mode';
  Box? _box;

  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _initTheme();
  }

  Future<void> _initTheme() async {
    _box = await Hive.openBox(_settingsBoxName);
    _isDarkMode = _box?.get(_themeKey, defaultValue: false) as bool? ?? false;
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _box?.put(_themeKey, _isDarkMode);
    notifyListeners();
  }
}

