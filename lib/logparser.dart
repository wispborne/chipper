import 'dart:collection';
import 'dart:convert';

import 'package:chipper/ModEntry.dart';
import 'package:cross_file/cross_file.dart';

import 'AppState.dart';
import 'ErrorLines.dart';

class LogParser {
  final modBlockOpenRegex = "Running with the following mods";
  final modBlockEndPattern = "Mod list finished";
  final javaVersionRegex = RegExp(".*(Java version:.*)");
  final errorBlockOpenPattern = "ERROR";
  final errorBlockClosePatterns = ["[Thread-", "[main]"];

  final modList = List<ModEntry>.empty(growable: true);
  final errorBlock = List<LogLine>.empty(growable: true);

  void parse(String stream) async {
    String? javaVersion;
    bool isReadingModList = false;
    bool isReadingError = false;

    try {
      var index = 0;
      final stopwatch = Stopwatch()..start();
      final splitter = const LineSplitter();
      splitter.convert(stream)
          // .transform(splitter)
          .forEach((line) {
        if (javaVersion == null && javaVersionRegex.hasMatch(line)) {
          javaVersion = javaVersionRegex.firstMatch(line)?.group(1);
        }

        if (line.contains(modBlockEndPattern)) {
          isReadingModList = false;
        }

        if (isReadingModList) {
          modList.add(ModEntry.tryCreate(line));
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
          final err = (StacktraceLogLine.tryCreate(index + 1, line));
          if (err != null) {
            errorBlock.add(err);
          } else {
            var err = GeneralErrorLogLine.tryCreate(index + 1, line);
            if (err != null) {
              errorBlock.add(err);
            } else {
              errorBlock.add(UnknownLogLine(index + 1, line));
            }
          }
        }

        index++;
      });

      javaVersion ??= "(no java version in log)";

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
