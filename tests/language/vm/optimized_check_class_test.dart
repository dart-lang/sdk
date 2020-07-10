// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-use-osr --no-background-compilation

import "package:expect/expect.dart";

// Test dense class-id checks. Regression test for issue 22104.

class A {
  toString() => "an A";
}

class A1 extends A {}

class A2 extends A {}

class A3 extends A {}

class A4 extends A {
  toString() => "ha";
}

class A5 extends A {}

class A6 extends A {}

class A7 extends A {}

class A8 extends A {}

class A9 extends A {}

class A10 extends A {}

class A11 extends A {}

class A12 extends A {}

class A13 extends A {}

class A14 extends A {}

class A15 extends A {}

class A16 extends A {}

class A17 extends A {}

class A18 extends A {}

class A19 extends A {}

class A20 extends A {}

class A21 extends A {}

class A22 extends A {}

class A23 extends A {}

class A24 extends A {}

class A25 extends A {}

class A26 extends A {}

class A27 extends A {}

class A28 extends A {}

class A29 extends A {}

class A30 extends A {}

class A31 extends A {}

class A32 extends A {}

class A33 extends A {}

class A34 extends A {}

class A35 extends A {}

class A36 extends A {}

test_class_check(e) => e.toString();

main() {
  var list = [new A1(), new A2(), new A11(), new A36()];
  for (var i = 0; i < list.length; i++) {
    test_class_check(list[i]);
  }
  for (var i = 0; i < 100; i++) {
    Expect.equals("an A", test_class_check(new A1()));
  }
  Expect.equals("ha", test_class_check(new A4()));
}
