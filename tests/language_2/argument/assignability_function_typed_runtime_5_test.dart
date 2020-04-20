// TODO(multitest): This was automatically migrated from a multitest and may
// contain strange or dead code.

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



  // Assignable but fails at runtime.
  var intToObject2 = intToObject;

  var intToNum2 = intToNum;

  var numToObject2 = numToObject;


  // Ok

  f(numToInt);


}
