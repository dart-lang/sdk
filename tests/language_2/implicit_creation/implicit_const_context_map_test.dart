// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test that map literals are constant when evaluated in a const context.

class C {
  final Object x;
  const C(this.x);

  // Static const.
  static const staticConst = <int, int>{37: 87};
}

// Top-level const.
const topConst = <int, int>{37: 87};

main() {
  const c0 = const <int, int>{37: 87}; // Explicit const.

  // RHS of const local variable.
  const c1 = <int, int>{37: 87};

  // Inside const expression.
  var c2 = (const [
    <int, int>{37: 87}
  ])[0]; // List element.
  var c3 = (const {
    <int, int>{37: 87}: 0
  })
      .keys
      .first; // Map key.
  var c4 = (const {
    0: <int, int>{37: 87}
  })
      .values
      .first; // Map value.
  var c5 = (const C(<int, int>{37: 87})).x; // Constructor argument.

  Expect.identical(c0, c1);
  Expect.identical(c0, c2);
  Expect.identical(c0, c3);
  Expect.identical(c0, c4);
  Expect.identical(c0, c5);
  Expect.identical(c0, C.staticConst);
  Expect.identical(c0, topConst);

  // Switch case expression.
  switch (c0) {
    case <int, int>{37: 87}:
      break;
    default:
      Expect.fail("Didn't match constant");
  }

  // Annotation argument.
  // (Cannot check that it's const, just that it's accepted).
  @C(<int, int>{37: 87})
  var foo = null;
  foo; // avoid "unused" hints.
}
