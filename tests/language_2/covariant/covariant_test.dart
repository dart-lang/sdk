// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that `covariant` can be parsed (and ignored) by
// dart2js and the VM.
// This test only checks for non-strong mode behavior.
//
// Generally, `covariant` should be ignored, when it is used in the right
// places.

import 'package:expect/expect.dart';

// Top level field may not have a covariant.
// Would be considered a minor (acceptable) bug, if it was accepted here too.
covariant // //# 00: syntax error
int x0;

covariant int covariant; // //# 00b: syntax error

int covariant; // //# 00c: ok

// Getters may never have `covariant`. (Neither on the top-level nor as members)
covariant // //# 01: syntax error
int get x1 => 499;

// Top level setters may not have a covariant.
// Would be considered a minor (acceptable) bug, if it was accepted here too.
void set x2(
    covariant //# 02: compile-time error
    int val) {}

// Same as above, but with `covariant` in different positions.
// The `covariant` is just wrong there.

int
covariant // //# 03: syntax error
    x3;

int
covariant // //# 04: syntax error
    get x4 => 499;

void set x5(
    int
    covariant //# 05: syntax error
        val) {}

// Same without types.

// Since `covariant` is a built-in identifier, it is not allowed here.
covariant x6; // //# 06: syntax error

covariant covariant; // //# 06b: syntax error

// Getters may never have `covariant`.
covariant // //# 07: syntax error
get x7 => 499;

// Top level setters may not have a covariant.
// Would be considered a minor (acceptable) bug, if it was accepted here too.
void set x8(
    covariant //# 08: compile-time error
    val) {}

// If there is no type, then `covariant` is simply the parameter name:
void set x9(covariant) {}

// Covariant won't work on return types.
covariant // //# 10: syntax error
int f10() => 499;

// Covariant won't work as a return type.
covariant // //# 11: syntax error
f11() => 499;

// Covariant should not work on top-level methods.
// It's a minor (acceptable) bug to not error out here.
int f12(
    covariant //# 12: compile-time error
        int x) =>
    499;

// `Covariant` must be in front of the types.
int f13(
        int
    covariant //# 13: syntax error
            x) =>
    499;

// Covariant should not work on top-level methods.
// It's a minor (acceptable) bug to not error out here.
int f14(
    covariant //# 14: compile-time error
        final x) =>
    499;

// `Covariant` must be in front of modifiers.
int f15(
        final
    covariant //# 15: syntax error
            x) =>
    499;

// Covariant should not work on top-level methods.
// It's a minor (acceptable) bug to not error out here.
int f16(
    covariant //# 16: compile-time error
        final int x) =>
    499;

// `Covariant` must be in front of modifiers.
int f17(
        final
    covariant //# 17: syntax error
            int
            x) =>
    499;

// On its own, `covariant` is just a parameter name.
int f18(covariant) => covariant;

covariant; // //# 19: syntax error

// All of the above as statics in a class.
class A {
  // Static fields may not have a covariant.
  // Would be considered a minor (acceptable) bug, if it was accepted here too.
  static
  covariant // //# 20: syntax error
      int x20;

  static covariant int covariant; // //# 20b: syntax error

  static int covariant; // //# 20c: ok

  // Getters may never have `covariant`.
  static
  covariant // //# 21: syntax error
      int get x21 => 499;

  // Getters may never have `covariant`.
  covariant // //# 21b: syntax error
  static int get x21b => 499;

  // Static setters may not have a covariant.
  // Would be considered a minor (acceptable) bug, if it was accepted here too.
  static void set x22(
      covariant //# 22: compile-time error
      int val) {}

  // Same as above, but with `covariant` in different positions.
  // The `covariant` is just wrong there.

  static int
  covariant // //# 23: syntax error
      x23;

  static int
  covariant // //# 24: syntax error
      get x24 => 499;

  static void set x25(
      int
    covariant //# 25: syntax error
          val) {}

  // Since `covariant` is a built-in identifier, it is not allowed here.
  static covariant x26; //# 26: syntax error
  static covariant covariant; //# 26b: syntax error

  // Getters may never have `covariant`.
  static
  covariant // //# 27: syntax error
      get x27 => 499;

  covariant // //# 27b: syntax error
  static get x27b => 499;

  // Static setters may not have a covariant.
  // Would be considered a minor (acceptable) bug, if it was accepted here too.
  static void set x28(
      covariant //# 28: compile-time error
      val) {}

  // If there is no type, then `covariant` is simply the parameter name:
  static void set x29(covariant) {}

  // Covariant won't work on return types.
  static
  covariant // //# 30: syntax error
      int f30() => 499;

  covariant // //# 30b: syntax error
  static int f30b() => 499;

  // Covariant won't work as a return type.
  static
  covariant // //# 31: syntax error
      f31() => 499;

  covariant // //# 31b: syntax error
  static f31b() => 499;

  // Covariant should not work on static methods.
  // It's a minor (acceptable) bug to not error out here.
  static int f32(
      covariant //# 32: compile-time error
          int x) =>
      499;

  // `Covariant` must be in front of the types.
  static int f33(
          int
      covariant //# 33: syntax error
              x) =>
      499;

  // Covariant should not work on top-level methods.
  // It's a minor (acceptable) bug to not error out here.
  static int f34(
      covariant //# 34: compile-time error
          final x) =>
      499;

  // `Covariant` must be in front of modifiers.
  static int f35(
          final
      covariant //# 35: syntax error
              x) =>
      499;

  // Covariant should not work on top-level methods.
  // It's a minor (acceptable) bug to not error out here.
  static int f36(
      covariant //# 36: compile-time error
          final int x) =>
      499;

  // `Covariant` must be in front of modifiers.
  static int f37(
          final
      covariant //# 37: syntax error
              int
              x) =>
      499;

  // `Covariant` on its own is just a parameter name.
  static int f38(covariant) => covariant;

  static covariant; // //# 39: syntax error

}

// All of the above as instance members in a class.
class B {
  covariant // //# 40: ok
  int x40;

  covariant int covariant; // //# 40b: ok

  int covariant; //           //# 40c: ok

  // Getters may never have `covariant`.
  covariant // //# 41: syntax error
  int get x41 => 499;

  void set x42(
      covariant // //# 42: ok
      int val) {}

  // `covariant` in the wrong position.
  int
  covariant // //# 43: syntax error
      x43;

  // `covariant` in the wrong position.
  int
  covariant // //# 44: syntax error
      get x44 => 499;

  void set x45(
      int
    covariant //# 45: syntax error
          val) {}

  // Since `covariant` is a built-in identifier, it is not allowed here.
  covariant x46; //# 46: syntax error
  covariant covariant; //# 46b: syntax error

  // Getters may never have `covariant`.
  covariant // //# 47: syntax error
  get x47 => 499;

  void set x48(
      covariant // //# 48: ok
      val) {}

  // If there is no type, then `covariant` is simply the parameter name:
  void set x49(covariant) {}

  // Covariant won't work on return types.
  covariant // //# 50: syntax error
  int f50() => 499;

  // Covariant won't work as a return type.
  covariant // //# 51: syntax error
  f51() => 499;

  int f52(
      covariant // //# 52: ok
          int x) =>
      499;

  // `Covariant` must be in front of the types.
  int f53(
          int
      covariant //# 53: syntax error
              x) =>
      499;

  int f54(
      covariant // //# 54: ok
          final x) =>
      499;

  // `Covariant` must be in front of modifiers.
  int f55(
          final
      covariant //# 55: syntax error
              x) =>
      499;

  int f56(
      covariant // //# 56: ok
          final int x) =>
      499;

  // `Covariant` must be in front of modifiers.
  int f57(
          final
      covariant //# 57: syntax error
              int
              x) =>
      499;

  // `Covariant` on its own is just a parameter name.
  int f58(covariant) => covariant;

  covariant; // //# 59: syntax error
}

void use(x) {}

main() {
  x0 = 0;
  covariant = 0; // //# 00b: continued
  covariant = 0; // //# 00c: continued
  use(x1);
  x2 = 499;
  use(x3);
  use(x4);
  x5 = 42;
  x6 = 0; //# 06: continued
  covariant = 0; //# 06b: continued
  use(x7);
  x8 = 11;
  x9 = 12;
  use(f10());
  use(f11());
  use(f12(2));
  use(f13(3));
  use(f14(3));
  use(f15(3));
  use(f16(3));
  use(f17(3));
  Expect.equals(123, f18(123));
  use(covariant); // //# 19: continued

  A.x20 = 0;
  A.covariant = 0; // //# 20b: continued
  A.covariant = 0; // //# 20c: continued
  use(A.x21);
  use(A.x21b);
  A.x22 = 499;
  use(A.x23);
  use(A.x24);
  A.x25 = 42;
  A.x26 = 0; //# 26: continued
  A.covariant = 0; //# 26b: continued
  use(A.x27);
  use(A.x27b);
  A.x28 = 11;
  A.x29 = 12;
  use(A.f30());
  use(A.f31());
  use(A.f31b());
  use(A.f32(2));
  use(A.f33(3));
  use(A.f34(3));
  use(A.f35(3));
  use(A.f36(3));
  use(A.f37(3));
  Expect.equals(1234, A.f38(1234));
  use(A.covariant); // //# 39: continued

  var b = new B();
  b.x40 = 0;
  b.covariant = 0; // //# 40b: continued
  b.covariant = 0; // //# 40c: continued
  use(b.x41);
  b.x42 = 499;
  use(b.x43);
  use(b.x44);
  b.x45 = 42;
  b.x46 = 0; //# 46: continued
  b.covariant = 0; //# 46b: continued
  use(b.x47);
  b.x48 = 11;
  b.x49 = 12;
  use(b.f50());
  use(b.f51());
  use(b.f52(2));
  use(b.f53(2));
  use(b.f54(3));
  use(b.f55(3));
  use(b.f56(3));
  use(b.f57(3));
  Expect.equals(12345, b.f58(12345));
  use(B.covariant); // //# 59: continued
}
