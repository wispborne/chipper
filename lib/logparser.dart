import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:fimber/fimber.dart';

import 'AppState.dart';
import 'ErrorLines.dart';
import 'ModEntry.dart';
import 'logging.dart';

class LogParser {
  final gameVersionContains = " - Starting Starsector ";
  final gameVersionRegex = RegExp(" - Starting Starsector (.*?) launcher");
  final osContains = "  - OS: ";
  final osRegex = RegExp("  - OS: *(.*)");
  final javaVersionContains = "Java version: ";
  final javaVersionRegex = RegExp(".*Java version: *(.*)");
  final modBlockOpenPattern = "Running with the following mods";
  final modBlockEndPattern = "Mod list finished";
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
        Fimber.v("Parsing line $index: $line");

        // Do `.contains` checks as a rough filter before doing a full regex match because contains is much faster.
        // Parsing a long filter without a game version, OS, or java version took 37s without this optimization and 5s with it.
        if (gameVersion == null && line.contains(gameVersionContains) && gameVersionRegex.hasMatch(line)) {
          gameVersion = gameVersionRegex.firstMatch(line)?.group(1);
        }
        if (os == null && line.contains(osContains) && osRegex.hasMatch(line)) {
          os = osRegex.firstMatch(line)?.group(1);
        }
        if (javaVersion == null && line.contains(javaVersionContains) && javaVersionRegex.hasMatch(line)) {
          javaVersion = javaVersionRegex.firstMatch(line)?.group(1);
        }

        if (line.contains(modBlockEndPattern)) {
          isReadingModList = false;
        }

        if (isReadingModList) {
          modList.add(ModEntry.tryCreate(line));
        }

        if (line.contains(modBlockOpenPattern)) {
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
            Fimber.d("Looking for previous log entry for line '$line'.");
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

            Fimber.d("Found it.");
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

      var elapsedMilliseconds = stopwatch.elapsedMilliseconds;
      var chips =
          LogChips(gameVersion, os, javaVersion, UnmodifiableListView(modList), UnmodifiableListView(errorBlock), elapsedMilliseconds);
      Fimber.i("Parsing took $elapsedMilliseconds ms");
      Fimber.v(chips.errorBlock.map((element) => "\n${element.lineNumber}-${element.fullError}").toList().toString());
      return chips;
    } catch (e, stacktrace) {
      Fimber.e("Parsing failed.", ex: e, stacktrace: stacktrace);
      return null;
    }
  }
}
