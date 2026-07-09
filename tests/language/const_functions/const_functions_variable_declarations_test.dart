// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests creating new local variables within const functions.

// SharedOptions=--enable-experiment=const-functions

import "package:expect/expect.dart";

const var1 = function1(1, 2);
//           ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
const var1_1 = function1(2, 2);
//             ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int function1(int a, int b) {
  var x = 1 + a + b;
  return x;
}

const var2 = function2();
//           ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
String function2() {
  dynamic x = "string";
  return x;
}

const var3 = function3();
//           ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int function3() {
  var first = 2;
  var second = 2 + first;
  return 2 + second;
}

const var4 = function4();
//           ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int function4() {
  var first = 2;
  var second = 0;
  return first + second;
}

const var5 = function5();
//           ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int function5() {
  const constant = -2;
  return constant;
}

const var6 = function6();
//           ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int function6() {
  var a;
  a = 2;
  return a;
}

const var7 = function7();
//           ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int function7() {
  var a;
  var b;
  a = 2;
  return a;
}

const var8 = function8();
//           ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int function8() {
  var a;
  int? b;
  a = 2;
  return a;
}

const var9 = function9();
//           ^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int? function9() {
  int? x;
  return x;
}

void main() {
  Expect.equals(var1, 4);
  Expect.equals(var1_1, 5);
  Expect.equals(var2, "string");
  Expect.equals(var3, 6);
  Expect.equals(var4, 2);
  Expect.equals(var5, -2);
  Expect.equals(var6, 2);
  Expect.equals(var7, 2);
  Expect.equals(var8, 2);
  Expect.equals(var9, null);
}
