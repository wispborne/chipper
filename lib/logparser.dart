import 'dart:convert';

import 'package:cross_file/cross_file.dart';

class LogParser {
  final modBlockOpenRegex = RegExp("Running with the following mods");
  final modBlockEndRegex = RegExp("Mod list finished");
  final javaVersionRegex = RegExp(".*(Java version:.*)");
  final modListItemRegex = RegExp(".*-     (.*) \\(from .*");
  final errorBlockOpenRegex = RegExp(".*ERROR.*");
  final errorBlockCloseRegex = RegExp(".*Thread-.*");

  final modList = List<String>.empty(growable: true);
  final errorBlock = List<String>.empty(growable: true);

  Future<LogChips?> parse(XFile file) async {
    List<String> text;
    bool isReadingModList = false;
    bool isReadingError = false;
    var chips = LogChips();

    try {
      await file
          .openRead()
          .map((event) => utf8.decode(event, allowMalformed: true))
          .transform(const LineSplitter())
          .forEach((line) {
        if (javaVersionRegex.hasMatch(line)) {
          chips.javaVersion = javaVersionRegex.firstMatch(line)?.group(1);
        }

        if (modBlockEndRegex.hasMatch(line)) {
          isReadingModList = false;
        }

        if (isReadingModList) {
          modList.add(modListItemRegex.firstMatch(line)?.group(1) ?? line);
        }

        if (modBlockOpenRegex.hasMatch(line)) {
          isReadingModList = true;
          modList
              .clear(); // If we found the start of a modlist block, wipe any previous, older one.
        }

        if (errorBlockCloseRegex.hasMatch(line)) {
          isReadingError = false;
        }

        if (errorBlockOpenRegex.hasMatch(line)) {
          isReadingError = true;
        }

        if (isReadingError) {
          errorBlock.add(line);
        }
      });

      chips.modList = modList;
      chips.errorBlock = errorBlock;
      print(chips);
      return chips;
    } catch (e, stacktrace) {
      print(e);
      print(stacktrace);
      return null;
    }
  }
}

class LogChips {
  List<String>? modList;
  String? javaVersion;
  List<String>? errorBlock;
}
