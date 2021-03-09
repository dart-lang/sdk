// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests creating new local variables within const functions.

// SharedOptions=--enable-experiment=const-functions

import "package:expect/expect.dart";

const var1 = function1(1, 2);
int function1(int a, int b) {
  var x = 1 + a + b;
  return x;
}

const var2 = function2();
String function2() {
  dynamic x = "string";
  return x;
}

const var3 = function3();
int function3() {
  var first = 2;
  var second = 2 + first;
  return 2 + second;
}

const var4 = function4();
int function4() {
  var first = 2;
  var second = 0;
  return first + second;
}

const var5 = function5();
int function5() {
  const constant = -2;
  return constant;
}

void main() {
  Expect.equals(var1, 4);
  Expect.equals(var2, "string");
  Expect.equals(var3, 6);
  Expect.equals(var4, 2);
  Expect.equals(var5, -2);
}
