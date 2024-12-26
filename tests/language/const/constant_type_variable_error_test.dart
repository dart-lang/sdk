// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the support for errors about type parameters as potentially
// constant expressions or potentially constant type expressions.

class A<X> {
  final Object x1, x2, x3, x4, x5, x6, x7, x8;

  const A()
    : x1 = const [X],
      //          ^
      // [analyzer] COMPILE_TIME_ERROR.CONST_TYPE_PARAMETER
      // [cfe] Type variables can't be used as constants.
      x2 = const <X>[],
      //          ^
      // [analyzer] COMPILE_TIME_ERROR.INVALID_TYPE_ARGUMENT_IN_CONST_LITERAL
      // [cfe] Type variables can't be used as constants.
      x3 = const {X},
      //          ^
      // [analyzer] COMPILE_TIME_ERROR.CONST_TYPE_PARAMETER
      // [cfe] Type variables can't be used as constants.
      x4 = const <X>{},
      //          ^
      // [analyzer] COMPILE_TIME_ERROR.INVALID_TYPE_ARGUMENT_IN_CONST_LITERAL
      // [cfe] Type variables can't be used as constants.
      x5 = const {X: null},
      //          ^
      // [analyzer] COMPILE_TIME_ERROR.CONST_TYPE_PARAMETER
      // [cfe] Type variables can't be used as constants.
      x6 = const <X, String?>{},
      //          ^
      // [analyzer] COMPILE_TIME_ERROR.INVALID_CONSTANT
      // [analyzer] COMPILE_TIME_ERROR.INVALID_TYPE_ARGUMENT_IN_CONST_LITERAL
      // [cfe] Type variables can't be used as constants.
      x7 = const B<X>(),
      //           ^
      // [analyzer] COMPILE_TIME_ERROR.CONST_WITH_TYPE_PARAMETERS
      // [cfe] Type variables can't be used as constants.
      x8 = const C(X);
  //               ^
  // [analyzer] COMPILE_TIME_ERROR.CONST_TYPE_PARAMETER
  // [cfe] Type variables can't be used as constants.
}

class B<X> {
  const B();
}

class C {
  const C(Object o);
}

void main() {
  const A<int>();
}
