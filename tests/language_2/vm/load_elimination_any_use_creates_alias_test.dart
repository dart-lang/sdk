// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test correctness of side effects tracking used by load to load forwarding.

// VMOptions=--no-use-osr --optimization-counter-threshold=10 --enable-inlining-annotations --no-background-compilation

import "package:expect/expect.dart";

const alwaysInline = "AlwaysInline";
const noInline = "NeverInline";

B G;

@noInline
modify() {
  G.bval = 123;
}

class B {
  @alwaysInline
  poly() {
    G = this;
    modify();
    return bval;
  }

  var bval = -1;
}

class C {
  poly() => null;
}

@alwaysInline
foo(obj) => obj.poly();

@noInline
test() {
  var b = new B();

  foo(b);
  return b.bval;
}

main() {
  foo(new C());
  foo(new B());
  for (var i = 0; i < 100; i++) test();
  Expect.equals(123, test());
}
