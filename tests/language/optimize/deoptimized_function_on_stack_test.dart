// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10

import "package:expect/expect.dart";

// This is a test for deoptimization infrastructure and to reproduce the
// failure from bug 5442338.

main() {
  warmup();
  runTest();
}

// Create a situation where method 'call' is optimized for using class A
// when calling foo.
warmup() {
  List a = [new A(), new A(), new A(), new A()];
  var res = 0;
  for (int i = 0; i < 20; i++) {
    res = call(a, 0);
  }
  Expect.equals(10, res);
}

// Create a situation where several optimized frames of 'call' are on stack
// when deoptimization occurs because B.foo is called. After the first
// deoptimization, several optimized frames of 'call' are still on stack and
// some of them will be deoptimized.
runTest() {
  List a = [new A(), new A(), new B(), new A(), new B(), new B()];
  var res = call(a, 0);
  Expect.equals(35, res);
}

// This method will be optimized for using class A when calling 'foo' and
// later will be deoptimized because B.foo is required.
call(List a, int n) {
  if (n < a.length) {
    var sum = call(a, n + 1);
    for (int i = n; i < a.length; i++) {
      sum += a[i].foo();
    }
    return sum;
  }
  return 0;
}

class A {
  foo() {
    return 1;
  }
}

class B {
  foo() {
    return 2;
  }
}
