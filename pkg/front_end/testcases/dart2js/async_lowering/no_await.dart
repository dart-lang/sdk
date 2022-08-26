// Wrap and return non-awaited expression.
Future<int> foo1() async {
  final c = 3;
  return c;
}

// Add null Future return.
Future<void> foo2() async {
  final c = 3;
}

// Return dynamic Future when no type.
foo3() async {
  return 234;
}

void bar(Future<int> Function() func) {
  func();
}

// Transform nested function even if parent is not convertible.
Future<bool> foo4() async {
  await Future.value(2);
  bar(() async => 3);
  return true;
}

// Convert multiple returns.
Future<int> foo5(bool x) async {
  if (x) return 123;
  return 234;
}

void main() {
  foo1();
  foo2();
  foo3();
  foo4();
  foo5(true);
}
