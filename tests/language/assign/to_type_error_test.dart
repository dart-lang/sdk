// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify that an attempt to assign to a class, enum, typedef, or type
// parameter produces a compile error.

class C<T> {
  f() {
    T = Null;
    // [error column 5, length 1]
    // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_TYPE
    // [cfe] Can't assign to a type literal.
  }
}

class D {}

enum E { e0 }

typedef void F();

main() {
  new C<D>().f();
  D = Null;
  // [error column 3, length 1]
  // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_TYPE
  // [cfe] Can't assign to a type literal.
  E = Null;
  // [error column 3, length 1]
  // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_TYPE
  // [cfe] Can't assign to a type literal.
  F = Null;
  // [error column 3, length 1]
  // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_TYPE
  // [cfe] Can't assign to a type literal.
}
