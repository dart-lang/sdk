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

// Don't allow unlimited recursion to overflow the stack.
var x7Depth = 0;
int x7 = (++x7Depth > 10) ? x7Depth : x7 + 1;

foo() {
  throw "interrupt initialization";
}

foo2() {
  x2 = 499;
  throw "interrupt initialization";
}

// Don't allow unlimited recursion to overflow the stack.
var foo3Depth = 0;
foo3() => (++foo3Depth > 10) ? foo3Depth : x3 + 1;

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
  // If an initializer throws, then accessing it again re-evaluates the
  // initializer.
  Expect.throws(() => fib(x), (e) => e == "interrupt initialization");
  Expect.throws(() => fib(x), (e) => e == "interrupt initialization");
  Expect.throws(() => fib(x), (e) => e == "interrupt initialization");

  Expect.throws(() => fib(x2), (e) => e == "interrupt initialization");
  // The store happened before the throw, so is there now.
  Expect.equals(499, x2);

  // This value means that the initializer did fully call itself recursively.
  Expect.equals(21, x3);

  Expect.equals(499, x4);

  Expect.equals(null, x5);

  Expect.equals(499, x6);

  // This value means that the initializer did fully call itself recursively.
  Expect.equals(21, x7);
}
