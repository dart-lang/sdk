// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Base {
  var i, j;
  Base.ctor1(int i, this.j) : this.i = i + 7;
  Base.ctor2(int i, this.j) : this.i = i + 8;
}

abstract class M {
  get i;
  get j;
  int k = 42;
  foo() => i + j;
}

class C extends Base with M {
  int l = 131;
  C.ctor1() : super.ctor1(1, 13);
  C.ctor2() : super.ctor2(1, 13);
}

main() {
  C c1 = new C.ctor1();
  Expect.equals(8, c1.i);
  Expect.equals(13, c1.j);
  Expect.equals(42, c1.k);
  Expect.equals(131, c1.l);
  Expect.equals(21, c1.foo());
  C c2 = new C.ctor2();
  Expect.equals(9, c2.i);
  Expect.equals(13, c2.j);
  Expect.equals(42, c2.k);
  Expect.equals(131, c2.l);
  Expect.equals(22, c2.foo());
}
