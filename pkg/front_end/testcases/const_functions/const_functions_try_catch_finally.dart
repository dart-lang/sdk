// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests try-catch and try-finally with const functions.

import "package:expect/expect.dart";

const var1 = fn("s");
const var2 = fn(1);
int fn(dynamic error) {
  try {
    throw error;
  } on String {
    return 0;
  } catch (e) {
    return 1;
  }
}

const var3 = fn1(10);
const var4 = fn1("s");
int fn1(dynamic error) {
  try {
    throw error;
  } on int catch (e) {
    return e;
  } catch (e) {
    return 1;
  }
}

const var5 = finallyReturn(10);
const var6 = finallyReturn("s");
const var7 = finallyReturn(1);
int finallyReturn(dynamic error) {
  try {
    if (error != 1) throw error;
  } on int catch (e) {
    return e;
  } catch (e) {
    return 1;
  } finally {
    return 100;
  }
}

const var8 = finallyReturn1(0);
const var9 = finallyReturn1(1);
int finallyReturn1(int x) {
  try {
    if (x == 1) {
      throw x;
    } else {
      return 0;
    }
  } finally {
    return 100;
  }
}

const var10 = finallyMutate();
int finallyMutate() {
  int x = 0;
  try {
    return x;
  } finally {
    x++;
  }
}

const var11 = subtypeFn();
int subtypeFn() {
  try {
    throw 2.5;
  } on num catch (e) {
    return 0;
  }
}

const var12 = orderFn();
String orderFn() {
  String x = "st";
  try {
    x += "ri";
    throw 2;
  } catch (e) {
    x += "n";
  } finally {
    return x + "g";
  }
}

const var13 = notThrowStatement();
int notThrowStatement() {
  int count = 0;
  try {
    for (int i = 0; i < 1; throw 'a') {
      count += i;
    }
  } catch (e) {
    return 1;
  }
  return 0;
}

void main() {
  Expect.equals(var1, 0);
  Expect.equals(var2, 1);
  Expect.equals(var3, 10);
  Expect.equals(var4, 1);
  Expect.equals(var5, 100);
  Expect.equals(var6, 100);
  Expect.equals(var7, 100);
  Expect.equals(var8, 100);
  Expect.equals(var9, 100);
  Expect.equals(var10, 0);
  Expect.equals(var11, 0);
  Expect.equals(var12, "string");
  Expect.equals(var13, 1);
}
