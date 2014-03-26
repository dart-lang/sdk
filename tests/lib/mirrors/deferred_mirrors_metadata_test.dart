@A(const B())
library main;

@B()
import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import "dart:math";

import 'deferred_mirrors_metadata_lib.dart' deferred as lib1;

class A {
  final B b;
  const A(this.b);
  String toString() => "A";
}

class B {
  const B();
  String toString() => "B";
}

class C {
  const C();
  String toString() => "C";
}

void main() {
  asyncStart();
  lib1.loadLibrary().then((_) {
    Expect.equals("ABC", lib1.foo());
    asyncEnd();
  });
}
