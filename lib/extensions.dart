import 'dart:convert';
import 'dart:io';

import 'package:fimber/fimber.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

extension DoubleExt on double {
  String bytesAsReadableMB() => "${(this / 1000000).toStringAsFixed(3)} MB";

  double coerceAtLeast(double minimumValue) {
    return this < minimumValue ? minimumValue : this;
  }

  double coerceAtMost(double maximumValue) {
    return this > maximumValue ? maximumValue : this;
  }
}
// Long.bytesAsReadableMB: String
// get() = "%.3f MB".format(this / 1000000f)

extension StringBufferExt on StringBuffer {
  appendAndPrint(String line, Function(String) traceOut) {
    traceOut(line);
    writeln(line);
  }
}

extension StringExt on String {
  String ifBlank(String str) {
    if (isEmpty) return str;
    return this;
  }

  Directory toDirectory() => Directory(this);

  File toFile() => File(this);

  String take(int n) => length < n ? this : substring(0, n);

  String takeLast(int n) => length < n ? this : substring(length - n);

  String takeWhile(bool Function(String) predicate) {
    var index = 0;
    while (index < length && predicate(this[index])) {
      index++;
    }
    return substring(0, index);
  }

  String removePrefix(String prefix) {
    if (startsWith(prefix)) {
      return substring(prefix.length);
    }
    return this;
  }

  /// Warning: probably not fast.
  String fixJson() {
    var fixed = replaceAll(r"\#", "#");
    try {
      return json.encode(loadYaml(fixed));
    } catch (e) {
      Fimber.d("Unable to fix json: $fixed");
      rethrow;
    }
  }

  Map<String, dynamic> fixJsonToMap() {
    return jsonDecode(fixJson());
  }

  /// Returns a string having leading characters from the chars array removed.
  String trimStart(String prefix) {
    var index = 0;
    while (index < length && prefix.contains(this[index])) {
      index++;
    }
    return substring(index);
  }

  String trimEnd(String suffix) {
    var index = length - 1;
    while (index >= 0 && suffix.contains(this[index])) {
      index--;
    }
    return substring(0, index + 1);
  }

  // Helper for comparing number-like strings
  int compareRecognizingNumbers(String str2) {
    final chunks1 = splitIntoAlphaAndNumeric();
    final chunks2 = str2.splitIntoAlphaAndNumeric();

    for (var i = 0; i < chunks1.length || i < chunks2.length; i++) {
      final chunk1 = _getSafeChunk(chunks1, i);
      final chunk2 = _getSafeChunk(chunks2, i);

      final result = _compareChunks(chunk1, chunk2);
      if (result != 0) return result;
    }

    return 0;
  }

  String filter(bool Function(String) predicate) => characters.where(predicate).join();

  /// Breaks a string into chunks of letters and numbers.
  /// "55hhb3vv-5 s" -> ["55", "hhb", "3", "vv", "5", "s"]
  List<String> splitIntoAlphaAndNumeric() {
    final str = this;

    return ([0] + _letterDigitSplitterRegex.allMatches(str).map((m) => m.start).toList() + [str.length])
        .zipWithNext((l, r) => str.substring(l, r).filter((it) => RegExp(r"[a-zA-Z0-9]").hasMatch(it)))
        .filter((p0) => p0.isNotEmpty)
        .toList();
  }

  bool containsAny(Iterable<String> elements) {
    return elements.any(contains);
  }
}

final _letterDigitSplitterRegex = RegExp(r"(?<=\D)(?=\d)|(?<=\d)(?=\D)");

String _getSafeChunk(List<String> chunks, int index) => index < chunks.length ? chunks[index] : "0";

int _compareChunks(String chunk1, String chunk2) {
  final int1 = int.tryParse(chunk1);
  final int2 = int.tryParse(chunk2);

  if (int1 != null && int2 != null) {
    return int1.compareTo(int2);
  } else {
    return chunk1.compareTo(chunk2);
  }
}

extension FileSystemEntityExt on FileSystemEntity {
  FileSystemEntity resolve(String path) {
    return File(p.join(absolute.path, path));
  }

  FileSystemEntity normalize() {
    return File(p.normalize(absolute.path));
  }

  void moveTo(Directory destDir, {bool overwrite = false}) {
    if (this is Directory) {
      (this as Directory).moveDirectory(destDir, overwrite: overwrite);
    } else if (this is File) {
      (this as File).moveTo(destDir, overwrite: overwrite);
    }
  }

  bool isFile() => statSync().type == FileSystemEntityType.file;

  bool isDirectory() => statSync().type == FileSystemEntityType.directory;

  File toFile() => File(absolute.path);

  Directory toDirectory() => Directory(absolute.path);

  bool existsSync() => FileSystemEntity.typeSync(path) != FileSystemEntityType.notFound;
}

extension FileExt on File {
  String relativePath(Directory modFolder) => p.normalize(p.relative(absolute.path, from: modFolder.absolute.path));

  String relativeTo(Directory modFolder) => relativePath(modFolder);

  String get nameWithoutExtension => p.basenameWithoutExtension(path);

  String get nameWithExtension => p.basename(path);

  String get extension => p.extension(path);

  File get normalize => File(p.normalize(absolute.path));

  File moveTo(Directory destDir, {bool overwrite = false}) {
    var destFile = destDir.resolve(nameWithExtension);
    if (destFile.existsSync()) {
      if (overwrite) {
        destFile.deleteSync();
      } else {
        Fimber.i("Skipping file move (file already exists): $this to $destFile");
        return this;
      }
    }
    return renameSync(destFile.path).normalize;
  }

  String readAsStringSyncAllowingMalformed() {
    return utf8.decode(readAsBytesSync(), allowMalformed: true);
  }

  /// From https://stackoverflow.com/a/64569532/1622788
  Future<bool> isWritable() async {
    try {
      final tmp = openWrite(mode: FileMode.append);
      await tmp.flush();
      await tmp.close(); // errors from opening will be thrown at this point
      return true;
    } catch (e) {
      Fimber.d("File $path is not writable: $e");
      return false;
    }
  }

  Future<bool> isNotWritable() async {
    return !(await isWritable());
  }
}

extension DirectoryExt on Directory {
  Directory get normalize => Directory(p.normalize(absolute.path));

  String get name => p.basename(path);

  Future<void> moveDirectory(Directory destDir, {bool overwrite = false}) async {
    try {
      renameSync(destDir.absolute.path);
    } catch (e) {
      // Simple rename didn't work. Time to get real.
      copyDirectory(destDir, overwrite: overwrite);
      deleteSync(recursive: true);
    }
  }

  /// Copied from FileUtils.java::doCopyDirectory in Apache Commons IO.
  Future<void> copyDirectory(Directory destDir, {bool overwrite = false}) async {
    final srcFiles = listSync(recursive: false).map((e) => e.path.toFile());
    destDir.createSync(recursive: true); // mkdirs

    for (var srcFile in srcFiles) {
      final destFile = destDir.resolve(srcFile.nameWithExtension);
      if (srcFile.isDirectory()) {
        srcFile.toDirectory().copyDirectory(destFile.toDirectory(), overwrite: overwrite);
      } else if (srcFile.isFile()) {
        if (destFile.existsSync() && !overwrite) {
          Fimber.d("Skipping file copy (file already exists): $srcFile to $destFile");
          continue;
        } else {
          srcFile.copy(destFile.path);
        }
      }
    }
  }
}

extension IterableExt<T> on Iterable<T> {
  String joinToString({String separator = ", ", required String Function(T element) transform}) {
    return map(transform).join(separator);
  }

  Iterable<T> filter(bool Function(T) predicate) {
    return where(predicate);
  }

  Iterable<R> flatMap<R>(Iterable<R> Function(T) transform) {
    return map(transform).expand((element) => element);
  }

  Iterable<R> mapNotNull<R>(R? Function(T) transform) {
    return map(transform).where((element) => element != null).map((e) => e!);
  }

  T? maxByOrNull<R extends Comparable<R>>(R Function(T) selector) {
    if (isEmpty) return null;
    var maxElement = first;
    var maxValue = selector(maxElement);
    for (var element in skip(1)) {
      var value = selector(element);
      if (value.compareTo(maxValue) > 0) {
        maxElement = element;
        maxValue = value;
      }
    }
    return maxElement;
  }

  Iterable<T> sortedByDescending<R extends Comparable<R>>(R Function(T) selector) {
    return toList()..sort((a, b) => selector(b).compareTo(selector(a)));
  }

  bool containsAll(Iterable<T> elements) {
    return elements.every(contains);
  }

  T random() {
    return elementAt(DateTime.now().microsecond % length);
  }

  T? getOrNull(int index) {
    if (index < 0 || index >= length) return null;
    return elementAt(index);
  }

  T? minByOrNull<R extends Comparable<R>>(R Function(T) selector) {
    if (isEmpty) return null;
    var minElement = first;
    var minValue = selector(minElement);
    for (var element in skip(1)) {
      var value = selector(element);
      if (value.compareTo(minValue) < 0) {
        minElement = element;
        minValue = value;
      }
    }
    return minElement;
  }

  /// Combines the current element with the next element in the iterable using the provided [transform] function.
  /// From Gemini.
  ///
  /// Example:
  /// ```dart
  /// final numbers = [1, 4, 9, 16];
  /// final differences = numbers.zipWithNext((a, b) => b - a);
  /// print(differences); // Output: [3, 5, 7]
  /// ```
  List<R> zipWithNext<R>(R Function(T a, T b) transform) {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return <R>[];

    final result = <R>[];
    var current = iterator.current;

    while (iterator.moveNext()) {
      final next = iterator.current;
      result.add(transform(current, next));
      current = next;
    }

    return result;
  }

  Iterable<T> dropUntil(bool Function(T) predicate) {
    var found = false;
    return where((element) {
      if (found) return true;
      if (predicate(element)) {
        found = true;
        return true;
      }
      return false;
    });
  }
}

extension NullableIterableExt<T> on Iterable<T>? {
  Iterable<T> orEmpty() => this ?? [];
}

extension IterableFileExt on Iterable<File> {
  Directory? rootFolder() {
    final result = minByOrNull<num>((File file) => file.path.length);
    return result?.isDirectory() != true ? null : result?.toDirectory();
  }
}

extension ListExt<T> on List<T> {
  void removeAll(Iterable<T> elements) {
    removeWhere((element) => elements.contains(element));
  }
}

extension IntExt on int {
  static const int MIN_VALUE = 0x80000000;

  int highestOneBit() {
    return this & (MIN_VALUE >>> numberOfLeadingZeros());
  }

  String bytesAsReadableMB() => "${(this / 1000000).toStringAsFixed(2)} MB";

  /// From Java
  int numberOfLeadingZeros() {
    // HD, Count leading 0's
    var i = this;
    if (i <= 0) {
      return i == 0 ? 32 : 0;
    }
    int n = 31;
    if (i >= 1 << 16) {
      n -= 16;
      i >>>= 16;
    }
    if (i >= 1 << 8) {
      n -= 8;
      i >>>= 8;
    }
    if (i >= 1 << 4) {
      n -= 4;
      i >>>= 4;
    }
    if (i >= 1 << 2) {
      n -= 2;
      i >>>= 2;
    }
    return n - (i >>> 1);
  }

  int coerceAtLeast(int minimumValue) {
    return this < minimumValue ? minimumValue : this;
  }

  int coerceAtMost(int maximumValue) {
    return this > maximumValue ? maximumValue : this;
  }
}

// List<Mod>.getBytesUsedByDedupedImages(): Long = this
// .flatMap { mod -> mod.images.map { img -> mod.info.modFolder to img } }
// .distinctBy { (modFolder: Path, image: ModImage) -> image.file.relativeTo(modFolder).pathString + image.file.name }
//     .sumOf { it.second.bytesUsed }

extension NumListExt on List<num> {
  num sum() {
    return fold(0, (previousValue, element) => previousValue + element);
  }

  // From Gemini
  num findClosest(num targetValue) {
    num? closestValue;
    num? minDistance;

    for (final value in this) {
      final distance = (targetValue - value).abs(); // Calculate absolute distance

      if (minDistance == null || distance < minDistance) {
        closestValue = value;
        minDistance = distance;
      }
    }

    return closestValue!; // Assuming the list 'values' will not be empty
  }
}

extension ObjectExt<T> on T {
  also(Function(T) block) {
    block(this);
    return this;
  }

  R let<R>(R Function(T) block) {
    return block(this);
  }

  T run(T Function() block) {
    return block();
  }
}

extension HexColor on Color {
  /// String is in the format "aabbcc" or "ffaabbcc" with an optional leading "#".
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Prefixes a hash sign if [leadingHashSign] is set to `true` (default is `true`).
  String toHex({bool leadingHashSign = true}) => '${leadingHashSign ? '#' : ''}'
      '${alpha.toRadixString(16).padLeft(2, '0')}'
      '${red.toRadixString(16).padLeft(2, '0')}'
      '${green.toRadixString(16).padLeft(2, '0')}'
      '${blue.toRadixString(16).padLeft(2, '0')}';

  MaterialColor createMaterialColor() {
    final color = this;
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }

    return MaterialColor(color.value, swatch);
  }
}
