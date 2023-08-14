// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that equality is allowed for receivers of specific types.

import "package:expect/expect.dart";

main() {
  const c = C(); // Does not override operator==.
  const d = D(); // Overrides operator==.

  // Allowed if receiver has primitive equality...
  Expect.isTrue(const T.eq(1, 1).value);
  Expect.isTrue(const T.eq(1.5, 1.5).value);
  Expect.isTrue(const T.eq("", "").value);
  Expect.isTrue(const T.eq(true, true).value);
  Expect.isTrue(const T.eq(null, null).value);
  Expect.isTrue(const T.eq(c, c).value);
  Expect.isTrue(const T.eq(E.value1, E.value1).value);

  Expect.isFalse(const T.eq(1, c).value);
  Expect.isFalse(const T.eq(1.5, c).value);
  Expect.isFalse(const T.eq("", c).value);
  Expect.isFalse(const T.eq(true, c).value);
  Expect.isFalse(const T.eq(null, c).value);
  Expect.isFalse(const T.eq(E.value1, c).value);

  Expect.isFalse(const T.eq(1, d).value);
  Expect.isFalse(const T.eq(1.5, d).value);
  Expect.isFalse(const T.eq("", d).value);
  Expect.isFalse(const T.eq(true, d).value);
  Expect.isFalse(const T.eq(null, d).value);
  Expect.isFalse(const T.eq(c, d).value);
  Expect.isFalse(const T.eq(E.value1, d).value);

  // ... or if second operand is Null.
  Expect.isFalse(const T.eq(1, null).value);
  Expect.isFalse(const T.eq(1.5, null).value);
  Expect.isFalse(const T.eq("", null).value);
  Expect.isFalse(const T.eq(false, null).value);
  Expect.isFalse(const T.eq(c, null).value);
  Expect.isFalse(const T.eq(d, null).value);

  // Otherwise not allowed.
  const T.eq(d, d); //# 01: compile-time error
  const T.eq(d, 1); //# 02: compile-time error
  const T.eq(d, ""); //# 03: compile-time error
  const T.eq(d, c); //# 04: compile-time error
}

class T {
  final Object value;
  const T.eq(Object? o1, Object? o2) : value = o1 == o2;
}

/// Class that does not override operator==.
class C {
  const C();
}

/// Class that overrides operator==.
class D {
  const D();
  bool operator ==(Object other) => identical(this, other);
}

enum E { value1, value2 }
