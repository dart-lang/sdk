// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Base {
  int i, j;
  Base.ctor(int i, this.j) : this.i = i + 7;
}

abstract class M {
  int get i;
  int get j;
  int k = 42;
  foo() => i + j;
}

class C extends Base with M {
  int l = 131;
  C() : super.ctor(1, 13);
}

main() {
  C c = new C();
  Expect.equals(8, c.i);
  Expect.equals(13, c.j);
  Expect.equals(42, c.k);
  Expect.equals(131, c.l);
  Expect.equals(21, c.foo());
}
