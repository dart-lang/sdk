// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous string usage with const functions.

// SharedOptions=--enable-experiment=const-functions

import "package:expect/expect.dart";

const String str = "str";
const var1 = str[-1];
//           ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
//              ^
// [cfe] Constant evaluation error:
const var2 = str[3];
//           ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE
//              ^
// [cfe] Constant evaluation error:

const var3 = fn();
//           ^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
// [cfe] Constant evaluation error:
fn() {
  String s = "str";
  return str[-1];
}

const var4 = fn2();
//           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
// [cfe] Constant evaluation error:
fn2() {
  String s = "str";
  return str[3];
}

const var5 = fn3();
//           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
fn3() {
  String s = "str";
  return str[1.1];
  //         ^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] A value of type 'double' can't be assigned to a variable of type 'int'.
}
