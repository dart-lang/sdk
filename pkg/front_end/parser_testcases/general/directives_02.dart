#!/usr/bin/env dart

@FooX<int>(<int, int>{})
library foo.bar.directive;

@FooX<int>(<int, int>{})
import "foo.dart";
export "bar.dart";

import 'baz1.dart'
    if (dart.library.html) 'baz2.dart'
    if (dart.library.io) 'baz3.dart'
    as baz;
part 'bla.dart';

FooX<int>? foo() {
  print("This isn't a directive!");
  return null;
}

@FooX<int>(<int, int>{})
class Foo {
  void foo1() {}
  void foo2() {}
  void foo3() {}
  void foo4() {}
}

class FooX<E> {
  final Map<E, E> map;
  const FooX(this.map);
}
