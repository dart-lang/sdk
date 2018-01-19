// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that an omitted `new` is allowed for a non-generic class.

class C {
  final Object x;
  C(this.x); // Not const constructor.
  const C.c(this.x); // Const constructor.

  operator <(other) => this;
  operator >(other) => other;
  operator -() => this;

  C get self => this;
  C method() => self;
}

T id<T>(T x) => x;

main() {
  const cc = const C.c(42); // Canonicalized.
  var x = 42; // Avoid constant parameter.
  var c0 = new C.c(x); // Original syntax.

  // Uses of `C.c(x)` in various contexts.
  var c1 = C.c(x);
  var c2 = [C.c(x)][0];
  var c3 = {C.c(x): 0}.keys.first;
  var c4 = {0: C.c(x)}.values.first;
  var c5 = id(C.c(x));
  var c6 = C.c(x).self;
  var c7 = C.c(x).method();
  var c8 = C(C.c(x)).x;
  var c9 = -C.c(x);
  var c10 = C.c(x) < 9;
  var c11 = C(null) > C.c(x);
  var c12 = (c10 == c11) ? null : C.c(x);
  var c13 = C.c(x)..method();
  var c14;
  try {
    throw C.c(x);
  } catch (e) {
    c14 = e;
  }
  Expect.isNotNull(c12);

  switch (C.c(x)) {
    case cc:
      Expect.fail("Should not be const");
      break;
    default:
    // Success.
  }

  for (C.c(x); false; C.c(x), C.c(x)) {
    Expect.fail("Unreachable");
  }

  var values = [
    cc,
    c0,
    c1,
    c2,
    c3,
    c4,
    c5,
    c6,
    c7,
    c8,
    c9,
    c10,
    c11,
    c12,
    c13,
    c14
  ];
  Expect.allDistinct(values); // Non of them create constants.
  for (var value in values) {
    Expect.isTrue(value is C);
    Expect.equals(42, (value as C).x);
  }
}
