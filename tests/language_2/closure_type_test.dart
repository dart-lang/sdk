// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Dart test for a closure result type test that cannot be eliminated at compile
// time.

import "package:expect/expect.dart";

void test(A func(String value), String value) {
  Expect.throws(() {
      B x = func(value);
  }, (e) => e is TypeError);
}


class A {
}

class B extends A {
}

class C {
  static A a(String x) => new A();
}

A aclosure(String x) => C.a(x);
A bclosure() => new A(); 

main() {
  test(aclosure, "foo");
  test((bar) => bclosure(), "baz");
} 
