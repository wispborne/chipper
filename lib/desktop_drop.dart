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

  bool _dragging = false;

  Offset? offset;

  @override
  Widget build(BuildContext context) {
    return DropTarget(
      onDragDone: (detail) async {
        setState(() {
          _list.addAll(detail.files);
        });

        debugPrint('onDragDone:');
        for (final file in detail.files) {
          debugPrint('  ${file.path} ${file.name}'
              '  ${await file.lastModified()}'
              '  ${await file.length()}'
              '  ${file.mimeType}');
        }
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
        height: 200,
        width: 200,
        color: _dragging ? Colors.blue.withOpacity(0.4) : Colors.black26,
        child: Stack(
          children: [
            if (_list.isEmpty)
              const Center(child: Text("Drop here"))
            else
              Text(_list.map((e) => e.path).join("\n")),
            if (offset != null)
              Align(
                alignment: Alignment.topRight,
                child: Text(
                  '$offset',
                  style: Theme.of(context).textTheme.caption,
                ),
              )
          ],
        ),
      ),
    );
  }
}
