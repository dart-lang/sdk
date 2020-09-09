// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

main() {
  var c0 = const C0();
  //       ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONST
  //             ^
  // [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
  var i0 = const I0();
  //       ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONST
  //             ^
  // [cfe] Cannot invoke a non-'const' factory where a const expression is expected.
  var c1 = const C1();
  var c2 = const C2();
  //       ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_NON_CONST
  //             ^
  // [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
  var c3 = const C3();
  //       ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_THROWS_EXCEPTION
}

abstract class I0 {
  factory I0() = C0;
}

class C0 implements I0 {
  C0();
}

class C1 {
  const C1();
//      ^^
// [analyzer] COMPILE_TIME_ERROR.CONST_CONSTRUCTOR_WITH_NON_FINAL_FIELD
// [cfe] Constructor is marked 'const' so all fields must be final.
  var modifiable;
}

class C2 {
  C2();
}

class C3 {
  const C3()
      : field = new C0()
      //^^^^^
      // [analyzer] COMPILE_TIME_ERROR.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION
      //      ^
      // [cfe] 'field' is a final instance variable that was initialized at the declaration.
      //      ^
      // [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
      //        ^^^^^^^^
      // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
      // [cfe] New expression is not a constant expression.
  ;
  final field = null;
}
