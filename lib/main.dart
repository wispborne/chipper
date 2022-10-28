import 'dart:convert';
import 'dart:io';

import 'package:chipper/AppState.dart';
import 'package:chipper/desktop_drop.dart';
import 'package:chipper/utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:platform_info/platform_info.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_size/window_size.dart';

import 'AppState.dart' as state;
import 'config.dart';
import 'copy.dart';
import 'logging.dart';

const chipperTitle = "Chipper v1.11.0";
const chipperSubtitle = " by Wisp";

void main() async {
  initLogging(printPlatformInfo: true);
  Hive.init("chipper.config");
  box = await Hive.openBox("chipperTheme");
  runApp(const ProviderScope(child: MyApp()));
  setWindowTitle(chipperTitle + chipperSubtitle);
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
    var darkTheme = ThemeData(brightness: Brightness.dark);
    final lightTheme = ThemeData.light(useMaterial3: false);
    return CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.keyV, control: true): () => pasteLog(ref)},
        child: MaterialApp(
          title: chipperTitle + chipperSubtitle,
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme.copyWith(
              colorScheme: darkTheme.colorScheme.copyWith(
                  primary: const Color.fromRGBO(73, 252, 255, 1),
                  secondary: const Color.fromRGBO(59, 203, 232, 1),
                  tertiary: const Color.fromRGBO(0, 255, 255, 1)),
              scaffoldBackgroundColor: const Color.fromRGBO(14, 22, 43, 1),
              dialogBackgroundColor: const Color.fromRGBO(14, 22, 43, 1)),
          themeMode: AppState.theme.currentTheme(),
          home: const MyHomePage(title: chipperTitle, subTitle: chipperSubtitle),
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
                        onPressed: () => pasteLog(ref), tooltip: "Paste tog (Ctrl-V)", icon: const Icon(Icons.paste)),
                  ]),
                  const Spacer(),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                        tooltip: "Switch theme",
                        onPressed: () => AppState.theme.switchThemes(),
                        icon: Icon(AppState.theme.currentTheme() == ThemeMode.dark ? Icons.sunny : Icons.mode_night)),
                    IconButton(
                        tooltip: "About Chipper",
                        onPressed: () => showMyDialog(context,
                                title: Center(
                                    child: Column(children: [
                                  Text(
                                    chipperTitle,
                                    style: theme.textTheme.titleLarge?.copyWith(fontSize: 24),
                                  ),
                                  Text("A Starsector log viewer", style: theme.textTheme.labelLarge),
                                  Text("by Wisp", style: theme.textTheme.labelLarge),
                                  const Divider(),
                                ])),
                                body: [
                                  ConstrainedBox(
                                      constraints: const BoxConstraints(maxWidth: 600),
                                      child: Column(
                                        children: [
                                          Text(
                                            "What's it do?",
                                            style: theme.textTheme.titleLarge,
                                          ),
                                          SizedBox.fromSize(
                                            size: const Size.fromHeight(5),
                                          ),
                                          const Text(
                                              "The first part of troubleshooting Starsector issues is looking through a log file for errors, and often checking for outdated mods.\nChipper pulls useful information out of the log for easier viewing."),
                                          SizedBox.fromSize(
                                            size: const Size.fromHeight(20),
                                          ),
                                          Text(
                                            "What do you do with my logs?",
                                            style: theme.textTheme.titleLarge,
                                          ),
                                          SizedBox.fromSize(
                                            size: const Size.fromHeight(5),
                                          ),
                                          const Text(
                                              "Everything is done on your browser. Neither the file nor any part of it are ever sent over the Internet.\nI do not collect any analytics except for what Cloudflare, the hosting provider, collects by default, which is all anonymous."),
                                          SizedBox.fromSize(
                                            size: const Size.fromHeight(30),
                                          ),
                                          Text.rich(TextSpan(children: [
                                            const TextSpan(text: "Created using Flutter, by Google "),
                                            TextSpan(
                                                text: "so it'll probably get discontinued next year.",
                                                style: theme.textTheme.bodySmall)
                                          ])),
                                          Linkify(
                                            text: "Source Code: https://github.com/wispborne/chipper",
                                            linkifiers: const [UrlLinkifier()],
                                            onOpen: (link) => launchUrl(Uri.parse(link.url)),
                                          ),
                                        ],
                                      ))
                                ]),
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
