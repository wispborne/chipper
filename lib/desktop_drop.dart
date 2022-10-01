import 'package:chipper/logparser.dart';
import 'package:collection/collection.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

import 'AppState.dart';

class DesktopDrop extends StatefulWidget {
  const DesktopDrop({super.key, this.chips});

  final LogChips? chips;

  @override
  State<DesktopDrop> createState() => _DesktopDropState();
}

class _DesktopDropState extends State<DesktopDrop> {
  String? _javaVersion;
  String? _mods;
  List<LogLine>? _errors;
  bool _dragging = false;
  Offset? offset;

  @override
  void didUpdateWidget(DesktopDrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    final logChips = widget.chips;
    if (logChips != null) {
      _javaVersion = "${logChips.javaVersion}";
      _mods = logChips.modList.map((e) => "  $e\n").join();
      _errors = logChips.errorBlock;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropTarget(
        onDragDone: (detail) async {
          debugPrint('onDragDone:');
          for (final file in detail.files) {
            debugPrint('  ${file.path} ${file.name}'
                '  ${await file.lastModified()}'
                '  ${await file.length()}'
                '  ${file.mimeType}');
          }

          final logFile = detail.files
              .firstWhereOrNull((element) => element.name == "starsector.log");

          final wrongLogRegex = RegExp(".*\.log\./d", caseSensitive: false);
          if (logFile != null) LogParser().parse(logFile);

          setState(() {
            if (logFile == null &&
                detail.files
                    .any((element) => wrongLogRegex.hasMatch(element.name))) {
              _mods = "Log file should not end in a number.";
            }
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
            color:
                _dragging ? Colors.blue.withOpacity(0.4) : Colors.transparent,
            padding: const EdgeInsets.only(left: 20, top: 20, right: 20),
            child: (widget.chips == null)
                ? Container(
                    constraints: const BoxConstraints(
                        minWidth: double.infinity, minHeight: double.infinity),
                    child: Center(
                        widthFactor: 1.5,
                        child: Text(
                          "Drop starsector.log here",
                          style: Theme.of(context).textTheme.headline4,
                        )))
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        if (_javaVersion != null)
                          Container(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(_javaVersion!,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge),
                                ],
                              )),
                        if (_mods != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Mods",
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              Text(
                                _mods!,
                                softWrap: false,
                              )
                            ],
                          ),
                        if (_errors != null)
                          // Scrollbar(
                          //     scrollbarOrientation: ScrollbarOrientation.top,
                          //     child: SingleChildScrollView(
                          //         primary: true,
                          //         scrollDirection: Axis.horizontal,
                          //         child:
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text("Errors",
                                    style:
                                        Theme.of(context).textTheme.titleLarge),
                                Expanded(
                                    child: ListView.builder(
                                        itemCount: _errors!.length,
                                        itemBuilder:
                                            (BuildContext context, int index) {
                                          return (isConsecutiveWithPreviousLine(
                                                  index))
                                              ? const Text("") // Spacer
                                              : IntrinsicHeight(
                                                  child: Row(children: [
                                                  Column(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          " ${_errors![index].lineNumber} ",
                                                          style: TextStyle(
                                                              color: Theme.of(
                                                                      context)
                                                                  .hintColor,
                                                              fontFamily:
                                                                  'RobotoMono'),
                                                        )
                                                      ]),
                                                  Expanded(
                                                      child: Text(
                                                    _errors![index].error,
                                                    style: const TextStyle(
                                                        fontFamily:
                                                            'RobotoMono'),
                                                  ))
                                                ]));
                                        }))
                              ])),
                      ])));
  }

  bool isConsecutiveWithPreviousLine(int index) {
    if (index == 0) return false;
    return _errors![index].lineNumber - 1 != _errors![index - 1].lineNumber;
  }
}
