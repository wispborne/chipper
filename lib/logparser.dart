import 'dart:convert';

import 'package:chipper/ModEntry.dart';
import 'package:collection/collection.dart';
import 'package:fimber/fimber.dart';

import 'AppState.dart';
import 'ErrorLines.dart';
import 'logging.dart';

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

  Future<LogChips?> parse(String stream) async {
    initLogging(); // Needed because isolate has its own memory.
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
          final thread = threadPattern.firstMatch(line)?.group(1);

          if (thread != null) {
            // Only look max 10 lines up for perf (edit: removed).  `&& i > (index - 10)`
            // Edit: It didn't affect perf much, but it did cause some INFO lines to be missed.
            for (var i = (index - 1); i >= 0; i--) {
              final isLineAlreadyAdded = errorBlock.any((err) => err.lineNumber == (i + 1));
              if (isLineAlreadyAdded) {
                break; // If the line's already added, it's an error line, so don't keep looking for an info.
              }

              if (threadPattern.firstMatch(logLines[i])?.group(1) == thread) {
                // Create a new logline (which is the prev message on the thread).
                // Try to parse it as a regular error line, and if that fails, make it an "unknown" one.
                errorBlock.add((GeneralErrorLogLine.tryCreate(i + 1, logLines[i])?..isPreviousThreadLine = true) ??
                    UnknownLogLine(i + 1, logLines[i], isPreviousThreadLine: true));
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

      // javaVersion ??= "(no java version in log)";

      var chips =
          LogChips(gameVersion, os, javaVersion, UnmodifiableListView(modList), UnmodifiableListView(errorBlock));
      Fimber.i("Parsing took ${stopwatch.elapsedMilliseconds} ms");
      Fimber.i(chips.errorBlock.map((element) => "\n${element.lineNumber}-${element.fullError}").toList().toString());
      return chips;
    } catch (e, stacktrace) {
      Fimber.e("Parsing failed.", ex: e, stacktrace: stacktrace);
      return null;
    }
  }
}
