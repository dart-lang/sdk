// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test various invalid mixin applications where the supertype doesn't
// implement the super-interfaces.

abstract class UnaryNum {
  num foo(num x) => x;
}

abstract class UnaryInt {
  num foo(int x) => x;
}

mixin M1 on UnaryNum {}

class _ = Object with M1; //# 01: compile-time error
class _ = Null with M1; //# 02: compile-time error
class _ = UnaryInt with M1;  //# 03: compile-time error

mixin M2 on UnaryNum, UnaryInt {}

class _ = UnaryInt with M2;  //# 04: compile-time error
class _ = UnaryNum with M2;  //# 05: compile-time error

main() {
  // M1 and M2 are valid types.
  Expect.isNotType<M1>(null);
  Expect.isNotType<M2>(null);
}
