// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests 'const-function' flag disabled for simple function invocations.

const binary = binaryFn(2, 1);
//             ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
// [cfe] Method invocation is not a constant expression.
int binaryFn(int a, int b) => a - b;

const optional = optionalFn(2);
//               ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
// [cfe] Method invocation is not a constant expression.
const optional1 = optionalFn(2, 1);
//                ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
// [cfe] Method invocation is not a constant expression.
int optionalFn(int c, [int d = 0]) => c + d;

const named = namedFn(2, f: 2);
//            ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
// [cfe] Method invocation is not a constant expression.
const named1 = namedFn(2);
//             ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
// [cfe] Method invocation is not a constant expression.
int namedFn(int e, {int f = 3}) => e + f;

const type = typeFn(6);
//           ^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
// [cfe] Method invocation is not a constant expression.
T typeFn<T>(T x) => x;

const str = stringFn("str");
//          ^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
// [cfe] Method invocation is not a constant expression.
String stringFn(String s) => s + "ing";

const eq = equalFn(2, 2);
//         ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
// [cfe] Method invocation is not a constant expression.
bool equalFn(int a, int b) => a == b;

const neg = unary(2);
//          ^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
// [cfe] Method invocation is not a constant expression.
int unary(int a) => -a;

const boolean = boolFn(true, false);
//              ^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
// [cfe] Method invocation is not a constant expression.
bool boolFn(bool a, bool b) => a || b;

const doub = doubleFn(2.2, 2);
//           ^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
// [cfe] Method invocation is not a constant expression.
double doubleFn(double a, double b) => a * b;
