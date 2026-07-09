// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// A mixin declaration introduces a static scope.
// Instance members keep seeing this scope when mixed in.

abstract class UnaryNum {
  num foo(num x);
}

mixin M1 on UnaryNum {
  static int counter = 0;
  static int next() => ++counter;
  int count() => foo(next()) as int;
}

class C1 implements UnaryNum {
  static int counter = 87;
  static int next() => 42;
  num foo(num x) => x * 10;
}

class A1 = C1 with M1;

main() {
  Expect.equals(0, M1.counter);
  Expect.equals(1, M1.next());
  Expect.equals(2, M1.next());
  var a = A1();
  Expect.equals(30, a.count());
  Expect.equals(40, a.count());
  Expect.equals(5, M1.next());
}
