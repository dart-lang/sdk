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
  f(intToInt); //# 01: compile-time error
  f(objectToObject); //# 02: compile-time error

  // Assignable but fails at runtime.
  var intToObject2 = intToObject;
  Expect.throwsTypeError(() => f(intToObject2)); //# 03: ok
  var intToNum2 = intToNum;
  Expect.throwsTypeError(() => f(intToNum2)); //# 04: ok
  var numToObject2 = numToObject;
  Expect.throwsTypeError(() => f(numToObject2)); //# 05: ok

  // Ok
  f(numToNum); //# 06: ok
  f(numToInt); //# 07: ok
  f(objectToNum); //# 08: ok
  f(objectToInt); //# 09: ok
}
