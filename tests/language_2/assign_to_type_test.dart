// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that an attempt to assign to a class, enum, typedef, or type
// parameter produces a compile error.

class C<T> {
  f() {
    T = null; //# 01: compile-time error
  }
}

class D {}

enum E { e0 }

typedef void F();

main() {
  new C<D>().f();
  D = null; //# 02: compile-time error
  E = null; //# 03: compile-time error
  F = null; //# 04: compile-time error
}
