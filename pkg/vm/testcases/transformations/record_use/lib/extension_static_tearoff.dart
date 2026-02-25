import 'package:meta/meta.dart' show RecordUse;

extension StringUtils on String {
  @RecordUse()
  static void printHello() => print('hello');
}

void main() {
  final f = [StringUtils.printHello][0];
  print(f);
  f();
}
