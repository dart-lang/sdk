// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=3.2

// This exercises unsound code in version <= 3.2.

import 'package:expect/expect.dart';

sealed class S {}

class A extends S {}

class B extends S {}

class C extends S {}

class X extends A {}

class Y extends B {}

class Z implements A, B {}

int unsound(S s) => switch (s) {
      X() as A => 0,
      Y() as B => 1,
    };

int? sound(S s) => switch (s) {
      X() as A => 0,
      Y() as B => 1,
      _ => null,
      //^^
      // [analyzer] STATIC_WARNING.UNREACHABLE_SWITCH_CASE
    };

main() {
  Expect.equals(sound(X()), unsound(X()));
  Expect.throws(() => unsound(Z()));
}
