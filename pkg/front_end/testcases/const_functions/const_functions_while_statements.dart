// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests while statements for const functions.

import "package:expect/expect.dart";

const var1 = fn(2);
const var2 = fn(3);
int fn(int a) {
  int b = a;
  int i = 0;
  while (i < 2) {
    b += a;
    i++;
  }
  return b;
}

const var3 = fn1(2);
const var4 = fn1(3);
int fn1(int a) {
  int b = a;
  while (true) {
    b *= 3;
    if (b > 10) return b;
  }
}

const var5 = fnContinue();
int fnContinue() {
  int a = 0;
  int i = 0;
  while (i < 5) {
    if (i % 2 == 1) {
      i++;
      continue;
    }
    a += i;
    i++;
  }
  return a;
}

const var6 = fnBreak(2);
const var7 = fnBreak(3);
int fnBreak(int a) {
  int b = a;
  int i = 0;
  while (i < 2) {
    if (b == 2) break;
    b += a;
    i++;
  }
  return b;
}

const var8 = fnNestedWhile();
int fnNestedWhile() {
  int a = 0;
  while (true) {
    while (true) {
      break;
    }
    return 1;
  }
}

const var9 = fnBreakLabel();
int fnBreakLabel() {
  foo:
  while (true) {
    while (true) {
      break foo;
    }
  }
  return 3;
}

void main() {
  Expect.equals(var1, 6);
  Expect.equals(var2, 9);
  Expect.equals(var3, 18);
  Expect.equals(var4, 27);
  Expect.equals(var5, 6);
  Expect.equals(var6, 2);
  Expect.equals(var7, 9);
  Expect.equals(var8, 1);
  Expect.equals(var9, 3);
}
