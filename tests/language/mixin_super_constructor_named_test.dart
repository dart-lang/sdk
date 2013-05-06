// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Base {
  int i, j;
  Base.ctor(int this.i, {int this.j: 10});
}

abstract class M {
  get i;
  get j;
  int k = 42;
  foo() => i + j;
}

class C extends Base with M {
  int l = 131;
  C.foo() : super.ctor(1, j: 13);
  C.bar() : super.ctor(1);
}

main() {
  C c1 = new C.foo();
  Expect.equals(1, c1.i);
  Expect.equals(13, c1.j);
  Expect.equals(14, c1.foo());
  Expect.equals(42, c1.k);
  Expect.equals(131, c1.l);
  C c2 = new C.bar();
  Expect.equals(1, c2.i);
  Expect.equals(10, c2.j);
  Expect.equals(11, c2.foo());
  Expect.equals(42, c2.k);
  Expect.equals(131, c2.l);
}
