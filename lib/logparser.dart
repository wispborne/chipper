import 'dart:convert';

import 'package:chipper/ModEntry.dart';
import 'package:collection/collection.dart';

import 'AppState.dart';
import 'ErrorLines.dart';

class LogParser {
  final gameVersionRegex = RegExp(" - Starting Starsector (.*?) launcher");
  final osRegex = RegExp("  - OS: *(.*)");
  final modBlockOpenRegex = "Running with the following mods";
  final modBlockEndPattern = "Mod list finished";
  final javaVersionRegex = RegExp(".*Java version: *(.*)");
  final errorBlockOpenPattern = "ERROR";
  final errorBlockClosePatterns = ["[Thread-", "[main]", " INFO "];
  final threadPattern = RegExp("\\d+ \\[(.*?)\\] .+");

  final modList = List<ModEntry>.empty(growable: true);
  final errorBlock = List<LogLine>.empty(growable: true);

  void parse(String stream) async {
    String? gameVersion;
    String? os;
    String? javaVersion;
    bool isReadingModList = false;
    bool isReadingError = false;

    try {
      final stopwatch = Stopwatch()..start();
      const splitter = LineSplitter();
      var logLines = splitter.convert(stream);

      logLines
          // .transform(splitter)
          .forEachIndexed((index, line) {
        if (gameVersion == null && gameVersionRegex.hasMatch(line)) {
          gameVersion = gameVersionRegex.firstMatch(line)?.group(1);
        }
        if (os == null && osRegex.hasMatch(line)) {
          os = osRegex.firstMatch(line)?.group(1);
        }

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
          // Travel back up and find the previous log entry on the same thread
          // Only look max 10 lines up for perf.
          final thread = threadPattern.firstMatch(line)?.group(1);

          if (thread != null) {
            for (var i = (index - 1); i >= 0 && i > (index - 10); i--) {
              final isLineAlreadyAdded = errorBlock.none((err) => err.lineNumber == i);
              if (isLineAlreadyAdded && threadPattern.firstMatch(logLines[i])?.group(1) == thread) {
                errorBlock.add(UnknownLogLine(i + 1, logLines[i], isPreviousThreadLine: true));
                break;
              }
            }
          }

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
              errorBlock.add(UnknownLogLine(index + 1, line, isPreviousThreadLine: false));
            }
          }
        }
      });

      javaVersion ??= "(no java version in log)";

      var chips =
          LogChips(gameVersion, os, javaVersion, UnmodifiableListView(modList), UnmodifiableListView(errorBlock));
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
