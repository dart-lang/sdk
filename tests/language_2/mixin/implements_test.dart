// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

abstract class I0 {
  foo();
}

abstract class I1 {
  bar();
}

abstract class I2 implements I0, I1 {}

class M {
  foo() => 42;
  bar() => 87;
}

class C0 = Object with M;
class C1 = Object with M implements I0;
class C2 = Object with M implements I1;
class C3 = Object with M implements I0, I1;
class C4 = Object with M implements I1, I0;
class C5 = Object with M implements I2;

main() {
  var c0 = new C0();
  Expect.equals(42, c0.foo());
  Expect.equals(87, c0.bar());
  Expect.isTrue(c0 is M);
  Expect.isFalse(c0 is I0);
  Expect.isFalse(c0 is I1);
  Expect.isFalse(c0 is I2);

  var c1 = new C1();
  Expect.equals(42, c1.foo());
  Expect.equals(87, c1.bar());
  Expect.isTrue(c1 is M);
  Expect.isTrue(c1 is I0);
  Expect.isFalse(c1 is I1);
  Expect.isFalse(c1 is I2);

  var c2 = new C2();
  Expect.equals(42, c2.foo());
  Expect.equals(87, c2.bar());
  Expect.isTrue(c2 is M);
  Expect.isFalse(c2 is I0);
  Expect.isTrue(c2 is I1);
  Expect.isFalse(c1 is I2);

  var c3 = new C3();
  Expect.equals(42, c3.foo());
  Expect.equals(87, c3.bar());
  Expect.isTrue(c3 is M);
  Expect.isTrue(c3 is I0);
  Expect.isTrue(c3 is I1);
  Expect.isFalse(c1 is I2);

  var c4 = new C4();
  Expect.equals(42, c4.foo());
  Expect.equals(87, c4.bar());
  Expect.isTrue(c4 is M);
  Expect.isTrue(c4 is I0);
  Expect.isTrue(c4 is I1);
  Expect.isFalse(c1 is I2);

  var c5 = new C5();
  Expect.equals(42, c5.foo());
  Expect.equals(87, c5.bar());
  Expect.isTrue(c5 is M);
  Expect.isTrue(c5 is I0);
  Expect.isTrue(c5 is I1);
  Expect.isTrue(c5 is I2);
}
