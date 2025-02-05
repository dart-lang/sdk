// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

void f(num callback(num x)) {}

Object intToObject(int x) => 0;
Object numToObject(num x) => 0;
Object objectToObject(Object x) => 0;
int intToInt(int x) => 0;
int numToInt(num x) => 0;
int objectToInt(Object x) => 0;
num intToNum(int x) => 0;
num numToNum(num x) => 0;
num objectToNum(Object x) => 0;

main() {
  // Unrelated types (not assignable).
  f(intToInt);
  //^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'int Function(int)' can't be assigned to the parameter type 'num Function(num)'.
  f(objectToObject);
  //^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'Object Function(Object)' can't be assigned to the parameter type 'num Function(num)'.

  // Downcasts.
  f(intToObject);
  //^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'Object Function(int)' can't be assigned to the parameter type 'num Function(num)'.
  f(intToNum);
  //^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'num Function(int)' can't be assigned to the parameter type 'num Function(num)'.
  f(numToObject);
  //^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] The argument type 'Object Function(num)' can't be assigned to the parameter type 'num Function(num)'.

  // Ok.
  f(numToNum);
  f(numToInt);
  f(objectToNum);
  f(objectToInt);
}
