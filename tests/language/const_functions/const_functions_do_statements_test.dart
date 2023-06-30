// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests do-while statements for const functions.

// SharedOptions=--enable-experiment=const-functions

import "package:expect/expect.dart";

const var1 = fn();
//           ^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int fn() {
  int x = 0;
  do {
    x++;
  } while (x < 2);
  return x;
}

const var2 = fn2(2);
//           ^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
const var3 = fn2(10);
//           ^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int fn2(int a) {
  int x = 0, b = 0;
  do {
    if (x > 5) break;
    x += a;
    b++;
  } while (b < 2);
  return x;
}

const var4 = fn3();
//           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int fn3() {
  int x = 0, b = 0;
  do {
    x += 1;
    if (x % 2 == 1) continue;
    b += x;
  } while (x < 5);
  return b;
}

void main() {
  Expect.equals(var1, 2);
  Expect.equals(var2, 4);
  Expect.equals(var3, 10);
  Expect.equals(var4, 6);
}
