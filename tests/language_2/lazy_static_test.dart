// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

final x = foo();
final y = y2(y3);
final y2 = incrementCreator();
final y3 = fib(5);

foo() => 499;

incrementCreator() => (x) => x + 1;
fib(x) {
  if (x < 2) return x;
  return fib(x - 1) + fib(x - 2);
}

var count = 0;
sideEffect() => count++;

final t = sideEffect();
var t2 = sideEffect();

class A {
  static final a = toto();
  static final b = b2(b3);
  static final b2 = decrementCreator();
  static final b3 = fact(5);

  static toto() => 666;

  static decrementCreator() => (x) => x - 1;
  static fact(x) {
    if (x <= 1) return x;
    return x * fact(x - 1);
  }
}

main() {
  Expect.equals(499, x);
  Expect.equals(6, y);
  Expect.equals(666, A.a);
  Expect.equals(119, A.b);
  Expect.equals(0, t);
  t2 = 499;
  Expect.equals(499, t2);
  Expect.equals(1, count);
}
