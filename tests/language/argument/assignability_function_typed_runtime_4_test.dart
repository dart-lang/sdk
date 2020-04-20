// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

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
  // Unrelated types (not assignable)



  // Assignable but fails at runtime.
  var intToObject2 = intToObject;

  var intToNum2 = intToNum;

  var numToObject2 = numToObject;


  // Ok
  f(numToNum);



}
