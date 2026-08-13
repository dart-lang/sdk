// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests function invocation return types.

// SharedOptions=--enable-experiment=const-functions

import "package:expect/expect.dart";

const var1 = fn();
//           ^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
void fn() {}

const var2 = fn2();
//           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
void fn2() {
  return;
}

const var3 = fn3();
//           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int? fn3() => null;

const var4 = fn4();
//           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int? fn4() {
  return null;
}

const var5 = fn5();
//           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
// [web] Constant evaluation error:
int fn5() {
  try {
    return throw 1;
  } on int {
    return 2;
  }
}

void main() {
  Expect.equals((var1 as dynamic), null);
  Expect.equals((var2 as dynamic), null);
  Expect.equals(var3, null);
  Expect.equals(var4, null);
  Expect.equals(var5, 2);
}
