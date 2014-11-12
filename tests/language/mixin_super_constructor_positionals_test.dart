// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Base {
  int i, j;
  Base.ctor(int this.i,
            [                  /// 01: compile-time error
            int this.j
            ]                  /// 01: continued
           );
}

abstract class M {
  get i;
  get j;
  int k = 42;
  foo() => i + j;
}

class C extends Base with M {
  int l = 131;
  C.foo() : super.ctor(1, 13);
  C.bar() : super.ctor(1);     /// 01: continued
}

main() {
  C c1 = new C.foo();
  Expect.equals(1, c1.i);
  Expect.equals(13, c1.j);
  Expect.equals(14, c1.foo());
  Expect.equals(42, c1.k);
  Expect.equals(131, c1.l);
  C c2 = new C.bar();          /// 01: continued
}
