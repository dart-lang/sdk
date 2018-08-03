// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test for testing implicit super calls with bad arguments or no default
// constructor in super class.

import "package:expect/expect.dart";

class A {
  A(
    this.x // //# 01: compile-time error
      );
  final foo = 499;
}

class B extends A {}

class B2 extends A {
  B2();
  B2.named() : this.x = 499;
  var x;
}

class C {
  C
  .named // //# 02: compile-time error
  ();
  final foo = 499;
}

class D extends C {}

class D2 extends C {
  D2();
  D2.named() : this.x = 499;
  var x;
}

main() {
  Expect.equals(499, new B().foo);
  Expect.equals(499, new B2().foo);
  Expect.equals(499, new B2.named().foo);
  Expect.equals(499, new D().foo);
  Expect.equals(499, new D2().foo);
  Expect.equals(499, new D2.named().foo);
}
