// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void argument() {
  throw new ArgumentError(499);
}

void noSuchMethod() {
  (499).doesNotExist();
}

void nullThrown() {
  throw null;
}

void range() {
  throw new RangeError.range(0, 1, 2);
}

void fallThrough() {
  nested() {}

  switch (5) {
    case 5:
      nested();
    default:
      Expect.fail("Should not reach");
  }
}

abstract class A {
  foo();
}

void abstractClassInstantiation() {
  new A();
}

void unsupported() {
  throw new UnsupportedError("unsupported");
}

void unimplemented() {
  throw new UnimplementedError("unimplemented");
}

void state() {
  return [1, 2].single;
}

void type() {
  return 1 + "string";
}

main() {
  List<Function> errorFunctions = [
    argument,
    noSuchMethod,
    nullThrown,
    range,
    fallThrough,
    abstractClassInstantiation,
    unsupported,
    unimplemented,
    state,
    type
  ];

  for (var f in errorFunctions) {
    bool hasThrown = false;
    try {
      f();
    } catch (e) {
      hasThrown = true;
      Expect.isTrue(
          e.stackTrace is StackTrace, "$e doesn't have a non-null stack trace");
    }
    Expect.isTrue(hasThrown);
  }
}
