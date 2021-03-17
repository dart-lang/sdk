// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests for statements for const functions.

// SharedOptions=--enable-experiment=const-functions

import "package:expect/expect.dart";

const var1 = fn(2);
const var2 = fn(3);
int fn(int a) {
  int b = a;
  for (int i = 0; i < 2; i++) {
    b += a;
  }
  return b;
}

const var3 = fn1(2);
const var4 = fn1(3);
int fn1(int a) {
  int b = a;
  for (int i = 0;; i++) {
    b *= 3;
    if (b > 10) return b;
  }
}

const var5 = fn2();
int fn2() {
  for (int i = 0, j = 2;; i += 2, j += 1) {
    if (i + j > 10) {
      return i + j;
    }
  }
}

void main() {
  Expect.equals(var1, 6);
  Expect.equals(var2, 9);
  Expect.equals(var3, 18);
  Expect.equals(var4, 27);
  Expect.equals(var5, 11);
}
