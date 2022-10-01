// import 'package:flutter/material.dart';
// import 'package:super_clipboard/super_clipboard.dart';
// import 'package:super_drag_and_drop/super_drag_and_drop.dart';
//
// class FileDropper extends StatelessWidget {
//   const FileDropper({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return DropRegion(
//       // Formats this region can accept.
//       formats: Formats.standardFormats,
//       hitTestBehavior: HitTestBehavior.opaque,
//       onDropOver: (event) {
//         // You can inspect local data here, as well as formats of each item.
//         // However on certain platforms (mobile / web) the actual data is
//         // only available when the drop is accepted (onPerformDrop).
//         final item = event.session.items.first;
//         if (item.localData is Map) {
//           // This is a drag within the app and has custom local data set.
//         }
//         if (item.hasValue(Formats.plainText)) {
//           // this item contains plain text.
//         }
//         // This drop region only supports copy operation.
//         if (event.session.allowedOperations.contains(DropOperation.copy)) {
//           return DropOperation.copy;
//         } else {
//           return DropOperation.none;
//         }
//       },
//       onDropEnter: (event) {
//         // This is called when region first accepts a drag. You can use this
//         // to display a visual indicator that the drop is allowed.
//       },
//       onDropLeave: (event) {
//         // Called when drag leaves the region. Will also be called after
//         // drag completion.
//         // This is a good place to remove any visual indicators.
//       },
//       onPerformDrop: (event) async {
//         // Called when user dropped the item. You can now request the data.
//         // Note that data must be requested before the performDrop callback
//         // is over.
//         final item = event.session.items.first;
//         // data reader is available now
//         final reader = item.dataReader!;
//         if (reader.hasValue(Formats.plainText)) {
//           reader.getValue(Formats.plainText, (value) {
//             if (value.error != null) {
//               print('Error reading value ${value.error}');
//             } else {
//               print('Dropped text: ${value.value}');
//             }
//           });
//         }
//       },
//       child: const Padding(
//         padding: EdgeInsets.all(15.0),
//         child: Text('Drop items here'),
//       ),
//     );
//   }
// }
