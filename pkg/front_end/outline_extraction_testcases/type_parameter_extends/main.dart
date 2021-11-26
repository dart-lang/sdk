import "foo.dart";

class A<T extends Bar, U extends Baz> {
  T? aMethod1() {}
  U? aMethod2() {}
}

mixin A2<T extends Bar2, U extends Baz2> {
  T? aMethod1() {}
  U? aMethod2() {}
}

extension A3<T extends Bar3, U extends Baz3> on Object {
  T? aMethod1() {}
  U? aMethod2() {}
}
