import 'package:chipper/logparser.dart';
import 'package:collection/collection.dart';
import 'package:cross_file/cross_file.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';

class DesktopDrop extends StatefulWidget {
  const DesktopDrop({Key? key}) : super(key: key);

  @override
  State<DesktopDrop> createState() => _DesktopDropState();
}

class _DesktopDropState extends State<DesktopDrop> {
  final List<XFile> _list = [];
  String? _message;
  String? _errors;
  bool _dragging = false;
  Offset? offset;
  final ScrollController _horizontal = ScrollController(),
      _vertical = ScrollController();

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

          final logChips =
              logFile != null ? await LogParser().parse(logFile) : null;
          setState(() {
            _list.addAll(detail.files);

            if (logChips != null) {
              _message = "${logChips.javaVersion}"
                  "\n\nMods:\n${logChips.modList?.map((e) => "  $e\n").join()}";
              _errors =
                  "\n\nErrors:\n${logChips.errorBlock?.map((e) => "  $e\n").join()}";
            }

            if (logFile == null &&
                detail.files
                    .any((element) => wrongLogRegex.hasMatch(element.name))) {
              _message = "Log file should not end in a number.";
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
        child: Scrollbar(
            controller: _vertical,
            thumbVisibility: true,
            trackVisibility: true,
            child: Scrollbar(
                controller: _horizontal,
                thumbVisibility: true,
                trackVisibility: true,
                notificationPredicate: (notif) => notif.depth == 1,
                child: SingleChildScrollView(
                    controller: _vertical,
                    child: SingleChildScrollView(
                        controller: _horizontal,
                        scrollDirection: Axis.horizontal,
                        child: Container(
                            color: _dragging
                                ? Colors.blue.withOpacity(0.4)
                                : Colors.black26,
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                            constraints: const BoxConstraints(
                                minWidth: 200, minHeight: 200),
                            child: Column(
                              children: [
                                if (_list.isEmpty)
                                  Center(
                                      widthFactor: 1.5,
                                      child: Text(
                                        "Drop starsector.log here",
                                        style: Theme.of(context)
                                            .textTheme
                                            .headline4,
                                      )),
                                // else
                                //   Text(_list.map((e) => e.path).join("\n")),
                                // if (offset != null)
                                //   Align(
                                //     alignment: Alignment.topRight,
                                //     child: Text(
                                //       '$offset',
                                //       style: Theme.of(context).textTheme.caption,
                                //     ),
                                //   ),
                                if (_message != null)
                                  Text(
                                    _message!,
                                    softWrap: false,
                                  ),
                                if (_errors != null)
                                  Text(
                                    _errors!,
                                    softWrap: false,
                                  )
                              ],
                            )))))));
  }
}
