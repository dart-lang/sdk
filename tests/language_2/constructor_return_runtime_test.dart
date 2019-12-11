// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Dart spec 0.03, section 11.10 - generative constructors can only have return
// statements in the form 'return;'.
class A {
  int x;
  A(this.x) {
    return;
  }
  A.test1(this.x) {

  }
  A.test2(this.x) {

  }
  int foo(int y) => x + y;
}

class B {

}

class C {
  int value;

}

class D {
  int value;

}

main() {
  Expect.equals((new A(1)).foo(10), 11);
  Expect.equals((new A.test1(1)).foo(10), 11);
  Expect.equals((new A.test2(1)).foo(10), 11);
  new B();
  new C();
  new D();
}
