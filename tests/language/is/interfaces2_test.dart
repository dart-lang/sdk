// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {}

class B extends A {}

class C extends B {}

class D implements C {}

int inscrutable(int x) => (x == 0) ? 0 : (x | inscrutable(x & (x - 1)));

main() {
  var things = [new A(), new B(), new C(), new D()];

  var a = things[inscrutable(0)];
  Expect.isTrue(a is A);
  Expect.isFalse(a is B);
  Expect.isFalse(a is C);
  Expect.isFalse(a is D);

  var b = things[inscrutable(1)];
  Expect.isTrue(b is A);
  Expect.isTrue(b is B);
  Expect.isFalse(b is C);
  Expect.isFalse(b is D);

  var c = things[inscrutable(2)];
  Expect.isTrue(c is A);
  Expect.isTrue(c is B);
  Expect.isTrue(c is C);
  Expect.isFalse(c is D);

  var d = things[inscrutable(3)];
  Expect.isTrue(d is A);
  Expect.isTrue(d is B);
  Expect.isTrue(d is C);
  Expect.isTrue(d is D);
}
