// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests of loops.

import 'package:expect/expect.dart';

fact(n) {
  var f = 1;
  while (n > 0) {
    f *= n;
    --n;
  }
  return f;
}

fib(n) {
  if (n == 0) return 0;
  var previous = 0, current = 1;
  while (n > 1) {
    var temp = current;
    current += previous;
    previous = temp;
    --n;
  }
  return current;
}

mkTrue() => true;
mkFalse() => false;

check(b) {
  Expect.isTrue(b);
  return b;
}

test0() {
  while (mkTrue()) {
    Expect.isTrue(true);
    return;
  }
  Expect.isTrue(false);
}

test1() {
  while (mkFalse()) {
    Expect.isTrue(false);
  }
  Expect.isTrue(true);
}

test2() {
  do {
    Expect.isTrue(true);
  } while (mkFalse());
  Expect.isTrue(true);
}

test3() {
  do {
    Expect.isTrue(true);
    return;
  } while (check(false));
  Expect.isTrue(false);
}

main() {
  Expect.isTrue(fact(0) == 1);
  Expect.isTrue(fact(1) == 1);
  Expect.isTrue(fact(5) == 120);
  Expect
      .isTrue(fact(42) == 1405006117752879898543142606244511569936384000000000);
  Expect.isTrue(fact(3.14159) == 1.0874982674320444);

  Expect.isTrue(fib(0) == 0);
  Expect.isTrue(fib(1) == 1);
  Expect.isTrue(fib(2) == 1);
  Expect.isTrue(fib(3) == 2);
  Expect.isTrue(fib(4) == 3);
  Expect.isTrue(fib(5) == 5);
  Expect.isTrue(fib(6) == 8);
  Expect.isTrue(fib(7) == 13);
  Expect.isTrue(fib(42) == 267914296);
  Expect.isTrue(fib(3.14159) == 3);

  test0();
  test1();
  test2();
  test3();
}
