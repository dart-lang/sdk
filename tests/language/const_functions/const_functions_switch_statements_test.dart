// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests switch statements for const functions.

// SharedOptions=--enable-experiment=const-functions

import "package:expect/expect.dart";

const var1 = basicSwitch(1);
//           ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
const var2 = basicSwitch(2);
//           ^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int basicSwitch(int x) {
  switch (x) {
    case 1:
      return 100;
    default:
      x++;
      break;
  }
  return x;
}

const var3 = multipleCaseSwitch(1);
//           ^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
const var4 = multipleCaseSwitch(2);
//           ^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
const var5 = multipleCaseSwitch(3);
//           ^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int multipleCaseSwitch(int x) {
  switch (x) {
    case 1:
    case 2:
      return 100;
    default:
      break;
  }
  return 0;
}

const var6 = continueLabelSwitch(1);
//           ^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
const var7 = continueLabelSwitch(2);
//           ^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
const var8 = continueLabelSwitch(3);
//           ^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
const var9 = continueLabelSwitch(4);
//           ^^^^^^^^^^^^^^^^^^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int continueLabelSwitch(int x) {
  switch (x) {
    label1:
    case 1:
      x = x + 100;
      continue label3;
    case 2:
      continue label1;
    label3:
    case 3:
      return x + 3;
  }
  return 0;
}

void main() {
  Expect.equals(var1, 100);
  Expect.equals(var2, 3);
  Expect.equals(var3, 100);
  Expect.equals(var4, 100);
  Expect.equals(var5, 0);
  Expect.equals(var6, 104);
  Expect.equals(var7, 105);
  Expect.equals(var8, 6);
  Expect.equals(var9, 0);
}
