import 'dart:collection';
import 'dart:convert';

import 'package:cross_file/cross_file.dart';

import 'AppState.dart';

class LogParser {
  final modBlockOpenRegex = "Running with the following mods";
  final modBlockEndPattern = "Mod list finished";
  final javaVersionRegex = RegExp(".*(Java version:.*)");
  final modListItemRegex = RegExp(".*-     (.*) \\(from .*");
  final errorBlockOpenPattern = "ERROR";
  final errorBlockClosePatterns =[ "[Thread-", "[main]"];

  final modList = List<String>.empty(growable: true);
  final errorBlock = List<LogLine>.empty(growable: true);

  void parse(XFile file) async {
    String? javaVersion;
    bool isReadingModList = false;
    bool isReadingError = false;

    try {
      var index = 0;
      final stopwatch = Stopwatch()..start();
      await file
          .openRead()
          .map((event) => utf8.decode(event, allowMalformed: true))
          .transform(const LineSplitter())
          .forEach((line) {
        if (javaVersion == null && javaVersionRegex.hasMatch(line)) {
          javaVersion = javaVersionRegex.firstMatch(line)?.group(1) ?? "(no java version in log)";
        }

        if (line.contains(modBlockEndPattern)) {
          isReadingModList = false;
        }

        if (isReadingModList) {
          modList.add(modListItemRegex.firstMatch(line)?.group(1) ?? line);
        }
        if (line.contains(modBlockOpenRegex)) {
          isReadingModList = true;
          modList.clear(); // If we found the start of a modlist block, wipe any previous, older one.
        }

        if (errorBlockClosePatterns.any((element) => line.contains(element))) {
          isReadingError = false;
        }

        if (line.contains(errorBlockOpenPattern)) {
          isReadingError = true;
        }

        if (isReadingError) {
          errorBlock.add(LogLine(index + 1, line));
        }

        index++;
      });

      var chips = LogChips(javaVersion, UnmodifiableListView(modList), UnmodifiableListView(errorBlock));
      AppState.loadedLog.chips = chips;
      print("Parsing took ${stopwatch.elapsedMilliseconds} ms");
      // return chips;
    } catch (e, stacktrace) {
      print(e);
      print(stacktrace);
      return null;
    }
  }
}
