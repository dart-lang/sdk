// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests for statements for const functions.

// SharedOptions=--enable-experiment=const-functions

import "package:expect/expect.dart";

const var1 = fn(2);
//           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
const var2 = fn(3);
//           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int fn(int a) {
  int b = a;
  for (int i = 0; i < 2; i++) {
    b += a;
  }
  return b;
}

const var3 = fn1(2);
//           ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
const var4 = fn1(3);
//           ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int fn1(int a) {
  int b = a;
  for (int i = 0;; i++) {
    b *= 3;
    if (b > 10) return b;
  }
}

const var5 = fn2();
//           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int fn2() {
  for (int i = 0, j = 2;; i += 2, j += 1) {
    if (i + j > 10) {
      return i + j;
    }
  }
}

const var6 = fnContinue();
//           ^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int fnContinue() {
  int a = 0;
  for (int i = 0; i < 5; i++) {
    if (i % 2 == 1) continue;
    a += i;
  }
  return a;
}

const var7 = fnBreak(2);
//           ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
const var8 = fnBreak(3);
//           ^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int fnBreak(int a) {
  int b = a;
  for (int i = 0; i < 2; i++) {
    if (b == 2) break;
    b += a;
  }
  return b;
}

const var9 = fnNestedFor();
//           ^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int fnNestedFor() {
  int a = 0;
  for (;;) {
    for (;;) {
      break;
    }
    return 1;
  }
}

const var10 = fnBreakLabel();
//            ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int fnBreakLabel() {
  foo:
  for (;;) {
    for (;;) {
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
  Expect.equals(var5, 11);
  Expect.equals(var6, 6);
  Expect.equals(var7, 2);
  Expect.equals(var8, 9);
  Expect.equals(var9, 1);
  Expect.equals(var10, 3);
}
