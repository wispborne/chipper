import 'dart:convert';
import 'dart:ui';

import 'package:chipper/ModEntry.dart';
import 'package:chipper/logparser.dart';
import 'package:collection/collection.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'AppState.dart';
import 'ErrorLines.dart';

class DesktopDrop extends StatefulWidget {
  const DesktopDrop({super.key, this.chips});

  final LogChips? chips;

  @override
  State<DesktopDrop> createState() => _DesktopDropState();
}

class _DesktopDropState extends State<DesktopDrop> {
  String? _gameVersion;
  String? _os;
  String? _javaVersion;
  UnmodifiableListView<ModEntry>? _mods;
  List<LogLine>? _errors;
  bool _dragging = false;
  Offset? offset;
  String msg = "Drop starsector.log here";

  // final ScrollController _scroller = ScrollController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void didUpdateWidget(DesktopDrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    final logChips = widget.chips;
    if (logChips != null) {
      _gameVersion = "${logChips.gameVersion}";
      _os = "${logChips.os}";
      _javaVersion = "${logChips.javaVersion}";
      _mods = logChips.modList;
      _errors = logChips.errorBlock.reversed.toList(growable: false);
    }

    // Start at bottom, where errors live.
    // if (_scroller.hasClients) {
    //   _scroller.jumpTo(_scroller.position.maxScrollExtent);
    // }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DropTarget(
        onDragDone: (detail) async {
          Fimber.i('onDragDone:');
          for (final file in detail.files) {
            Fimber.i('  Path:${file.path}'
                '\n  Name:${file.name}'
                '\n  Modified:${await file.lastModified()}'
                '\n  Length: ${await file.length()}'
                '\n  Type: ${file.runtimeType}'
                '\n  MIME:${file.mimeType}');
          }

          final droppedFile = detail.files.firstOrNull;
          if (droppedFile == null) return;

          // No need to filter by name for now, in case file has (Copy) or (1) in it.
          // .firstWhereOrNull((element) => element.name == "starsector.log");
          String? logStream;

          // Check if file is a url or an actual file
          if (droppedFile.name.endsWith(".url")) {
            final url = RegExp(".*(http.*)").firstMatch(await droppedFile.readAsString())?.group(1);
            if (url != null) {
              final uri = Uri.parse(url);
              try {
                Fimber.i("Fetching and streaming online url $uri");
                logStream = (await http.get(uri, headers: {
                  'Content-Type': 'text/plain',
                }))
                    .body; //get()).bodyBytes;//.onError((error, stackTrace) => );
              } catch (e) {
                Fimber.w("Failed to read $url", ex: e);
              }
            }
          } else {
            try {
              logStream = utf8.decode((await droppedFile.readAsBytes()),
                  allowMalformed: true); //.openRead().map((chunk) => utf8.decode(chunk, allowMalformed: true));
            } catch (e) {
              Fimber.w("Couldn't parse text file.", ex: e);
            }
          }

          // final wrongLogRegex = RegExp(".*\.log\./d", caseSensitive: false);
          if (logStream != null) {
            LogParser().parse(logStream);
          } else {
            Fimber.i("Couldn't read ${droppedFile.name}");
          }

          // setState(() {
          //   if (logFile == null && detail.files.any((element) => wrongLogRegex.hasMatch(element.name))) {
          //     msg = "Log file should not end in a number.";
          //   }
          // });
        },
        onDragUpdated: (details) {
          setState(() {
            offset = details.localPosition;
          });
        },
        onDragEntered: (detail) {
          setState(() {
            _dragging = true;
            offset = detail.localPosition;
          });
        },
        onDragExited: (detail) {
          setState(() {
            _dragging = false;
            offset = null;
          });
        },
        child: Container(
            color: _dragging ? Colors.blue.withOpacity(0.4) : Colors.transparent,
            padding: const EdgeInsets.only(left: 20, top: 20, right: 20, bottom: 20),
            child: (widget.chips == null)
                ? Container(
                    constraints: const BoxConstraints(minWidth: double.infinity, minHeight: double.infinity),
                    child: Center(
                        widthFactor: 1.5,
                        child: Text(
                          msg,
                          style: theme.textTheme.headline4,
                        )))
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (_gameVersion != null || _javaVersion != null)
                      Container(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("System", style: theme.textTheme.titleLarge),
                              Text("Starsector: ${_gameVersion!}\nOS: $_os\nJRE: $_javaVersion", style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(240))),
                            ],
                          )),
                    if (_mods != null)
                      Container(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Mods (${_mods?.length})", style: theme.textTheme.titleLarge),
                              ConstrainedBox(
                                  constraints: const BoxConstraints(maxHeight: 150),
                                  // child: Scrollbar(
                                  //     scrollbarOrientation:
                                  //         ScrollbarOrientation.left,
                                  child: ListView.builder(
                                      itemCount: _mods!.length,
                                      shrinkWrap: true,
                                      scrollDirection: Axis.vertical,
                                      itemBuilder: (context, index) => _mods![index].createWidget(context)))
                            ],
                          )),
                    if (_errors != null)
                      // Scrollbar(
                      //     scrollbarOrientation: ScrollbarOrientation.top,
                      //     child: SingleChildScrollView(
                      //         primary: true,
                      //         scrollDirection: Axis.horizontal,
                      //         child:
                      Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text("Errors", style: theme.textTheme.titleLarge),
                        Expanded(
                            // child: Scrollbar(
                            //     scrollbarOrientation:
                            //         ScrollbarOrientation.left,
                            child: ListView.builder(
                                itemCount: _errors!.length,
                                // controller: _scroller,
                                reverse: true,
                                itemBuilder: (BuildContext context, int index) {
                                  return Column(children: [
                                    if (isConsecutiveWithPreviousLine(index))
                                      Divider(
                                        color: theme.disabledColor,
                                      ),
                                    Container(
                                        padding: (isConsecutiveWithPreviousLine(index))
                                            ? const EdgeInsets.only()
                                            : const EdgeInsets.only(top: 1, bottom: 1),
                                        child: IntrinsicHeight(
                                            child: Row(children: [
                                          Column(mainAxisAlignment: MainAxisAlignment.start, children: [
                                            Text(
                                              " ${_errors![index].lineNumber}  ",
                                              style: TextStyle(
                                                  color: theme.hintColor.withAlpha(40),
                                                  fontFeatures: const [FontFeature.tabularFigures()]),
                                            )
                                          ]),
                                          Expanded(child: _errors![index].createLogWidget(context))
                                        ])))
                                  ]);
                                }))
                      ])),
                  ])));
  }

  bool isConsecutiveWithPreviousLine(int index) {
    if (index == _errors!.length - 1) return false;
    return _errors![index].lineNumber - 1 != _errors![index + 1].lineNumber;
  }
}
