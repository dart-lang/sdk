// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=this-promotion

// The CFE has several lowered representations for expressions involving
// explicit or implicit `this`. In this test we try to exercise as many of those
// lowered representations as we can think of.

class A {
  num get x => 1;
  set x(num value) {}

  void f(num val) {}
}

class B extends ClassTest with M {
  @override
  int get x => 2;
  @override
  set x(covariant int value) {}

  @override
  void f(covariant int val) {}

  void bOnly() {}
}

class ClassTest extends A {
  void testClass() {
    if (this is B) {
      // 1. Simple member write with double value
      x = 1.0;
      //  ^^^
      // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
      // [cfe] A value of type 'double' can't be assigned to a variable of type 'int'.

      this.x = 1.0;
      //       ^^^
      // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
      // [cfe] A value of type 'double' can't be assigned to a variable of type 'int'.

      // 2. Method invocation with double value
      f(1.0);
      //^^^
      // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
      // [cfe] The argument type 'double' can't be assigned to the parameter type 'int'.

      this.f(1.0);
      //     ^^^
      // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
      // [cfe] The argument type 'double' can't be assigned to the parameter type 'int'.
    }

    // 3. Accessing B-only member without promotion
    bOnly();
    // [error column 5, length 5]
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'bOnly' isn't defined for the type 'ClassTest'.

    this.bOnly();
    //   ^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'bOnly' isn't defined for the type 'ClassTest'.
  }
}

mixin M on A {
  void testMixin() {
    if (this is B) {
      // 1. Simple member write with double value
      x = 1.0;
      //  ^^^
      // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
      // [cfe] A value of type 'double' can't be assigned to a variable of type 'int'.

      this.x = 1.0;
      //       ^^^
      // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
      // [cfe] A value of type 'double' can't be assigned to a variable of type 'int'.

      // 2. Method invocation with double value
      f(1.0);
      //^^^
      // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
      // [cfe] The argument type 'double' can't be assigned to the parameter type 'int'.

      this.f(1.0);
      //     ^^^
      // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
      // [cfe] The argument type 'double' can't be assigned to the parameter type 'int'.
    }

    // 3. Accessing B-only member without promotion
    bOnly();
    // [error column 5, length 5]
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'bOnly' isn't defined for the type 'M'.

    this.bOnly();
    //   ^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'bOnly' isn't defined for the type 'M'.
  }
}

extension Ext on A {
  void testExtension() {
    if (this is B) {
      // 1. Simple member write with double value
      x = 1.0;
      //  ^^^
      // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
      // [cfe] A value of type 'double' can't be assigned to a variable of type 'int'.

      this.x = 1.0;
      //       ^^^
      // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
      // [cfe] A value of type 'double' can't be assigned to a variable of type 'int'.

      // 2. Method invocation with double value
      f(1.0);
      //^^^
      // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
      // [cfe] The argument type 'double' can't be assigned to the parameter type 'int'.

      this.f(1.0);
      //     ^^^
      // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
      // [cfe] The argument type 'double' can't be assigned to the parameter type 'int'.
    }

    // 3. Accessing B-only member without promotion
    bOnly();
    // [error column 5, length 5]
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'bOnly' isn't defined for the type 'A'.

    this.bOnly();
    //   ^^^^^
    // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
    // [cfe] The method 'bOnly' isn't defined for the type 'A'.
  }
}

void main() {}
