import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ErrorLines.dart';
import 'ModEntry.dart';
import 'MyTheme.dart';

class AppState {
  static LoadedLog loadedLog = LoadedLog();
  static MyTheme theme = MyTheme();
}

final logRawContents = StateProvider<String?>((ref) => null);

class LoadedLog extends ChangeNotifier {
  LogChips? _chips;

  LogChips? get chips => _chips;

  set chips(LogChips? newChips) {
    _chips = newChips;
    notifyListeners();
  }
}

class LogChips {
  final String? gameVersion;
  final String? os;
  final String? javaVersion;
  UnmodifiableListView<ModEntry> modList = UnmodifiableListView([]);
  UnmodifiableListView<LogLine> errorBlock = UnmodifiableListView([]);
  final int timeTaken;

  LogChips(this.gameVersion, this.os, this.javaVersion, this.modList, this.errorBlock, this.timeTaken);
}
