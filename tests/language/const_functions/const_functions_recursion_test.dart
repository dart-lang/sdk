// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests recursive function calls for const functions.

// SharedOptions=--enable-experiment=const-functions

import "package:expect/expect.dart";

const b = fn(4);
//        ^^^^^
// [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
int fn(int a) {
  if (a == 1) return 1;
  return a * fn(a - 1);
}

int localTest() {
  int fnLocal(int a) {
    if (a == 1) return 1;
    return a * fnLocal(a - 1);
  }

  const c = fnLocal(4);
  //        ^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
  return c;
}

void main() {
  Expect.equals(b, 24);
  Expect.equals(localTest(), 24);
}
