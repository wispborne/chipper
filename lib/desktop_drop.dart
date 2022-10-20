import 'dart:convert';

import 'package:chipper/extensions.dart';
import 'package:chipper/logparser.dart';
import 'package:chipper/readout.dart';
import 'package:collection/collection.dart';
import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:fimber/fimber.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'AppState.dart';
import 'logging.dart';

class DesktopDrop extends StatefulWidget {
  const DesktopDrop({super.key, this.chips});

  final LogChips? chips;

  @override
  State<DesktopDrop> createState() => _DesktopDropState();
}

class _DesktopDropState extends State<DesktopDrop> {
  bool _dragging = false;
  bool _parsing = false;
  Offset? offset;
  String msg = "Drop starsector.log here";

  // final ScrollController _scroller = ScrollController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DropTarget(
        onDragDone: (detail) {
          Fimber.i('onDragDone:');

          setState(() {
            _parsing = true;
          });

          final filePaths = detail.files.map((e) => e.path);
          compute(_handleDroppedFile, filePaths).then((chips) {
            setState(() {
              _parsing = false;
              AppState.loadedLog.chips = chips;
            });
          });
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
            child: (_parsing == true || widget.chips == null)
                ? Container(
                    constraints: const BoxConstraints(minWidth: double.infinity, minHeight: double.infinity),
                    child: Center(
                        widthFactor: 1.5,
                        child: _parsing
                            ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const CircularProgressIndicator(),
                                Container(height: 10),
                                Text(
                                  [
                                    "thinking...",
                                    "processing...",
                                    "parsing...",
                                    "pondering the log",
                                    "chipping...",
                                    "breaking logs down...",
                                    "analyzing...",
                                    "analysing...",
                                    "spinning...",
                                    "please wait...",
                                    "please hold...",
                                  ].random(),
                                  style: theme.textTheme.headlineMedium,
                                )
                              ])
                            : Text(
                                msg,
                                style: theme.textTheme.headlineMedium,
                              )))
                : Readout(widget.chips!)));
  }
}

Future _handleDroppedFile(Iterable<String> droppedFilePaths) async {
  initLogging(); // Needed because isolate has its own memory.

  final files = droppedFilePaths.map((e) => XFile(e));
  for (final file in files) {
    Fimber.i('  Path:${file.path}'
        '\n  Name:${file.name}'
        '\n  Modified:${await file.lastModified()}'
        '\n  Length: ${await file.length()}'
        '\n  Type: ${file.runtimeType}'
        '\n  MIME:${file.mimeType}');
  }

  final droppedFile = files.firstOrNull;
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
    return LogParser().parse(logStream);
  } else {
    Fimber.i("Couldn't read ${droppedFile.name}");
  }
}
