// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests that `void` accepts any value and won't throw on non-`null` values.
// The test is set up in a way that `--trust-type-annotations` and type
// propagation must not assume that `void` is `null` either.

import 'package:expect/expect.dart';

class A {
  void foo() {
    return bar();
  }

  void bar() {}
}

class B extends A {
  int bar() => 42;
}

// Makes the typing cleaner: the return type here is `dynamic` and we are
// guaranteed that there won't be any warnings.
// Dart2js can still infer the type by itself.
@NoInline()
callFoo(A a) => a.foo();

main() {
  var a = new A();
  var b = new B();
  // The following line is not throwing, even though `a.foo()` (inside
  // `callFoo`) is supposedly `void`.
  callFoo(b).abs();
  Expect.isNull(callFoo(a));
  Expect.equals(42, callFoo(b));
}
