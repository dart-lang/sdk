// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The body of a primary constructor does not have access to declaring
// parameters, initializing formals, or super parameters.

// SharedOptions=--enable-experiment=primary-constructors

int k = 42;

class A {
  final int i;
  A(int j) : i = j * k;
}

class Super(super.j) extends A {
  this {
    print(j);
    //    ^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_IDENTIFIER
    // [cfe] The getter 'j' isn't defined for the type 'Super'.
  }
}

class InitializingFormal(this.x) {
  final int x;
  this {
    print(x++); // Accessing instance variable `x`
    //    ^
    // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL
    // [cfe] The setter 'x' isn't defined for the type 'InitializingFormal'.
  }
}

class Declaring(final int x) {
  this {
    print(x++); // Accessing instance variable `x`
    //    ^
    // [analyzer] COMPILE_TIME_ERROR.ASSIGNMENT_TO_FINAL
    // [cfe] The setter 'x' isn't defined for the type 'Declaring'.
  }
}
