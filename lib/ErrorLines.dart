import 'package:chipper/extensions.dart';
import 'package:flutter/material.dart';

abstract class LogLine {
  int lineNumber;
  String fullError;
  bool shouldWrap = false;

  @mustCallSuper
  LogLine(this.lineNumber, this.fullError);

  Widget createLogWidget(BuildContext context);
}

class GeneralErrorLogLine extends LogLine {
  static final RegExp _logRegex =
      RegExp("(?<millis>\\d*?) +(?<thread>\\[.*?\\]) +(?<level>\\w+?) +(?<namespace>.*?) +- +(?<error>.*)");

  String? time;
  String? thread;
  String? logLevel;
  String? namespace;
  String? error;

  GeneralErrorLogLine(super.lineNumber, super.fullError);

  static GeneralErrorLogLine? tryCreate(int lineNumber, String fullError) {
    final match = _logRegex.firstMatch(fullError);

    if (match != null) {
      final log = GeneralErrorLogLine(lineNumber, fullError);
      log.time = match.namedGroup("millis");
      log.thread = match.namedGroup("thread");
      log.logLevel = match.namedGroup("level");
      log.namespace = match.namedGroup("namespace");
      log.error = match.namedGroup("error");
      return log;
    } else {
      return null;
    }
  }

  @override
  Widget createLogWidget(BuildContext context) {
    return GeneralErrorLogLineWidget(line: this);
  }
}

class GeneralErrorLogLineWidget extends StatelessWidget {
  final GeneralErrorLogLine line;

  const GeneralErrorLogLineWidget({super.key, required this.line});

  @override
  Widget build(BuildContext context) {
    return RichText(
      softWrap: line.shouldWrap,
        text: TextSpan(
            text: "",
            style:
                TextStyle(fontFamily: 'RobotoMono', color: Theme.of(context).colorScheme.onSurface.withAlpha(240)),
            children: [
          TextSpan(text: line.time, style: TextStyle(color: Theme.of(context).disabledColor)),
          TextSpan(text: line.thread?.prepend(" "), style: TextStyle(color: Theme.of(context).hintColor)),
          TextSpan(text: line.logLevel?.prepend(" "), style: TextStyle(color: Theme.of(context).disabledColor)),
          TextSpan(
              text: line.namespace?.prepend(" "),
              style: TextStyle(color: Theme.of(context).colorScheme.tertiary.withAlpha(200))),
          TextSpan(
              text: line.error?.prepend(" "),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(240))),
        ]));
  }
}

class StacktraceLogLine extends LogLine {
  static final RegExp _stacktraceRegex = RegExp("(?<at>at) (?<namespace>.*)\\.(?<method>.*?\\()(?<classAndLine>.*)\\)");

  String? at;
  String? namespace;
  String? method;

  /// No parentheses.
  String? classAndLine;

  StacktraceLogLine(super.lineNumber, super.fullError);

  static StacktraceLogLine? tryCreate(int lineNumber, String fullError) {
    final match = _stacktraceRegex.firstMatch(fullError);

    if (match != null) {
      final log = StacktraceLogLine(lineNumber, fullError);
      log.at = match.namedGroup("at");
      log.namespace = match.namedGroup("namespace");
      log.method = match.namedGroup("method");
      log.classAndLine = match.namedGroup("classAndLine");
      return log;
    } else {
      return null;
    }
  }

  @override
  Widget createLogWidget(BuildContext context) {
    return StacktraceLogLineWidget(logLine: this);
  }
}

class StacktraceLogLineWidget extends StatelessWidget {
  final StacktraceLogLine logLine;

  const StacktraceLogLineWidget({super.key, required this.logLine});

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    final obfColor = theme.disabledColor;
    final isObf = logLine.classAndLine == "Unknown Source"; // Hardcoding, baby

    return RichText(
        softWrap: logLine.shouldWrap,
        text: TextSpan(
            text: "",
            style:
                TextStyle(fontFamily: 'RobotoMono', color: isObf? obfColor : theme.colorScheme.onSurface.withAlpha(240)),
            children: [
          TextSpan(text: logLine.at, style: TextStyle(color: theme.hintColor)),
          TextSpan(text: logLine.namespace?.prepend(" "), style: TextStyle(color: isObf? obfColor : theme.colorScheme.onSurface.withAlpha(240))),
          TextSpan(text: logLine.method?.prepend(" "), style: TextStyle(color: isObf? obfColor : theme.disabledColor)),
          TextSpan(
              text: logLine.namespace?.prepend(" "),
              style: TextStyle(color: isObf? obfColor : theme.colorScheme.tertiary.withAlpha(200))),
          TextSpan(
              text: logLine.classAndLine?.prepend(" (").append(")"),
              style: TextStyle(color: isObf? obfColor : theme.colorScheme.onSurface.withAlpha(240))),
        ]));
  }
}

class UnknownLogLine extends LogLine {
  UnknownLogLine(super.lineNumber, super.fullError);

  static UnknownLogLine? tryCreate(int lineNumber, String fullError) {
    return UnknownLogLine(lineNumber, fullError);
  }

  @override
  Widget createLogWidget(BuildContext context) {
    return UnknownLogLineWidget(line: this);
  }
}

class UnknownLogLineWidget extends StatelessWidget {
  final UnknownLogLine line;

  const UnknownLogLineWidget({super.key, required this.line});

  @override
  Widget build(BuildContext context) {
    return RichText(
        softWrap: line.shouldWrap,
        text: TextSpan(
            text: line.fullError,
            style:
            TextStyle(fontFamily: 'RobotoMono', color: Theme.of(context).disabledColor),
            children: [
              // TextSpan(text: line.at, style: TextStyle(color: Theme.of(context).hintColor)),
              // TextSpan(text: line.namespace?.prepend(" "), style: TextStyle(color: isObf? obfColor : Theme.of(context).hintColor)),
              // TextSpan(text: line.method?.prepend(" "), style: TextStyle(color: isObf? obfColor : Theme.of(context).disabledColor)),
              // TextSpan(
              //     text: line.namespace?.prepend(" "),
              //     style: TextStyle(color: isObf? obfColor : Theme.of(context).colorScheme.tertiary.withAlpha(200))),
              // TextSpan(
              //     text: line.classAndLine?.prepend(" (").append(")"),
              //     style: TextStyle(color: isObf? obfColor : Theme.of(context).colorScheme.onSurface.withAlpha(240))),
            ]
        ));
  }
}
