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


class C {
  C(this.x, this.y);
  final x;
  final y;
}

test_deopt(a, b) {
  var c = new C(a, b);
  return c.x + c.y;
}


create_error (x) {
  return x as int;
}

check_stacktrace(e) {
  var s = e.stackTrace;
  if (identical(s, null)) throw "FAIL";
  // s should never be null.
  return "OK";
}

test_stacktrace() {
  try {
    create_error("bar");
  } catch (e) {
    Expect.equals("OK", check_stacktrace(e));
    for (var i=0; i<20; i++) { check_stacktrace(e); }
    Expect.equals("OK", check_stacktrace(e));
  }
}


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

  // Test guarded fields with allocation sinking and deoptimization.
  Expect.equals(43, test_deopt(42, 1));
  for (var i = 0; i < 20; i++) { test_deopt(42, 1); }
  Expect.equals(43, test_deopt(42, 1));
  Expect.equals("aaabbb", test_deopt("aaa", "bbb"));

  // Regression test for fields initialized in native code (Error._stackTrace).
  test_stacktrace();
}
