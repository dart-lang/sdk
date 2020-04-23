// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program for constructors and initializers.

import "package:expect/expect.dart";

// Super initializer and super constructor body are executed in with the same
// bindings.

String trace = "";

int E(int i) {
  trace = "$trace$i-";
  return i;
}

class A {
  // f closes-over arg.  arg needs to be preserved while b2 is initialized.
  A(arg)
      : a = E(arg += 1),
        f = (() => E(arg += 10)) {
    // b2 should be initialized between the above initializers and the following
    // statements.
    var r1 = f();
    E(arg += 100); // If this is the same arg as closed by f, ...
    var r2 = f(); //  .. the effect of +=100 will be seen here.
  }
  final a;
  final f;
}

class B extends A {
  // Initializers in order: b1, super, b2.
  B(x, y)
      : b1 = E(x++),
        b2 = E(y++),
        super(1000) {
    // Implicit super call to A's body happens here.
    E(x);
    E(y);
    f();
  }
  var b1;
  var b2;
}

class C extends B {
  C() : super(10, 20);
}

main() {
  var c = new C();
  Expect.equals("10-20-1001-1011-1111-1121-11-21-1131-", trace);
}
