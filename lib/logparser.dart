import 'package:cross_file/cross_file.dart';

void parse(XFile file) async {
  List<String> text;

  try {
    text = (await file.readAsString()).split("\n");
  } catch (e) {
    print(e);
    return;
  }

}
