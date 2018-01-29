// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

import "implicit_new_prefix_constructor_test.dart" as prefix;

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

  var c0 = new prefix.C(42); // Original syntax.

  // Uses of `prefix.C(42)` in various contexts.
  var c1 = prefix.C(42);
  var c2 = [prefix.C(42)][0];
  var c3 = {prefix.C(42): 0}.keys.first;
  var c4 = {0: prefix.C(42)}.values.first;
  var c5 = id(prefix.C(42));
  var c6 = prefix.C(42).self;
  var c7 = prefix.C(42).method();
  var c8 = C(prefix.C(42)).x;
  var c9 = -prefix.C(42);
  var c10 = prefix.C(42) < 9;
  var c11 = C(null) > prefix.C(42);
  var c12 = (c10 == c11) ? null : prefix.C(42);
  var c13 = prefix.C(42)..method();
  var c14;
  try {
    throw prefix.C(42);
  } catch (e) {
    c14 = e;
  }
  Expect.isNotNull(c12);

  switch (prefix.C(42)) {
    case cc:
      Expect.fail("Should not be const");
      break;
    default:
    // Success.
  }

  for (prefix.C(42); false; prefix.C(42), prefix.C(42)) {
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
