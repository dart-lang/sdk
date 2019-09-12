// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

abstract class Mixin {
  // Declares an instance variable.
  // Declaration would be valid in a "const class", but mixin application
  // won't get const constructor forwarders.
  final int y = 0;

  int get x;
  int get m => x;
}

class Base {
  final int x;

  // Non-const constructors.
  Base.c1(this.x);
  Base.c2([this.x = 37]);
  Base.c3({this.x = 37});

  // Non-forwarding generative const constructors.
  const Base.c4(this.x);
  const Base.c5([this.x = 37]);
  const Base.c6({this.x = 37});

  // Forwarding generative const constructors.
  const Base.c7(int x) : this.c4(x);
  const Base.c8([int x = 87]) : this.c4(x);
  const Base.c9({int x = 87}) : this.c4(x);
  const Base.c10(int x) : this.c5(x);
  const Base.c11([int x = 87]) : this.c5(x);
  const Base.c12({int x = 87}) : this.c5(x);
  const Base.c13(int x) : this.c6(x: x);
  const Base.c14([int x = 87]) : this.c6(x: x);
  const Base.c15({int x = 87}) : this.c6(x: x);

  // Non-generative constructor.
  const factory Base() = Base.c5;
}

class Application = Base with Mixin;

main() {
  Expect.equals(42, new Application.c1(42).m);
  Expect.equals(42, new Application.c2(42).m);
  Expect.equals(42, new Application.c3(x: 42).m);
  Expect.equals(42, new Application.c4(42).m);
  Expect.equals(42, new Application.c5(42).m);
  Expect.equals(42, new Application.c6(x: 42).m);
  Expect.equals(42, new Application.c7(42).m);
  Expect.equals(42, new Application.c8(42).m);
  Expect.equals(42, new Application.c9(x: 42).m);
  Expect.equals(42, new Application.c10(42).m);
  Expect.equals(42, new Application.c11(42).m);
  Expect.equals(42, new Application.c12(x: 42).m);
  Expect.equals(42, new Application.c13(42).m);
  Expect.equals(42, new Application.c14(42).m);
  Expect.equals(42, new Application.c15(x: 42).m);

  Expect.equals(37, new Application.c2().m); //# issue38304: ok
  Expect.equals(37, new Application.c3().m);
  Expect.equals(37, new Application.c5().m); //# issue38304: continued
  Expect.equals(37, new Application.c6().m);
  Expect.equals(87, new Application.c8().m); //# issue38304: continued
  Expect.equals(87, new Application.c9().m);
  Expect.equals(87, new Application.c11().m); //# issue38304: continued
  Expect.equals(87, new Application.c12().m);
  Expect.equals(87, new Application.c14().m); //# issue38304: continued
  Expect.equals(87, new Application.c15().m);

  // Don't make constructors const if mixin declares instance variable.
  const Application.c4(42); //# 00: compile-time error
  const Application.c5(42); //# 01: compile-time error
  const Application.c6(x: 42); //# 02: compile-time error
  const Application.c7(42); //# 03: compile-time error
  const Application.c8(42); //# 04: compile-time error
  const Application.c9(x: 42); //# 05: compile-time error
  const Application.c10(42); //# 06: compile-time error
  const Application.c11(42); //# 07: compile-time error
  const Application.c12(x: 42); //# 08: compile-time error
  const Application.c13(42); //# 09: compile-time error
  const Application.c14(42); //# 10: compile-time error
  const Application.c15(x: 42); //# 11: compile-time error

  // Only insert forwarders for generative constructors.
  new Application(); //# 12: compile-time error
}
