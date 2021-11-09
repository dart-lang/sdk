// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


// Can only be declared with exactly one required positional parameter.
class C2 {
  Object? operator >>>(arg1, arg2) => arg1;
  //               ^
  // [cfe] Operator '>>>' should have exactly one parameter.
  //               ^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR
}

class CO1 {
  Object? operator >>>([arg1]) => arg1;
  //                    ^^^^
  // [cfe] An operator can't have optional parameters.
  // [analyzer] COMPILE_TIME_ERROR.OPTIONAL_PARAMETER_IN_OPERATOR
}

class C1O1 {
  Object? operator >>>(arg1, [arg2]) => arg1;
  //               ^
  // [cfe] Operator '>>>' should have exactly one parameter.
  //               ^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR
}

class C1N1 {
  Object? operator >>>(arg1, {arg2}) => arg1;
  //               ^
  // [cfe] Operator '>>>' should have exactly one parameter.
  //               ^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR
}

class C0 {
  Object? operator >>>() => 0;
  //               ^
  // [cfe] Operator '>>>' should have exactly one parameter.
  //               ^^^
  // [analyzer] COMPILE_TIME_ERROR.WRONG_NUMBER_OF_PARAMETERS_FOR_OPERATOR
}

// Operators cannot be generic.
class Gen {
  Object? operator >>> <T>(T arg1) => arg1;
  //                    ^
  // [cfe] Types parameters aren't allowed when defining an operator.
  //                   ^^^
  // [analyzer] SYNTACTIC_ERROR.TYPE_PARAMETER_ON_OPERATOR
}

// Operators cannot be static.
class Static {
  /**/ static Object? operator >>>(arg) => arg;
  //   ^^^^^^
  // [cfe] Operators can't be static.
  // [analyzer] SYNTACTIC_ERROR.STATIC_OPERATOR
}

main() {
  C0();
  CO1();
  C1O1();
  C1N1();
  C2();
  Gen();
  Static();
}
