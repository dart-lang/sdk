// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  final int x;
  const A.a1() : x = 'foo';
  //                 ^^^^^
  // [analyzer] CHECKED_MODE_COMPILE_TIME_ERROR.CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE
  // [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.
  //                 ^^^^^
  // [analyzer] STATIC_WARNING.FIELD_INITIALIZER_NOT_ASSIGNABLE
  const A.a2(this.x);
  const A.a3([this.x = 'foo']);
  //                   ^^^^^
  // [analyzer] STATIC_TYPE_WARNING.INVALID_ASSIGNMENT
  // [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.
  const A.a4(String this.x);
  //         ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_PARAMETER_DECLARATION
  //         ^^^^^^^^^^^^^
  // [analyzer] STATIC_WARNING.FIELD_INITIALIZING_FORMAL_NOT_ASSIGNABLE
  //                     ^
  // [cfe] The type of parameter 'x', 'String' is not a subtype of the corresponding field's type, 'int'.
  const A.a5(String x) : this.x = x;
  //                              ^
  // [analyzer] CHECKED_MODE_COMPILE_TIME_ERROR.CONST_FIELD_INITIALIZER_NOT_ASSIGNABLE
  // [cfe] A value of type 'String' can't be assigned to a variable of type 'int'.
  //                              ^
  // [analyzer] STATIC_WARNING.FIELD_INITIALIZER_NOT_ASSIGNABLE
  const A.a6(int x) : this.x = x;
}

var a1 = const A.a1();
//       ^^^^^^^^^^^^
// [analyzer] CHECKED_MODE_COMPILE_TIME_ERROR.CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH
var a2 = const A.a2('foo');
//                  ^^^^^
// [analyzer] CHECKED_MODE_COMPILE_TIME_ERROR.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH
// [cfe] The argument type 'String' can't be assigned to the parameter type 'int'.
//                  ^^^^^
// [analyzer] STATIC_WARNING.ARGUMENT_TYPE_NOT_ASSIGNABLE
var a3 = const A.a3();
//       ^^^^^^^^^^^^
// [analyzer] CHECKED_MODE_COMPILE_TIME_ERROR.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH
var a4 = const A.a4('foo');
//                  ^^^^^
// [analyzer] CHECKED_MODE_COMPILE_TIME_ERROR.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH
var a5 = const A.a5('foo');
//       ^^^^^^^^^^^^^^^^^
// [analyzer] CHECKED_MODE_COMPILE_TIME_ERROR.CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH
var a6 = const A.a6('foo');
//       ^^^^^^^^^^^^^^^^^
// [analyzer] CHECKED_MODE_COMPILE_TIME_ERROR.CONST_CONSTRUCTOR_FIELD_TYPE_MISMATCH
//                  ^^^^^
// [analyzer] CHECKED_MODE_COMPILE_TIME_ERROR.CONST_CONSTRUCTOR_PARAM_TYPE_MISMATCH
// [cfe] The argument type 'String' can't be assigned to the parameter type 'int'.
//                  ^^^^^
// [analyzer] STATIC_WARNING.ARGUMENT_TYPE_NOT_ASSIGNABLE

main() {
  print(a1);
  print(a2);
  print(a3);
  print(a4);
  print(a5);
  print(a6);
}
