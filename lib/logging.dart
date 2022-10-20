import 'package:fimber/fimber.dart';
import 'package:platform_info/platform_info.dart';

void initLogging({bool printPlatformInfo = false}) {
  Fimber.clearAll();
  Fimber.plantTree(DebugTree.elapsed(logLevels: ["D", "I", "W", "E"], useColors: true));

  if (printPlatformInfo) {
    Fimber.i("Logging started.");
    Fimber.i("Platform: ${Platform.I.operatingSystem.name} ${Platform.I.version}.");
  }
}
