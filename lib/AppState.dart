import 'dart:collection';

import 'package:chipper/MyTheme.dart';
import 'package:flutter/foundation.dart';

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

class LogLine {
  final RegExp _logRegex = RegExp("(?<millis>\\d*?) +(?<thread>\\[.*?\\]) +(?<level>\\w+?) +(?<namespace>.*?) +- +(?<error>.*)");
  int lineNumber;

  String? time;
  String? thread;
  String? logLevel;
  String? namespace;
  String? error;

  String fullError;

  LogLine(this.lineNumber, this.fullError) {
    _parse();
  }

  void _parse() {
    final match = _logRegex.firstMatch(fullError);

    if (match != null) {
      time = match.namedGroup("millis");
      thread = match.namedGroup("thread");
      logLevel = match.namedGroup("level");
      namespace = match.namedGroup("namespace");
      error = match.namedGroup("error");
    }
  }
}
