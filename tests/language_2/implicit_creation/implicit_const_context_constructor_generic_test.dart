// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that constructor invocations are constant
// when evaluated in a const context.

class C<T> {
  final T x;
  const C(this.x);

  // Static const.
  static const staticConst = C<int>(42);
}

// Top-level const.
const topConst = C<int>(42);

main() {
  const c0 = const C<int>(42); // Explicit const.

  // RHS of const local variable.
  const c1 = C<int>(42);

  // Inside const expression.
  var c2 = (const [C<int>(42)])[0]; // List element.
  var c3 = (const {C<int>(42): 0}).keys.first; // Map key.
  var c4 = (const {0: C<int>(42)}).values.first; // Map value.
  var c5 = (const C(C<int>(42))).x; // Constructor argument.

  Expect.identical(c0, c1);
  Expect.identical(c0, c2);
  Expect.identical(c0, c3);
  Expect.identical(c0, c4);
  Expect.identical(c0, c5);
  Expect.identical(c0, C.staticConst);
  Expect.identical(c0, topConst);

  // Switch case expression.
  switch (c0) {
    case C<int>(42):
      break;
    default:
      Expect.fail("Didn't match constant");
  }

  // Annotation argument.
  // (Cannot check that it's const, just that it's accepted).
  @C(C<int>(42))
  var foo = null;
  foo; // avoid "unused" hints.
}
