// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests local function usage, some having references to other constant values.

// SharedOptions=--enable-experiment=const-functions

import "package:expect/expect.dart";

int function1() {
  int add(int a, int b) => a + b;
  const value = add(10, 2);
  //            ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
  return value;
}

const constTwo = 2;
int function2() {
  int addTwo(int a) {
    int b = a + constTwo;
    return b;
  }

  const value = addTwo(2);
  //            ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
  return value;
}

int function3() {
  int addTwoReturn(int a) => a + constTwo;
  const value = addTwoReturn(3);
  //            ^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
  return value;
}

int function4() {
  const localTwo = 2;
  int addTwo(int a) => a + localTwo;
  const value = addTwo(20);
  //            ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
  return value;
}

int function5() {
  T typeFn<T>(T a) => a;
  const value = typeFn(3);
  //            ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
  return value;
}

int function6() {
  int optionalFn([int a = 0]) => a;
  const value = optionalFn(1);
  //            ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
  return value;
}

int function7() {
  int namedFn({int a = 0}) => a;
  const value = namedFn(a: 2);
  //            ^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
  return value;
}

int function8() {
  int add(int a, int b) => a + b;
  const value = add(1, 1);
  //            ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
  const value1 = add(2, 3);
  //             ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
  return value + value1;
}

void main() {
  Expect.equals(function1(), 12);
  Expect.equals(function2(), 4);
  Expect.equals(function3(), 5);
  Expect.equals(function4(), 22);
  Expect.equals(function5(), 3);
  Expect.equals(function6(), 1);
  Expect.equals(function7(), 2);
  Expect.equals(function8(), 7);
}
