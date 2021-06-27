// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests if statements for const functions.

import "package:expect/expect.dart";

const var1 = ifTest(1);
const var2 = ifTest(2);
const var3 = ifTest(3);
int ifTest(int a) {
  if (a == 1) {
    return 100;
  } else if (a == 2) {
    return 200;
  } else {
    return 300;
  }
}

const one = 1;
const var4 = ifTest2(1);
const var5 = ifTest2(2);
int ifTest2(int a) {
  if (a == one) {
    return 100;
  } else {
    return 200;
  }
}

const var6 = ifTest3(1);
const var6_1 = ifTest3(2);
const var6_2 = ifTest3(0);
int ifTest3(int a) {
  if (a > 0) {
    if (a == 1) return 100;
    return 200;
  }
  return 300;
}

const var7 = ifTest4(1);
int ifTest4(int a) {
  int b = a;
  if (a == 1) {
    b += a;
    if (a % 2 == 1) {
      b += a;
    }
  } else if (a == 2) {
    b -= a;
  }

  return b;
}

const var8 = ifTest5();
int ifTest5() {
  var x = 10;
  if (true) var x = 20;
  return x;
}

void main() {
  Expect.equals(var1, 100);
  Expect.equals(var2, 200);
  Expect.equals(var3, 300);
  Expect.equals(var4, 100);
  Expect.equals(var5, 200);
  Expect.equals(var6, 100);
  Expect.equals(var7, 3);
  Expect.equals(var8, 10);
}
