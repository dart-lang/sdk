// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Test correct handling of phis with only environment uses that were inserted
// by store to load forwarding.
// VMOptions=--optimization_counter_threshold=10

import "package:expect/expect.dart";

class A {
  var foo;
}

class B {
  get foo => null;
}

test(obj) => obj.foo == null ? "null" : "other";

main() {
  var a = new A();
  var b = new B();
  // Trigger optimization of test with a polymorphic load.
  // The guarded type of foo is null.
  test(a);
  test(b);
  for (var i = 0; i < 20; ++i) test(a);
  Expect.equals("null", test(a));
  Expect.equals("null", test(b));

  // Store a non-null object into foo to trigger deoptimization of test.
  a.foo = 123;
  Expect.equals("other", test(a));
  Expect.equals("null", test(b));
}
