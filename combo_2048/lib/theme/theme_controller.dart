import 'package:flutter/material.dart';
import 'app_theme.dart';

class ThemeController extends ChangeNotifier {
  AppTheme _current = AppTheme.original;
  AppTheme get current => _current;

  ThemeData get themeData => buildTheme(_current);

  static const _order = [AppTheme.original, AppTheme.dark, AppTheme.minecraft];

  void setTheme(AppTheme theme) {
    if (_current == theme) return;
    _current = theme;
    notifyListeners();
  }

  void next() {
    final i = _order.indexOf(_current);
    _current = _order[(i + 1) % _order.length];
    notifyListeners();
  }

  // Mantém compatibilidade com o botão atual
  void toggle() => next();
}
