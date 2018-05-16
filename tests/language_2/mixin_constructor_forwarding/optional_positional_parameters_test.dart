// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

abstract class Mixin {
  int get x;
  int get m => x;
}

class Base {
  final int x;
  Base.c1(this.x);
  Base.c2([this.x = 37]);
  Base.c3(int x) : this.c1(x);
  Base.c4([int x = 37]) : this.c1(x);
  Base.c5(int x) : this.c2(x);
  Base.c6([int x = 37]) : this.c2(x);
  factory Base() = Base.c2;
}

class Application = Base with Mixin;

class Application2 extends Base with Mixin {}

main() {
  Expect.equals(42, new Application.c1(42).m);
  Expect.equals(42, new Application.c2(42).m);
  Expect.equals(42, new Application.c3(42).m);
  Expect.equals(42, new Application.c4(42).m);
  Expect.equals(42, new Application.c5(42).m);
  Expect.equals(42, new Application.c6(42).m);
  Expect.equals(37, new Application.c2().m);
  Expect.equals(37, new Application.c4().m);
  Expect.equals(37, new Application.c6().m);

  Expect.equals(42, new Application2.c1(42).m);
  Expect.equals(42, new Application2.c2(42).m);
  Expect.equals(42, new Application2.c3(42).m);
  Expect.equals(42, new Application2.c4(42).m);
  Expect.equals(42, new Application2.c5(42).m);
  Expect.equals(42, new Application2.c6(42).m);
  Expect.equals(37, new Application2.c2().m);
  Expect.equals(37, new Application2.c4().m);
  Expect.equals(37, new Application2.c6().m);

  // Only insert forwarders for generative constructors.
  new Application(); //# 01: compile-time error
  new Application2(); //# 02: compile-time error
}
