// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that dart2js's backend type inference handles super calls.

import "package:expect/expect.dart";

class A {
  foo(a) => a + 42;
}

class B extends A {
  bar() {
    super.foo(null);
  }
}

var a = [new A()];

main() {
  analyzeFirst();
  analyzeSecond();
}

analyzeFirst() {
  Expect.equals(84, a[0].foo(42));
}

analyzeSecond() {
  Expect.throwsNoSuchMethodError(() => new B().bar());
}
