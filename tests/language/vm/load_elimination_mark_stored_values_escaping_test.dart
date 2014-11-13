// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test correctness of side effects tracking used by load to load forwarding.

// VMOptions=--no-use-osr --optimization-counter-threshold=10 --enable-inlining-annotations

// Tests correct handling of redefinitions in aliasing computation.

import "package:expect/expect.dart";

const alwaysInline = "AlwaysInline";
const noInline = "NeverInline";

B G;

class A {
  int val = -1;

  @alwaysInline
  poly(p) {
    p.aa = this;
  }
}


@noInline
modify() {
  G.aa.val = 123;
}

class B {
 A aa;

 @alwaysInline
 poly(p) {
   G = this;
   foo2(p, this);
   modify();
 }
}

@alwaysInline
foo(obj, p) => obj.poly(p);

@alwaysInline
foo2(obj, p) => obj.poly(p);

@noInline
testfunc() {
  var a = new A();
  var b = new B();
  foo(b, a);
  return a.val;
}

main() {
  foo(new B(), new A());
  foo(new A(), new B());
  foo2(new B(), new A());
  foo2(new A(), new B());
  for (var i = 0; i < 100; i++) testfunc();
  Expect.equals(123, testfunc());
}
