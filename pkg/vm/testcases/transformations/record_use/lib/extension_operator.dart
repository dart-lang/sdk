import 'package:meta/meta.dart' show RecordUse;

extension Ext on String {
  @RecordUse()
  String operator -(String other) => this.replaceAll(other, '');
}

void main() {
  final c = 'abc';
  print(c - 'b');
}
