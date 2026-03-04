import 'package:meta/meta.dart' show RecordUse;

extension StringUtils on String {
  @RecordUse()
  static void printHello(String s) => print('hello $s');
}

void main() {
  StringUtils.printHello('arg');
}
