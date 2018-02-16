// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that an omitted `new` is allowed for a generic constructor invocation.

class C<T> {
  final T x;
  C(this.x); // Not const constructor.
  const C.c(this.x); // Const constructor.

  operator <(other) => this;
  operator >(other) => other;
  operator -() => this;

  C<T> get self => this;
  C<T> method() => self;
}

T id<T>(T x) => x;

main() {
  const cc = const C<int>.c(42); // Canonicalized.

  var c0 = new C<int>(42); // Original syntax.

  // Uses of `C<int>(42)` in various contexts.
  var c1 = C<int>(42);
  var c2 = [C<int>(42)][0];
  var c3 = {C<int>(42): 0}.keys.first;
  var c4 = {0: C<int>(42)}.values.first;
  var c5 = id(C<int>(42));
  var c6 = C<int>(42).self;
  var c7 = C<int>(42).method();
  var c8 = C(C<int>(42)).x;
  var c9 = -C<int>(42);
  var c10 = C<int>(42) < 9;
  var c11 = C(null) > C<int>(42);
  var c12 = (c10 == c11) ? null : C<int>(42);
  var c13 = C<int>(42)..method();
  var c14;
  try {
    throw C<int>(42);
  } catch (e) {
    c14 = e;
  }

  switch (C<int>(42)) {
    case cc:
      Expect.fail("Should not be const");
      break;
    default:
    // Success.
  }

  for (C<int>(42); false; C<int>(42), C<int>(42)) {
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
    Expect.isTrue(value is C<int>);
    Expect.equals(42, (value as C<int>).x);
  }
}
