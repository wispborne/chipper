import 'package:chipper/config.dart';
import 'package:flutter/material.dart';

class MyTheme with ChangeNotifier {
  static bool _isDark = true;
  static bool _isMaterial3 = false;
  static const String _key = "currentTheme";
  static const String _keyMaterial = "isMaterial";

  MyTheme() {
    if (box.containsKey(_key)) {
      _isDark = box.get(_key);
      _isMaterial3 = box.get(_keyMaterial);
    }
  }

  ThemeMode currentTheme() {
    return _isDark ? ThemeMode.dark : ThemeMode.light;
  }

  bool isMaterial3() {
    return _isMaterial3;
  }

  void switchThemes() {
    _isDark = !_isDark;
    box.put(_key, _isDark);
    print("Changed theme. Dark: $_isDark");
    notifyListeners();
  }

  void switchMaterial() {
    _isMaterial3 = !_isMaterial3;
    box.put(_keyMaterial, _isMaterial3);
    print("Changed material. Material: $_isMaterial3");
    notifyListeners();
  }
}
