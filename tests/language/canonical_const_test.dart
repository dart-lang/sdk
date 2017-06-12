// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Check that initializers of static const fields are compile time constants.

import "package:expect/expect.dart";

class CanonicalConstTest {
  static const A = const C1();
  static const B = const C2();

  static testMain() {
    Expect.identical(null, null);
    Expect.isFalse(identical(null, 0));
    Expect.identical(1, 1);
    Expect.isFalse(identical(1, 2));
    Expect.identical(true, true);
    Expect.identical("so", "so");
    Expect.identical(const Object(), const Object());
    Expect.isFalse(identical(const Object(), const C1()));
    Expect.identical(const C1(), const C1());
    Expect.identical(A, const C1());
    Expect.isFalse(identical(const C1(), const C2()));
    Expect.identical(B, const C2());
    // TODO(johnlenz): these two values don't currently have the same type
    // Expect.identical(const [1,2], const List[1,2]);
    Expect.isFalse(identical(const [2, 1], const [1, 2]));
    Expect.identical(const <int>[1, 2], const <int>[1, 2]);
    Expect.identical(const <Object>[1, 2], const <Object>[1, 2]);
    Expect.isFalse(identical(const <int>[1, 2], const <double>[1.0, 2.0]));
    Expect.identical(const {"a": 1, "b": 2}, const {"a": 1, "b": 2});
    Expect.isFalse(identical(const {"a": 1, "b": 2}, const {"a": 2, "b": 2}));
  }
}

class C1 {
  const C1();
}

class C2 extends C1 {
  const C2() : super();
}

main() {
  CanonicalConstTest.testMain();
}
