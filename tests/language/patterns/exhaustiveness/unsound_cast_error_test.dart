// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This exercises unsound code in version <= 3.2.

sealed class S {}

class A extends S {}

class B extends S {}

class C extends S {}

class X extends A {}

class Y extends B {}

class Z implements A, B {}

method(S s) => switch (s) {
//             ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_EXHAUSTIVE_SWITCH_EXPRESSION
//                     ^
// [cfe] The type 'S' is not exhaustively matched by the switch cases since it doesn't match 'A()'.
      X() as A => 0,
      Y() as B => 1,
    };

test() {
  method(Z());
}
