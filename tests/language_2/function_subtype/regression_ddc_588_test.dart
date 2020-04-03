import "package:expect/expect.dart";

// regression test for ddc #588

typedef int Int2Int(int x);

void foo(List<Int2Int> list) {
  list.forEach((f) => print(f(42)));
}

void main() {
  var l = <Function>[];
  Expect.throwsTypeError(() => foo(l));
}
