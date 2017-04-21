// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test deoptimization from within an inlined function.

import "package:expect/expect.dart";

class A {
  deopt_here() => 1;
}

class B {
  deopt_here() => 2;
}

var obj = new A();

bar(x) {
  x = 42;
  obj.deopt_here();
  return x;
}

foo(x) {
  x = bar(x);
  return x;
}

main() {
  Expect.equals(42, foo(1));
  for (var i = 0; i < 2000; i++) foo(7);
  Expect.equals(42, foo(2));
  obj = new B();
  Expect.equals(42, foo(3)); // <-- deoptimization via foo/bar/obj.deopt_here
}
