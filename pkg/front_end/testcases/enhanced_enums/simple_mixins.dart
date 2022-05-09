// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  String get foo => "foo";
}

class B {
  int bar() => 42;
}

mixin M {
  void set callOnAssignment(void Function() f) {
    f();
  }
}

enum E1 with A { one, two }

enum E2 with A, B { one, two }

enum E3 with M { one, two }

expectEquals(x, y) {
  if (x != y) {
    throw "Expected '$x' and '$y' to be equal.";
  }
}

expectThrows(void Function() f) {
  try {
    f();
    throw "Expected function to throw.";
  } catch (e) {}
}

void throwOnCall() {
  throw 42;
}

main() {
  expectEquals(E1.one.foo, "foo");
  expectEquals(E1.two.foo, "foo");
  expectEquals(E2.one.foo, "foo");
  expectEquals(E2.two.foo, "foo");
  expectEquals(E2.one.bar(), "bar");
  expectEquals(E2.two.bar(), "bar");
  expectThrows(E3.one.callOnAssignment = throwOnCall);
  expectThrows(E3.two.callOnAssignment = throwOnCall);
}
