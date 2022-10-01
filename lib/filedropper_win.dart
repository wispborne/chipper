// import 'dart:async';
//
// import 'package:drag_and_drop_windows/drag_and_drop_windows.dart' as dd;
// import 'package:flutter/material.dart';
//
// class FileDropperWin extends StatefulWidget {
//   const FileDropperWin({Key? key}) : super(key: key);
//
//   @override
//   State<FileDropperWin> createState() => _FileDropperWinState();
// }
//
// class _FileDropperWinState extends State<FileDropperWin> {
//   String _paths = 'Not received yet';
//   StreamSubscription? _subscription;
//
//   @override
//   void initState() {
//     super.initState();
//     _subscription ??= dd.dropEventStream.listen((paths) {
//       setState(() {
//         _paths = paths.join('\n');
//       });
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         ElevatedButton(
//             onPressed: () {
//               setState(() {
//                 _paths = 'aa';
//               });
//             },
//             child: const Text('Refresh')),
//         Text('Received paths:\n$_paths\n'),
//       ],
//     );
//   }
// }
