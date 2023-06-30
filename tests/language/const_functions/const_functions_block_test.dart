// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests blocks and scope with const functions.

// SharedOptions=--enable-experiment=const-functions

import "package:expect/expect.dart";

void blockTest() {
  int x() => 1;
  const i = x();
  //        ^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
  Expect.equals(i, 1);
  {
    int x() => 2;
    const y = x();
    //        ^^^
    // [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
    Expect.equals(y, 2);
    {
      int x() => 3;
      const y = x();
      //        ^^^
      // [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
      Expect.equals(y, 3);
    }
  }
  const z = x();
  //        ^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
  Expect.equals(z, 1);
}

void blockTest1() {
  int x() {
    int z = 3;
    {
      int z = 4;
    }
    return z;
  }

  const i = x();
  //        ^^^
  // [analyzer] COMPILE_TIME_ERROR.CONST_EVAL_METHOD_INVOCATION
  Expect.equals(i, 3);
}

void main() {
  blockTest();
  blockTest1();
}
