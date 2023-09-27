import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_color/flutter_color.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:platform_info/platform_info.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_size/window_size.dart';

import 'AboutView.dart';
import 'AppState.dart' as state;
import 'AppState.dart';
import 'config.dart';
import 'copy.dart';
import 'desktop_drop.dart';
import 'logging.dart';
import 'utils.dart';

const chipperTitle = "Chipper";
const chipperVersion = "1.13.1";
const chipperTitleAndVersion = "$chipperTitle v$chipperVersion";
const chipperSubtitle = "A Starsector log viewer";

void main() async {
  initLogging(printPlatformInfo: true);
  Hive.init("chipper.config");
  box = await Hive.openBox("chipperTheme");
  runApp(const ProviderScope(child: MyApp()));
  setWindowTitle(chipperTitleAndVersion);
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

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
    var material3 = AppState.theme.isMaterial3();
    var darkTheme = ThemeData(brightness: Brightness.dark, useMaterial3: material3);

    const starsectorPrimaryColor = Color.fromRGBO(73, 252, 255, 1);
    final starsectorLauncher = darkTheme.copyWith(
        colorScheme: darkTheme.colorScheme.copyWith(
          primary: starsectorPrimaryColor,
          secondary: const Color.fromRGBO(59, 203, 232, 1),
          tertiary: const Color.fromRGBO(0, 255, 255, 1),
        ),
        scaffoldBackgroundColor: const Color.fromRGBO(14, 22, 43, 1),
        dialogBackgroundColor: const Color.fromRGBO(14, 22, 43, 1),
        cardColor: const Color.fromRGBO(37, 44, 65, 1),
        appBarTheme: darkTheme.appBarTheme.copyWith(backgroundColor: const Color.fromRGBO(32, 41, 65, 1.0)),
        floatingActionButtonTheme: darkTheme.floatingActionButtonTheme
            .copyWith(backgroundColor: starsectorPrimaryColor, foregroundColor: darkTheme.colorScheme.surface));

    final halloween = darkTheme.copyWith(
        colorScheme: darkTheme.colorScheme.copyWith(
            primary: HexColor("#FF0000"),
            secondary: HexColor("#FF4D00").lighter(10),
            tertiary: HexColor("#FF4D00").lighter(20)),
        scaffoldBackgroundColor: HexColor("#272121"),
        dialogBackgroundColor: HexColor("#272121"));

    // Light theme
    var defaultLightTheme = ThemeData.light(useMaterial3: material3);
    final lightTheme = defaultLightTheme.copyWith(
      colorScheme: defaultLightTheme.colorScheme.copyWith(
          primary: starsectorPrimaryColor,
          secondary: const Color.fromRGBO(59, 203, 232, 1),
          tertiary: const Color.fromRGBO(0, 255, 255, 1)),
    );

    return CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.keyV, control: true): () => pasteLog(ref)},
        child: MaterialApp(
          title: chipperTitleAndVersion,
          debugShowCheckedModeBanner: false,
          theme: lightTheme.copyWith(
              textTheme:
                  lightTheme.textTheme.copyWith(bodyMedium: lightTheme.textTheme.bodyMedium?.copyWith(fontSize: 16)),
              snackBarTheme: const SnackBarThemeData()),
          darkTheme: starsectorLauncher.copyWith(
              textTheme:
                  darkTheme.textTheme.copyWith(bodyMedium: darkTheme.textTheme.bodyMedium?.copyWith(fontSize: 16))),
          themeMode: AppState.theme.currentTheme(),
          home: const MyHomePage(title: chipperTitleAndVersion, subTitle: chipperSubtitle),
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
    final theme = Theme.of(context);
    return Scaffold(
      body: Column(children: [
        AppBar(
            toolbarHeight: 70,
            title: Padding(
                padding: const EdgeInsets.only(left: 10, top: 5, right: 5),
                child: Row(children: [
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.title),
                      Text(
                        widget.subTitle ?? "",
                        style: theme.textTheme.labelLarge,
                      ),
                    ]),
                    const SizedBox(width: 30),
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
                    if (false)
                      IconButton(
                          onPressed: () => pasteLog(ref), tooltip: "Paste log (Ctrl-V)", icon: const Icon(Icons.paste)),
                  ]),
                  const Spacer(),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    // Padding(
                    //     padding: const EdgeInsets.only(top: 7),
                    //     child: IconButton(
                    //         onPressed: () => showMyDialog(context,
                    //             title: const Text("Happy Halloween"), body: [Image.asset("assets/images/spooky.png")]),
                    //         padding: EdgeInsets.zero,
                    //         icon: const ImageIcon(
                    //           AssetImage("assets/images/halloween.png"),
                    //           size: 48,
                    //         ))),
                    IconButton(
                        tooltip: "Switch theme",
                        onPressed: () => AppState.theme.switchThemes(),
                        icon: Icon(AppState.theme.currentTheme() == ThemeMode.dark ? Icons.sunny : Icons.mode_night)),
                    IconButton(
                        tooltip: "Switch density",
                        onPressed: () => AppState.theme.switchMaterial(),
                        icon: Icon(AppState.theme.isMaterial3() ? Icons.view_compact : Icons.view_cozy)),
                    IconButton(
                        tooltip: "About Chipper",
                        onPressed: () => showChipperAboutDialog(context, theme),
                        icon: const Icon(Icons.info))
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
