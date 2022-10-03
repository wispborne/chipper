import 'package:chipper/AppState.dart';
import 'package:chipper/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:window_size/window_size.dart';

import 'config.dart';

void main() async {
  Hive.init("chipper.config");
  box = await Hive.openBox("chipperTheme");
  runApp(const MyApp());
  setWindowTitle(MyApp.title + MyApp.subtitle);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static const title = "Chipper v1.1.0";
  static const subtitle = "  by Wisp";

  @override
  State<StatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    AppState.theme.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chipper',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: AppState.theme.currentTheme(),
      home: const MyHomePage(title: MyApp.title, subTitle: MyApp.subtitle),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, this.subTitle});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;
  final String? subTitle;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      // appBar: AppBar(
      //     // Here we take the value from the MyHomePage object that was created by
      //     // the App.build method, and use it to set our appbar title.
      //     title: IntrinsicHeight(
      //         child: Row(children: [
      //   Text(
      //     widget.title,
      //     style: TextStyle(
      //         fontSize: Theme.of(context).textTheme.titleLarge?.fontSize),
      //   ),
      //   if (widget.subTitle != null)
      //     Column(
      //       mainAxisAlignment: MainAxisAlignment.end,
      //       children: [
      //         Text(
      //           widget.subTitle!,
      //           style: TextStyle(
      //               fontSize: Theme.of(context).textTheme.titleSmall?.fontSize),
      //         ),
      //       ],
      //     )
      // ]))),
      body: SelectionArea(
          child: Stack(children: [
        Center(
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.

            child: Column(
                // Column is also a layout widget. It takes a list of children and
                // arranges them vertically. By default, it sizes itself to fit its
                // children horizontally, and tries to be as tall as its parent.
                //
                // Invoke "debug painting" (press "p" in the console, choose the
                // "Toggle Debug Paint" action from the Flutter Inspector in Android
                // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
                // to see the wireframe for each widget.
                //
                // Column has various properties to control how it sizes itself and
                // how it positions its children. Here we use mainAxisAlignment to
                // center the children vertically; the main axis here is the vertical
                // axis because Columns are vertical (the cross axis would be
                // horizontal).
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
              Expanded(
                  flex: 1,
                  child: DesktopDrop(
                    chips: chips,
                  )
                  // FileDropperWin()
                  // FileDropper()
                  )
            ])),
        Align(
            alignment: Alignment.topRight,
            child: IconButton(
                onPressed: () => AppState.theme.switchThemes(),
                icon: Icon(AppState.theme.currentTheme() == ThemeMode.dark ? Icons.sunny : Icons.mode_night))),
      ])),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (chips != null) {
            Clipboard.setData(
                ClipboardData(text: chips?.errorBlock.map((e) => "${e.lineNumber}: ${e.fullError}").join('\n')));
          }
        },
        tooltip: 'Copy',
        child: const Icon(Icons.copy),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
