// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test for conditionals as compile-time constants.

import 'package:expect/expect.dart';

class Marker {
  final field;
  const Marker(this.field);
}

var var0 = const Marker(0);
var var1 = const Marker(1);
const const0 = const Marker(0);
const const1 = const Marker(1);

const trueConst = true;
const falseConst = false;
var nonConst = true;
const zeroConst = 0;

const cond1 = trueConst ? const0 : const1;
const cond1a = trueConst ? nonConst : const1;
//                       ^
// [cfe] Constant evaluation error:
//                         ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [cfe] Not a constant expression.
const cond1b = trueConst ? const0 : nonConst;
//                                  ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [cfe] Not a constant expression.

const cond2 = falseConst ? const0 : const1;
const cond2a = falseConst ? nonConst : const1;
//                          ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [cfe] Not a constant expression.
const cond2b = falseConst ? const0 : nonConst;
//                        ^
// [cfe] Constant evaluation error:
//                                   ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [cfe] Not a constant expression.

const cond3 = nonConst ? const0 : const1;
//            ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [cfe] Not a constant expression.
//                     ^
// [cfe] Constant evaluation error:
const cond3a = nonConst ? nonConst : const1;
//             ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [cfe] Not a constant expression.
//                      ^
// [cfe] Constant evaluation error:
//                        ^
// [cfe] Not a constant expression.
const cond3b = nonConst ? const0 : nonConst;
//             ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
// [cfe] Not a constant expression.
//                      ^
// [cfe] Constant evaluation error:
//                                 ^
// [cfe] Not a constant expression.

const cond4 = zeroConst ? const0 : const1;
//            ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_TYPE_BOOL
// [cfe] A value of type 'int' can't be assigned to a variable of type 'bool'.
//            ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
const cond4a = zeroConst ? nonConst : const1;
//             ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_TYPE_BOOL
// [cfe] A value of type 'int' can't be assigned to a variable of type 'bool'.
//             ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
//                         ^
// [cfe] Not a constant expression.
const cond4b = zeroConst ? const0 : nonConst;
//             ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_TYPE_BOOL
// [cfe] A value of type 'int' can't be assigned to a variable of type 'bool'.
//             ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
//                                  ^
// [cfe] Not a constant expression.

void main() {
  Expect.identical(var0, cond1);
  Expect.identical(nonConst, cond1a);
  Expect.identical(var0, cond1b);

  Expect.identical(var1, cond2);
  Expect.identical(var1, cond2a);
  Expect.identical(nonConst, cond2b);

  Expect.identical(var0, cond3);
  Expect.identical(nonConst, cond3a);
  Expect.identical(var0, cond3b);

  Expect.identical(var1, cond4);
  Expect.identical(var1, cond4a);
  Expect.identical(nonConst, cond4b);
}
