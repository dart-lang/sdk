// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  const f0 = 42;
  const f1;
  //    ^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_NOT_INITIALIZED
  // [cfe] The const variable 'f1' must be initialized.
  const int f2 = 87;
  const int f3;
  //        ^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_NOT_INITIALIZED
  // [cfe] The const variable 'f3' must be initialized.
  Expect.equals(42, f0);
  Expect.equals(87, f2);

  Expect.equals(42, F0);
  Expect.equals(null, F1);
  Expect.equals(87, F2);
  Expect.equals(null, F3);

  Expect.isTrue(P0 is Point);
  Expect.isTrue(P1 is int);
  Expect.isTrue(P2 is Point);
  Expect.isTrue(P3 is int);

  Expect.isTrue(A0 is int);
  Expect.isTrue(A1 is int);
  Expect.isTrue(A2 is int);
  Expect.isTrue(A3 is int);

  Expect.isTrue(C0.X is C1);
  Expect.isTrue(C0.X.x is C1);

  Expect.equals("Hello 42", B2);
  Expect.equals("42Hello", B3);

  const cf1 = identical(const Point(1, 2), const Point(1, 2));

  const cf2 = identical(const Point(1, 2), new Point(1, 2));
  //                                       ^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
  // [cfe] New expression is not a constant expression.

  var f4 = B4;
  var f5 = B5;
}

const F0 = 42;
const F1;
//    ^^
// [analyzer] COMPILE_TIME_ERROR.CONST_NOT_INITIALIZED
// [cfe] The const variable 'F1' must be initialized.
const int F2 = 87;
const int F3;
//        ^^
// [analyzer] COMPILE_TIME_ERROR.CONST_NOT_INITIALIZED
// [cfe] Field 'F3' should be initialized because its type 'int' doesn't allow null.
//        ^
// [cfe] The const variable 'F3' must be initialized.
//          ^
// [cfe] The value 'null' can't be assigned to a variable of type 'int' because 'int' is not nullable.

class Point {
  final x, y;
  const Point(this.x, this.y);
  operator +(int other) => x;
}

// Check that compile time expressions can include invocations of
// user-defined const constructors.
const P0 = const Point(0, 0);
const P1 = const Point(0, 0) + 1;
//         ^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_TYPE_NUM
//                           ^
// [cfe] Constant evaluation error:
const P2 = new Point(0, 0);
//         ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [cfe] New expression is not a constant expression.
const P3 = new Point(0, 0) + 1;
//         ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [cfe] New expression is not a constant expression.

// Check that we cannot have cyclic references in compile time
// expressions.
const A0 = 42;
const A1 = A0 + 1;
const A2 = A3 + 1;
//    ^^
// [analyzer] COMPILE_TIME_ERROR.RECURSIVE_COMPILE_TIME_CONSTANT
// [cfe] Can't infer the type of 'A2': circularity found during type inference.
//            ^
// [cfe] Constant evaluation error:
const A3 = A2 + 1;
//    ^^
// [analyzer] COMPILE_TIME_ERROR.RECURSIVE_COMPILE_TIME_CONSTANT

class C0 {
  static const X = const C1();
  //           ^
  // [analyzer] COMPILE_TIME_ERROR.RECURSIVE_COMPILE_TIME_CONSTANT
}

class C1 {
  const C1()
      : x = C0.X
      //^
      // [analyzer] COMPILE_TIME_ERROR.FIELD_INITIALIZED_IN_INITIALIZER_AND_DECLARATION
      //  ^
      // [cfe] 'x' is a final instance variable that was initialized at the declaration.
      //  ^
      // [cfe] Cannot invoke a non-'const' constructor where a const expression is expected.
  ;
  final x = null;
}

// Check that sub-expressions of binary + are numeric.
const B0 = 42;
const B1 = "Hello";
const B2 = "$B1 $B0";
const B3 = B0 + B1;
//         ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_TYPE_NUM
//              ^^
// [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
// [cfe] A value of type 'String' can't be assigned to a variable of type 'num'.

// Check identical.

const B4 = identical(1, new Point(1, 2));
//                      ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [cfe] New expression is not a constant expression.
const B5 = identical(1, const Point(1, 2));
