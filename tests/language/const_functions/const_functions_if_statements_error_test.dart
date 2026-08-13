// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests erroneous if statements for const functions.

// SharedOptions=--enable-experiment=const-functions

import "package:expect/expect.dart";

const var1 = fn();
//           ^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int fn() {
  int val = 0;
  if (val) {
    //^^^
    // [analyzer] COMPILE_TIME_ERROR.NON_BOOL_CONDITION
    // [cfe] A value of type 'int' can't be assigned to a variable of type 'bool'.
    val += 1;
  }
  return val;
}

const var2 = fn2();
//           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
// [cfe] Constant evaluation error:
int fn2() {
  int val = 0;
  if (val as dynamic) {
    val += 1;
  }
  return val;
}

const var3 = fn3();
//           ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
// [cfe] Constant evaluation error:
int fn3() {
  dynamic val = 0;
  if (val) {
    val += 1;
  }
  return val;
}
