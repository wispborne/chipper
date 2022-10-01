import 'package:chipper/config.dart';
import 'package:flutter/material.dart';

class MyTheme with ChangeNotifier {
  static bool _isDark = true;
  static const String _key = "currentTheme";

  MyTheme() {
    if (box.containsKey(_key)) {
      _isDark = box.get(_key);
    }
  }

  ThemeMode currentTheme() {
    return _isDark ? ThemeMode.dark : ThemeMode.light;
  }

  void switchThemes() {
    _isDark = !_isDark;
    box.put(_key, _isDark);
    print("Changed theme. Dark: $_isDark");
    notifyListeners();
  }
}
