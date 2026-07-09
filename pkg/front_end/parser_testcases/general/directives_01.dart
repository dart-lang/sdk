#!/usr/bin/env dart
// @dart=3.0

@FooX<int>(<int, int>{})
library foo.bar.directive;

@FooX<int>(<int, int>{})
import "foo.dart";
export "bar.dart";

import 'baz1.dart'
    if (dart.library.html) 'baz2.dart'
    if (dart.library.io) 'baz3.dart' as baz;
part 'bla.dart';

@FooX<int>(<int, int>{})
class FooY {}

void foo() {
  print("This isn't a directive!");
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
