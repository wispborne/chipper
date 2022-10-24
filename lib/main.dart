import 'dart:convert';
import 'dart:io';

import 'package:chipper/AppState.dart';
import 'package:chipper/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static const title = "Chipper v1.8.0 by Wisp";
  static const subtitle = "";

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    AppState.theme.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final darkTheme = ThemeData.dark(useMaterial3: true);
    final lightTheme = ThemeData.light(useMaterial3: true);
    return MaterialApp(
      title: MyApp.title,
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      // .copyWith(
      // snackBarTheme: SnackBarThemeData(
      //     backgroundColor: darkTheme.colorScheme.surface,
      //     actionTextColor: darkTheme.hintColor,
      //     contentTextStyle: darkTheme.primaryTextTheme.bodyMedium,
      //     disabledActionTextColor: darkTheme.disabledColor)),
      themeMode: AppState.theme.currentTheme(),
      home: const MyHomePage(title: MyApp.title, subTitle: MyApp.subtitle),
    );
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
      body: SelectionArea(
          focusNode: FocusNode(),
          selectionControls: desktopTextSelectionControls,
          child: Stack(children: [
            Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: <Widget>[
              Expanded(
                  flex: 1,
                  child: DesktopDrop(
                    chips: chips,
                  ))
            ])),
            Align(
                alignment: Alignment.topRight,
                child: Row(mainAxisSize: MainAxisSize.min, children: [
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
                      tooltip: "Switch theme",
                      onPressed: () => AppState.theme.switchThemes(),
                      icon: Icon(AppState.theme.currentTheme() == ThemeMode.dark ? Icons.sunny : Icons.mode_night))
                ])),
          ])),
      floatingActionButton: Padding(
          padding: const EdgeInsets.only(right: 20),
          child: FloatingActionButton(
            onPressed: () async {
              try {
                FilePickerResult? result = await FilePicker.platform.pickFiles();

                if (result?.files.single != null) {
                  var file = result!.files.single;

                  if (kIsWeb) {
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
