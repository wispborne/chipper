import 'dart:convert';
import 'dart:io';

import 'package:chipper/AppState.dart';
import 'package:chipper/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:platform_info/platform_info.dart';
import 'package:window_size/window_size.dart';

import 'AppState.dart' as state;
import 'config.dart';
import 'copy.dart';
import 'logging.dart';

void main() async {
  initLogging(printPlatformInfo: true);
  Hive.init("chipper.config");
  box = await Hive.openBox("chipperTheme");
  runApp(const ProviderScope(child: MyApp()));
  setWindowTitle(MyApp.title + MyApp.subtitle);
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  static const title = "Chipper v1.10.0 by Wisp";
  static const subtitle = "";

  @override
  ConsumerState createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    AppState.theme.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final darkTheme = ThemeData.dark(useMaterial3: false);
    final lightTheme = ThemeData.light(useMaterial3: false);
    return CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.keyV, control: true): () => pasteLog(ref)},
        child: MaterialApp(
          title: MyApp.title,
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: AppState.theme.currentTheme(),
          home: const MyHomePage(title: MyApp.title, subTitle: MyApp.subtitle),
        ));
  }
}

Future<void> pasteLog(WidgetRef ref) async {
  var clipboardData = (await Clipboard.getData(Clipboard.kTextPlain))?.text;

  if (clipboardData?.isNotEmpty == true) {
    ref.read(state.logRawContents.notifier).update((state) => clipboardData);
  }
}

class MyHomePage extends ConsumerStatefulWidget {
  const MyHomePage({super.key, required this.title, this.subTitle});

  final String title;
  final String? subTitle;

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  LogChips? chips;

  @override
  void initState() {
    super.initState();
    AppState.loadedLog.addListener(() {
      setState(() {
        chips = AppState.loadedLog.chips;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        SizedBox(
            height: 30,
            child: Padding(
                padding: const EdgeInsets.only(left: 5, top: 5, right: 5),
                child: Row(children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    if (chips != null)
                      IconButton(
                          onPressed: () {
                            if (chips != null) {
                              Clipboard.setData(ClipboardData(
                                  text:
                                      "${createSystemCopyString(chips)}\n\n${createModsCopyString(chips)}\n\n${createErrorsCopyString(chips)}"));
                            }
                          },
                          tooltip: "Copy all",
                          icon: const Icon(Icons.copy_all)),
                    IconButton(
                        onPressed: () => pasteLog(ref), tooltip: "Paste tog (ctrl-V)", icon: const Icon(Icons.paste)),
                  ]),
                  const Spacer(),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                        tooltip: "Switch theme",
                        onPressed: () => AppState.theme.switchThemes(),
                        icon: Icon(AppState.theme.currentTheme() == ThemeMode.dark ? Icons.sunny : Icons.mode_night))
                  ])
                ]))),
        Expanded(
            child: SizedBox(
                width: double.infinity,
                child: DesktopDrop(
                  chips: chips,
                )))
      ]),
      floatingActionButton: Padding(
          padding: const EdgeInsets.only(right: 20),
          child: FloatingActionButton(
            onPressed: () async {
              try {
                FilePickerResult? result = await FilePicker.platform.pickFiles();

                if (result?.files.single != null) {
                  var file = result!.files.single;

                  if (Platform.I.isWeb) {
                    final content = utf8.decode(file.bytes!.toList(), allowMalformed: true);
                    ref.read(state.logRawContents.notifier).update((state) => content);
                  } else {
                    ref
                        .read(state.logRawContents.notifier)
                        .update((state) => utf8.decode(File(file.path!).readAsBytesSync(), allowMalformed: true));
                  }
                } else {
                  Fimber.w("Error reading file! $result");
                }
              } catch (e, stackTrace) {
                Fimber.e("Error reading log file.", ex: e, stacktrace: stackTrace);
              }
            },
            tooltip: 'Upload log file',
            child: const Icon(Icons.upload_file),
          )), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
