// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void f(num callback(num x)) {}

Object intToObject(int x) => null;
Object numToObject(num x) => null;
Object objectToObject(Object x) => null;
int intToInt(int x) => null;
int numToInt(num x) => null;
int objectToInt(Object x) => null;
num intToNum(int x) => null;
num numToNum(num x) => null;
num objectToNum(Object x) => null;

main() {
  // Unrelated types (not assignable)
  f(intToInt);
  //^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'int Function(int)' can't be assigned to the parameter type 'num Function(num)'.
  f(objectToObject);
  //^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'Object Function(Object)' can't be assigned to the parameter type 'num Function(num)'.

  // Assignable but fails at runtime.
  var intToObject2 = intToObject;
  Expect.throwsTypeError(() => f(intToObject2));
  var intToNum2 = intToNum;
  Expect.throwsTypeError(() => f(intToNum2));
  var numToObject2 = numToObject;
  Expect.throwsTypeError(() => f(numToObject2));

  // Ok
  f(numToNum);
  f(numToInt);
  f(objectToNum);
  f(objectToInt);
}
