import 'package:chipper/AppState.dart';

String createSystemCopyString(LogChips? chips) =>
    "Game: ${chips?.gameVersion}\nOS: ${chips?.os}\nJava: ${chips?.javaVersion}";

String createModsCopyString(LogChips? chips, {bool minify = false}) =>
    "Mods (${chips?.modList.length})\n${chips?.modList.map((e) => minify ? "${e.modId} ${e.modVersion}" : "${e.modName}  v${e.modVersion}  [${e.modId}]").join('\n')}";

String createErrorsCopyString(LogChips? chips) =>
    "Line: Error message\n${chips?.errorBlock.map((e) => "${e.lineNumber}: ${e.fullError}").join('\n')}";
