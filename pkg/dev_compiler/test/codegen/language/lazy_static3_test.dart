// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

final x = foo();
var x2 = foo2();
var x3 = foo3();
var x4 = foo4();
var x5 = foo5();
final x6 = foo6();
var x7 = x7 + 1;

foo() { throw "interrupt initialization"; }
foo2() { x2 = 499; throw "interrupt initialization"; }
foo3() => x3 + 1;
foo4() {
  x4 = 498;
  x4 = x4 + 1;
  return x4;
}
foo5() {
  x5 = 498;
  x5 = x5 + 1;
}
foo6() {
  try {
    return x5 + 1;
  } catch (e) {
    return 499;
  }
}

fib(x) {
  if (x is! int) return 0;
  if (x < 2) return x;
  return fib(x - 1) + fib(x - 2);
}

main() {
  Expect.throws(() => fib(x), (e) => e == "interrupt initialization");
  Expect.equals(null, x);

  Expect.throws(() => fib(x2), (e) => e == "interrupt initialization");
  Expect.equals(null, x2);

  Expect.throws(() => fib(x3), (e) => e is CyclicInitializationError);
  Expect.equals(null, x3);

  Expect.equals(499, x4);

  Expect.equals(null, x5);

  Expect.equals(499, x6);

  Expect.throws(() => fib(x7), (e) => e is CyclicInitializationError);
}
