// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--reify-generic-functions --optimization-counter-threshold=10 --no-use-osr --no-background-compilation

library generic_no_such_method_dispatcher_test_simple;

import "package:expect/expect.dart";

// A simple test that noSuchMethod dispatching works correctly with generic
// functions. We will remove this once the more complex version of this test
// 'generic_no_such_method_dispatcher_test' can be compiled by Fasta.

class A {}

class B extends A {
  foo() => super.foo<int>();
}

test(fn) {
  try {
    fn();
  } catch (e) {
    Expect.isTrue(e.toString().contains("foo<int>"));
  }
}

main() {
  test(() => (new B()).foo()); // missing generic super call
  test(() => foo<int>()); // missing generic static call
  test(() => (new A()).foo<int>()); // missing generic method call
}
