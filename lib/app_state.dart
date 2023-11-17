import 'dart:collection';

import 'package:Chipper/models/user_mods.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'MyTheme.dart';
import 'models/error_lines.dart';
import 'models/mod_entry.dart';

class AppState {
  static LoadedLog loadedLog = LoadedLog();
  static MyTheme theme = MyTheme();
}

final logRawContents = StateProvider<LogFile?>((ref) => null);

class LoadedLog extends ChangeNotifier {
  LogChips? _chips;

  LogChips? get chips => _chips;

  set chips(LogChips? newChips) {
    _chips = newChips;
    notifyListeners();
  }
}

class LogFile {
  final String? filename;
  final String contents;

  LogFile(this.filename, this.contents);
}

class LogChips {
  String? filename;
  final String? gameVersion;
  final String? os;
  final String? javaVersion;
  UserMods modList = UserMods(UnmodifiableListView<ModEntry>([]), isPerfectList: false);
  UnmodifiableListView<LogLine> errorBlock = UnmodifiableListView([]);
  final int timeTaken;

  LogChips(this.filename, this.gameVersion, this.os, this.javaVersion, this.modList, this.errorBlock, this.timeTaken);
}
