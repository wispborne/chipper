import 'dart:collection';
import 'dart:ui';

import 'package:chipper/AppState.dart';
import 'package:chipper/copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ErrorLines.dart';
import 'ModEntry.dart';

class Readout extends StatelessWidget {
  Readout(LogChips chips, {Key? key}) : super(key: key) {
    _chips = chips;

    _gameVersion = _chips.gameVersion ?? "Not found in log.";
    _os = _chips.os ?? "Not found in log.";
    _javaVersion = _chips.javaVersion ?? "Not found in log.";
    _mods = _chips.modList;
    _errors = _chips.errorBlock.reversed.toList(growable: false);
  }

  late LogChips _chips;
  String? _gameVersion;
  String? _os;
  String? _javaVersion;
  UnmodifiableListView<ModEntry>? _mods;
  List<LogLine>? _errors;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const iconOpacity = 140;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (_gameVersion != null || _javaVersion != null)
        Container(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Text("System", style: theme.textTheme.titleLarge),
                  IconButton(
                    tooltip: "Copy",
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: createSystemCopyString(_chips)));
                    },
                    icon: Icon(Icons.copy, color: theme.iconTheme.color?.withAlpha(iconOpacity)),
                    iconSize: 20,
                  )
                ]),
                Text("Starsector: ${_gameVersion!}\nOS: $_os\nJRE: $_javaVersion",
                    style: TextStyle(color: theme.colorScheme.onSurface.withAlpha(240))),
              ],
            )),
      if (_mods != null)
        Container(
            padding: const EdgeInsets.only(bottom: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Text("Mods (${_mods?.length})", style: theme.textTheme.titleLarge),
                  IconButton(
                    tooltip: "Copy",
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: createModsCopyString(_chips, minify: false)));
                    },
                    icon: Icon(
                      Icons.copy,
                      color: theme.iconTheme.color?.withAlpha(iconOpacity),
                    ),
                    iconSize: 20,
                  ),
                  IconButton(
                    tooltip: "Copy (less info)",
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: createModsCopyString(_chips, minify: true)));
                    },
                    icon: Icon(Icons.copy, color: theme.iconTheme.color?.withAlpha(iconOpacity)),
                    iconSize: 14,
                  ),
                  IconButton(
                    tooltip: "Popup",
                    onPressed: () {
                      _showMyDialog(context, body: _mods!.map((e) => e.createWidget(context)).toList());
                    },
                    icon: Icon(Icons.open_in_full, color: theme.iconTheme.color?.withAlpha(iconOpacity)),
                    iconSize: 20,
                  ),
                ]),
                ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 150),
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
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text("Errors", style: theme.textTheme.titleLarge),
            IconButton(
              tooltip: "Copy",
              onPressed: () {
                Clipboard.setData(ClipboardData(text: createErrorsCopyString(_chips)));
              },
              icon: Icon(Icons.copy, color: theme.iconTheme.color?.withAlpha(iconOpacity)),
              iconSize: 20,
            )
          ]),
          Expanded(
              // child: Scrollbar(
              //     scrollbarOrientation:
              //         ScrollbarOrientation.left,
              child: ListView.builder(
                  itemCount: _errors!.length,
                  // controller: _scroller,
                  reverse: true,
                  itemBuilder: (BuildContext context, int index) {
                    return _errors![index].isPreviousThreadLine
                        ? Container(
                            height: 0,
                          )
                        : Column(children: [
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
                                    Row(children: [
                                      if (isConsecutiveWithPreviousLine(index))
                                        SizedBox(
                                            height: 15,
                                            width: 20,
                                            child: IconButton(
                                              onPressed: () {
                                                var snacker = ScaffoldMessenger.of(context);
                                                snacker.clearSnackBars();
                                                var prevThreadMessage = _errors!
                                                    .sublist(0, index)
                                                    .lastWhere((element) => element.isPreviousThreadLine);
                                                snacker.showSnackBar(SnackBar(
                                                  behavior: SnackBarBehavior.floating,
                                                  content: SelectionArea(
                                                      child: Row(children: [
                                                    Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          prevThreadMessage.createLogWidget(context),
                                                          _errors![index].createLogWidget(context)
                                                        ]),
                                                        const Spacer(),
                                                        IconButton(
                                                          onPressed: () => snacker.clearSnackBars(),
                                                          icon: const Icon(Icons.close),
                                                          color: theme.colorScheme.onInverseSurface,
                                                        ),
                                                  ])),
                                                  duration: const Duration(days: 1),
                                                ));
                                              },
                                              padding: EdgeInsets.zero,
                                              splashRadius: 15,
                                              icon: Icon(
                                                Icons.info_outline_rounded,
                                                color: theme.disabledColor,
                                              ),
                                              iconSize: 15,
                                              tooltip: "View previous entry on this thread.",
                                            ))
                                      else
                                        Container(
                                          width: 20,
                                        ),
                                      Text(
                                        " ${_errors![index].lineNumber}  ",
                                        style: TextStyle(
                                            color: theme.hintColor.withAlpha(40),
                                            fontFeatures: const [FontFeature.tabularFigures()]),
                                      )
                                    ])
                                  ]),
                                  Expanded(child: _errors![index].createLogWidget(context))
                                ])))
                          ]);
                  }))
        ])),
    ]);
  }

  bool isConsecutiveWithPreviousLine(int index) {
    if (index == _errors!.length - 1) return false;
    return _errors![index].lineNumber - 1 != _errors![index + 1].lineNumber;
  }
}

Future<void> _showMyDialog(BuildContext context, {String? title, List<Widget>? body}) async {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: title == null ? null : Text(title),
        content: SingleChildScrollView(
          child: SelectionArea(
              child: ListBody(
            children: body ?? [],
          )),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Close'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}
