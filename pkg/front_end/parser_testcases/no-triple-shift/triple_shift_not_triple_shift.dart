// From https://github.com/dart-lang/sdk/issues/46886
extension on Symbol {
  String operator >(_) => "Greater Than used";
  String call(_) => "Called";
}

void main() {
  print(#>>>(2));
}

abstract class Foo extends List<List<List<String>>> {}
