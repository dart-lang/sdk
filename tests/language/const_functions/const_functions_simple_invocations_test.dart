// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests function invocations that immediately return simple expressions.

// SharedOptions=--enable-experiment=const-functions

import "package:expect/expect.dart";

const binary = binaryFn(2, 1);
//             ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int binaryFn(int a, int b) => a - b;

const optional = optionalFn(2);
//               ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
const optional1 = optionalFn(2, 1);
//                ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int optionalFn(int c, [int d = 0]) => c + d;

const named = namedFn(2, f: 2);
//            ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
const named1 = namedFn(2);
//             ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int namedFn(int e, {int f = 3}) => e + f;

const type = typeFn(6);
//           ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
T typeFn<T>(T x) => x;

const str = stringFn("str");
//          ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
String stringFn(String s) => s + "ing";

const eq = equalFn(2, 2);
//         ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
bool equalFn(int a, int b) => a == b;

const neg = unary(2);
//          ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int unary(int a) => -a;

const boolean = boolFn(true, false);
//              ^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
bool boolFn(bool a, bool b) => a || b;

const doub = doubleFn(2.2, 2);
//           ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
double doubleFn(double a, double b) => a * b;

const multi = multiFn(1);
//            ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
const multi2 = multiFn(2);
//             ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int multiFn(int a) => a + 1;

void main() {
  Expect.equals(binary, 1);
  Expect.equals(optional, 2);
  Expect.equals(optional1, 3);
  Expect.equals(named, 4);
  Expect.equals(named1, 5);
  Expect.equals(type, 6);
  Expect.equals(str, "string");
  Expect.equals(eq, true);
  Expect.equals(neg, -2);
  Expect.equals(boolean, true);
  Expect.equals(doub, 4.4);
  Expect.equals(multi, 2);
  Expect.equals(multi2, 3);
}
