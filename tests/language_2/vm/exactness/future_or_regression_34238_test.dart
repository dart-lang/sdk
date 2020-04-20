import 'dart:async';

class A {
  FutureOr<int> x;
}

Future<int> foo() async => 42;

main() {
  var a = new A();
  a.x = 33;
  a.x = null;
  a.x = foo();
}
