import 'dart:collection';

import 'package:chipper/MyTheme.dart';
import 'package:chipper/extensions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'ErrorLines.dart';

class AppState {
  static LoadedLog loadedLog = LoadedLog();
  static MyTheme theme = MyTheme();
}

class LoadedLog extends ChangeNotifier {
  LogChips? _chips;

  LogChips? get chips => _chips;

  set chips(LogChips? newChips) {
    _chips = newChips;
    notifyListeners();
  }
}

class LogChips {
  final String? javaVersion;
  UnmodifiableListView<String> modList = UnmodifiableListView([]);
  UnmodifiableListView<LogLine> errorBlock = UnmodifiableListView([]);

  LogChips(this.javaVersion, this.modList, this.errorBlock);
}

// class LogChips extends ChangeNotifier {
//   final List<String> _modList = [];
//   String? _javaVersion;
//   final List<LogLine> _errorBlock = [];
//
//   UnmodifiableListView<String> get modList => UnmodifiableListView(_modList);
//
//   String? get javaVersion => _javaVersion;
//
//   UnmodifiableListView<LogLine> get errorBlock =>
//       UnmodifiableListView(_errorBlock);
//
//   set modList(List<String> mods) {
//     _modList.clear();
//     _modList.addAll(mods);
//     notifyListeners();
//   }
//
//   set errorBlock(List<LogLine> errors) {
//     _errorBlock.clear();
//     _errorBlock.addAll(errors);
//     notifyListeners();
//   }
// }

