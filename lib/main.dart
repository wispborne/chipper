import 'dart:convert';

import 'package:Chipper/MyTheme.dart';
import 'package:Chipper/views/wavy_painter.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:platform_info/platform_info.dart';
import 'package:window_size/window_size.dart';

import 'app_state.dart' as state;
import 'app_state.dart';
import 'config.dart';
import 'copy.dart';
import 'logging.dart';
import 'views/about_view.dart';
import 'views/desktop_drop_view.dart';

const chipperTitle = "Chipper";
const chipperVersion = "1.14.2";
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

    var swatch = switch (DateTime.now().month) {
      DateTime.october => HalloweenSwatch(),
      DateTime.december => XmasSwatch(),
      _ => StarsectorSwatch()
    };

    final theme = darkTheme.copyWith(
        colorScheme: darkTheme.colorScheme.copyWith(
          primary: swatch.primary,
          secondary: swatch.secondary,
          tertiary: swatch.tertiary,
        ),
        scaffoldBackgroundColor: swatch.background,
        dialogBackgroundColor: swatch.background,
        cardColor: swatch.card,
        appBarTheme: darkTheme.appBarTheme.copyWith(backgroundColor: swatch.card),
        floatingActionButtonTheme: darkTheme.floatingActionButtonTheme
            .copyWith(backgroundColor: swatch.primary, foregroundColor: darkTheme.colorScheme.surface));

    // Light theme
    var starsectorSwatch = StarsectorSwatch();
    var defaultLightTheme = ThemeData.light(useMaterial3: material3);
    final lightTheme = defaultLightTheme.copyWith(
      colorScheme: defaultLightTheme.colorScheme.copyWith(
          primary: starsectorSwatch.primary,
          secondary: starsectorSwatch.secondary,
          tertiary: starsectorSwatch.tertiary),
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
          darkTheme: theme.copyWith(
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
    ref.read(state.logRawContents.notifier).update((state) {
      if (clipboardData == null) {
        return null;
      } else {
        LogFile(null, clipboardData);
      }
    });
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
        WavyLineWidget(color: theme.colorScheme.primary, ),
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
                    ref.read(state.logRawContents.notifier).update((state) => LogFile(file.name, content));
                  } else {
                    final content = utf8.decode(file.bytes!.toList(), allowMalformed: true);
                    ref.read(state.logRawContents.notifier).update((state) => LogFile(file.name, content));
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
