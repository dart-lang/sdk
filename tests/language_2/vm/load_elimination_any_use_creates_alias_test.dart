// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test correctness of side effects tracking used by load to load forwarding.

// VMOptions=--no-use-osr --optimization-counter-threshold=10 --no-background-compilation

import "package:expect/expect.dart";

B G;

@pragma('vm:never-inline')
modify() {
  G.bval = 123;
}

class B {
  @pragma('vm:prefer-inline')
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

@pragma('vm:prefer-inline')
foo(obj) => obj.poly();

@pragma('vm:never-inline')
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
