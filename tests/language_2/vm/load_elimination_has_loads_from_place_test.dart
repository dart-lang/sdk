// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test correctness of side effects tracking used by load to load forwarding.

// VMOptions=--optimization-counter-threshold=10 --no-use-osr --enable-inlining-annotations --no-background-compilation

// Tests correct handling of redefinitions in aliasing computation.

import "package:expect/expect.dart";

const alwaysInline = "AlwaysInline";
const noInline = "NeverInline";

var H = true;

class A {
  B bb;

  @alwaysInline
  poly(p) {
    if (H) {
      bb = p;
    }
    B t = bb;
    t.bval = 123;
    return t.bval;
  }
}

class B {
  int bval = -1;

  @alwaysInline
  poly(p) {
    return bval;
  }
}

@alwaysInline
foo(obj, p) => obj.poly(p);

@noInline
test() {
  A a = new A();
  B b = new B();
  foo(a, b);
  return b.bval;
}

main() {
  // Prime foo with polymorphic type feedback.
  foo(new B(), new A());
  foo(new A(), new B());

  for (var i = 0; i < 100; i++) test();
  Expect.equals(123, test());
}
