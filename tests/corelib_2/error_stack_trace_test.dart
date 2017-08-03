// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void argument() {
  throw new ArgumentError(499);
}

// Verify that
void noSuchMethod() {
  (499 as dynamic).doesNotExist();
}

void nullThrown() {
  throw null;
}

void range() {
  throw new RangeError.range(0, 1, 2);
}

abstract class A {
  foo();
}

void unsupported() {
  throw new UnsupportedError("unsupported");
}

void unimplemented() {
  throw new UnimplementedError("unimplemented");
}

void state() {
  [1, 2].single;
}

void cast() {
  dynamic d = 1;
  d as String;
}

main() {
  List<Function> errorFunctions = [
    argument,
    noSuchMethod,
    nullThrown, //# nullThrown: ok
    range,
    unsupported,
    unimplemented,
    state,
    cast,
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
