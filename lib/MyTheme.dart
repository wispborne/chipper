import 'package:flutter/material.dart';
import 'package:flutter_color/flutter_color.dart';

import 'config.dart';

class MyTheme with ChangeNotifier {
  static bool _isDark = true;
  static bool _isMaterial3 = false;
  static const String _key = "currentTheme";
  static const String _keyMaterial = "isMaterial";

  MyTheme() {
    if (box.containsKey(_key)) {
      _isDark = box.get(_key) ?? true;
      _isMaterial3 = box.get(_keyMaterial) ?? false;
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

class Swatch {
  final Color primary;
  final Color secondary;
  final Color tertiary;
  final Color background;
  final Color card;

  Swatch(this.primary, this.secondary, this.tertiary, this.background, this.card);
}

class StarsectorSwatch extends Swatch {
  StarsectorSwatch()
      : super(
          const Color.fromRGBO(73, 252, 255, 1),
          const Color.fromRGBO(59, 203, 232, 1),
          const Color.fromRGBO(0, 255, 255, 1),
          const Color.fromRGBO(14, 22, 43, 1),
          const Color.fromRGBO(32, 41, 65, 1.0),
        );
}

class HalloweenSwatch extends Swatch {
  HalloweenSwatch()
      : super(
          HexColor("#FF0000"),
          HexColor("#FF4D00").lighter(10),
          HexColor("#FF4D00").lighter(20),
          HexColor("#272121"),
          HexColor("#272121").lighter(3),
        );
}

class XmasSwatch extends Swatch {
  XmasSwatch()
      : super(
          HexColor("#f23942").darker(10),
          HexColor("#70BA7F").lighter(10),
          HexColor("#b47c4b").lighter(30),
          const Color.fromRGBO(26, 46, 31, 1.0).darker(5),
          HexColor("#171e13").lighter(8),
        );
}
